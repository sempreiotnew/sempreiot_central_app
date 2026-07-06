import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/device_ap_service.dart';
import '../domain/entities/device_ap_info.dart';
import '../domain/entities/device_qr_payload.dart';
import '../domain/entities/provisioning_step.dart';

class ProvisioningWizardState {
  final ProvisioningStep step;
  final DeviceQrPayload? credentials;
  final DeviceApInfo? deviceInfo;
  final String? centralId;
  final String? centralName; // local nickname, display only
  final bool networkReady;
  final String? error;

  const ProvisioningWizardState({
    this.step = ProvisioningStep.scan,
    this.credentials,
    this.deviceInfo,
    this.centralId,
    this.centralName,
    this.networkReady = true,
    this.error,
  });

  ProvisioningWizardState copyWith({
    ProvisioningStep? step,
    DeviceQrPayload? credentials,
    DeviceApInfo? deviceInfo,
    String? centralId,
    String? centralName,
    bool? networkReady,
    String? error,
    bool clearError = false,
  }) =>
      ProvisioningWizardState(
        step: step ?? this.step,
        credentials: credentials ?? this.credentials,
        deviceInfo: deviceInfo ?? this.deviceInfo,
        centralId: centralId ?? this.centralId,
        centralName: centralName ?? this.centralName,
        networkReady: networkReady ?? this.networkReady,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProvisioningWizardNotifier
    extends StateNotifier<ProvisioningWizardState> {
  ProvisioningWizardNotifier() : super(const ProvisioningWizardState());

  static const _pollInterval = Duration(seconds: 2);

  /// After the provision ACK, this many consecutive unreachable polls mean the
  /// SoftAP channel-switched us off — treated as "assumed provisioned".
  static const _silenceTolerance = 4;

  /// Give up waiting for a mesh-join verdict after this many polls (~60s).
  static const _maxStatusPolls = 30;

  Timer? _infoTimer;
  Timer? _statusTimer;
  bool _requestInFlight = false;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _infoTimer?.cancel();
    _infoTimer = null;
    _statusTimer?.cancel();
    _statusTimer = null;
    _requestInFlight = false;
  }

  // ── Step 1: credentials ────────────────────────────────────────────────────

  /// Called with QR payload or manual entry; advances to the connect-wifi
  /// step and starts hunting for the device.
  void setCredentials(DeviceQrPayload payload) {
    state = state.copyWith(
      credentials: payload,
      step: ProvisioningStep.connectWifi,
      clearError: true,
    );
    _startInfoPolling();
  }

  /// Back to scan (from connectWifi or identifyFailed).
  void backToScan() {
    _cancelTimers();
    state = ProvisioningWizardState(
      networkReady: state.networkReady,
    );
  }

  // ── Steps 2–3: find device + identify ──────────────────────────────────────

  void _startInfoPolling() {
    _infoTimer?.cancel();
    _infoTimer = Timer.periodic(_pollInterval, (_) => _tryReachDevice());
    _tryReachDevice(); // immediate first attempt
  }

  Future<void> _tryReachDevice() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final info = await DeviceApService.fetchInfo();
      if (!mounted || state.step != ProvisioningStep.connectWifi) return;

      _infoTimer?.cancel();
      _infoTimer = null;
      state = state.copyWith(
        deviceInfo: info,
        step: ProvisioningStep.identifying,
      );
      await _identify();
    } catch (_) {
      // Device not reachable yet — keep polling silently.
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _identify() async {
    final creds = state.credentials;
    if (creds == null) return;
    try {
      await DeviceApService.identify(
        deviceId: creds.deviceId,
        signature: creds.signature,
      );
      if (!mounted) return;
      state = state.copyWith(
        step: ProvisioningStep.selectCentral,
        clearError: true,
      );
    } on SignatureMismatchException {
      if (!mounted) return;
      state = state.copyWith(
        step: ProvisioningStep.identifyFailed,
        error: 'O dispositivo rejeitou as credenciais. '
            'Verifique se o QR Code corresponde a este dispositivo.',
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Provisioning] identify error: $e');
      // Transient failure right after contact — go back to hunting.
      state = state.copyWith(step: ProvisioningStep.connectWifi);
      _startInfoPolling();
    }
  }

  /// Retry from identifyFailed without rescanning (e.g. device was rebooted).
  void retryIdentify() {
    state = state.copyWith(
      step: ProvisioningStep.connectWifi,
      clearError: true,
    );
    _startInfoPolling();
  }

  // ── Steps 4–5: central + options ───────────────────────────────────────────

  void selectCentral({required String centralId, String? centralName}) {
    state = state.copyWith(
      centralId: centralId,
      centralName: centralName,
      step: ProvisioningStep.confirm,
      clearError: true,
    );
  }

  void backToSelectCentral() {
    state = state.copyWith(
      step: ProvisioningStep.selectCentral,
      clearError: true,
    );
  }

  void setNetworkReady(bool value) {
    state = state.copyWith(networkReady: value);
  }

  // ── Step 6: provision + outcome ────────────────────────────────────────────

  Future<void> submitProvision() async {
    final centralId = state.centralId;
    if (centralId == null || state.step == ProvisioningStep.provisioning) {
      return;
    }

    state = state.copyWith(
      step: ProvisioningStep.provisioning,
      clearError: true,
    );

    try {
      await DeviceApService.provision(
        centralId: centralId,
        networkReady: state.networkReady,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Provisioning] provision error: $e');
      state = state.copyWith(
        step: ProvisioningStep.confirm,
        error: 'Não foi possível enviar a configuração. '
            'Verifique se ainda está conectado à rede do dispositivo.',
      );
      return;
    }

    _startStatusPolling();
  }

  void _startStatusPolling() {
    var silentPolls = 0;
    var totalPolls = 0;

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(_pollInterval, (_) async {
      if (_requestInFlight) return;
      _requestInFlight = true;
      totalPolls++;
      try {
        final status = await DeviceApService.fetchStatus();
        silentPolls = 0;
        if (!mounted) return;

        switch (status.state) {
          case 'connected':
            _finish(ProvisioningStep.resultSuccess);
          case 'stored':
            _finish(ProvisioningStep.resultStored);
          case 'failed':
            _finish(ProvisioningStep.resultFailed);
          default:
            // identified/connecting — still working, keep polling.
            if (totalPolls >= _maxStatusPolls) {
              _finish(ProvisioningStep.resultAssumed);
            }
        }
      } catch (_) {
        // The SoftAP may legitimately vanish while the device switches to the
        // mesh channel. The provision request was ACKed, so after enough
        // silence assume it worked and point the user at the central.
        silentPolls++;
        if (!mounted) return;
        if (silentPolls >= _silenceTolerance ||
            totalPolls >= _maxStatusPolls) {
          _finish(ProvisioningStep.resultAssumed);
        }
      } finally {
        _requestInFlight = false;
      }
    });
  }

  void _finish(ProvisioningStep result) {
    _cancelTimers();
    if (!mounted) return;
    state = state.copyWith(step: result);
  }

  /// From a result screen: provision another device keeping nothing.
  void restart() {
    _cancelTimers();
    state = const ProvisioningWizardState();
  }

  /// From resultFailed: try the mesh join again with the same config.
  Future<void> retryProvision() async {
    state = state.copyWith(step: ProvisioningStep.confirm, clearError: true);
  }
}

final provisioningWizardProvider = StateNotifierProvider.autoDispose<
    ProvisioningWizardNotifier, ProvisioningWizardState>(
  (ref) => ProvisioningWizardNotifier(),
);
