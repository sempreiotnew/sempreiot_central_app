// Integration test for the provisioning wizard state machine against the
// mocked device server (mocked-device-autoconnect).
//
// Run with the mock up:
//   node ../../mocked-device-autoconnect/server.js   (any JOIN_* env is fine —
//   the test overrides joinResult/joinDelayMs via POST /reset)
//   flutter test test/provisioning_wizard_integration_test.dart \
//     --dart-define=DEVICE_AP_URL=http://localhost:8080
//
// Skipped automatically when the mock isn't reachable.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sempreiot_central_app/features/provisioning/application/provisioning_wizard_provider.dart';
import 'package:sempreiot_central_app/features/provisioning/domain/entities/device_qr_payload.dart';
import 'package:sempreiot_central_app/features/provisioning/domain/entities/provisioning_step.dart';

const _mockBase = String.fromEnvironment(
  'DEVICE_AP_URL',
  defaultValue: 'http://192.168.4.1',
);

Future<bool> _mockReachable() async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final req = await client.postUrl(Uri.parse('$_mockBase/reset'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'joinResult': 'success', 'joinDelayMs': 1000}));
    final res = await req.close();
    await res.drain<void>();
    client.close();
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<void> _reset({required String joinResult, int joinDelayMs = 1000}) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse('$_mockBase/reset'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({'joinResult': joinResult, 'joinDelayMs': joinDelayMs}));
  final res = await req.close();
  await res.drain<void>();
  client.close();
}

/// Waits until the notifier reaches [target] (or any result step if
/// [anyResult]), failing after [timeout].
Future<ProvisioningStep> _waitFor(
  ProvisioningWizardNotifier notifier, {
  ProvisioningStep? target,
  bool anyResult = false,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final step = notifier.state.step;
    if (target != null && step == target) return step;
    if (anyResult && step.isResult) return step;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('Timed out waiting for ${target ?? 'a result'} — '
      'stuck at ${notifier.state.step}');
}

const _goodCreds = DeviceQrPayload(deviceId: 'dev-001', signature: 'abc123');

Future<ProvisioningWizardNotifier> _identifiedNotifier() async {
  final notifier = ProvisioningWizardNotifier();
  notifier.setCredentials(_goodCreds);
  await _waitFor(notifier, target: ProvisioningStep.selectCentral);
  return notifier;
}

void main() async {
  final reachable = await _mockReachable();

  group('provisioning wizard against mock device', () {
    test('happy path: identify → provision → connected', () async {
      await _reset(joinResult: 'success');
      final notifier = await _identifiedNotifier();

      notifier.selectCentral(centralId: 'central-xyz', centralName: 'Casa');
      expect(notifier.state.step, ProvisioningStep.confirm);

      notifier.setNetworkReady(true);
      await notifier.submitProvision();
      final result = await _waitFor(notifier, anyResult: true);
      expect(result, ProvisioningStep.resultSuccess);
      notifier.dispose();
    });

    test('wrong signature → identifyFailed', () async {
      await _reset(joinResult: 'success');
      final notifier = ProvisioningWizardNotifier();
      notifier.setCredentials(
        const DeviceQrPayload(deviceId: 'dev-001', signature: 'WRONG'),
      );
      await _waitFor(notifier, target: ProvisioningStep.identifyFailed);
      expect(notifier.state.error, isNotNull);
      notifier.dispose();
    });

    test('mesh join fails → resultFailed', () async {
      await _reset(joinResult: 'fail');
      final notifier = await _identifiedNotifier();
      notifier.selectCentral(centralId: 'central-xyz');
      await notifier.submitProvision();
      final result = await _waitFor(notifier, anyResult: true);
      expect(result, ProvisioningStep.resultFailed);
      notifier.dispose();
    });

    test('AP drops after ACK → resultAssumed', () async {
      await _reset(joinResult: 'drop');
      final notifier = await _identifiedNotifier();
      notifier.selectCentral(centralId: 'central-xyz');
      await notifier.submitProvision();
      final result = await _waitFor(
        notifier,
        anyResult: true,
        timeout: const Duration(seconds: 45),
      );
      expect(result, ProvisioningStep.resultAssumed);
      notifier.dispose();
    });

    test('networkReady=false → resultStored', () async {
      await _reset(joinResult: 'success');
      final notifier = await _identifiedNotifier();
      notifier.selectCentral(centralId: 'central-xyz');
      notifier.setNetworkReady(false);
      await notifier.submitProvision();
      final result = await _waitFor(notifier, anyResult: true);
      expect(result, ProvisioningStep.resultStored);
      notifier.dispose();
    });
  }, skip: reachable ? false : 'mock device server not reachable at $_mockBase');

  test('DeviceQrPayload parses valid QR and rejects garbage', () {
    final ok = DeviceQrPayload.tryParse(
      '{"deviceId":"dev-001","signature":"abc123"}',
    );
    expect(ok?.deviceId, 'dev-001');
    expect(ok?.signature, 'abc123');

    expect(DeviceQrPayload.tryParse('just-a-subid'), isNull);
    expect(DeviceQrPayload.tryParse('{"deviceId":"x"}'), isNull);
    expect(DeviceQrPayload.tryParse(''), isNull);
  });
}
