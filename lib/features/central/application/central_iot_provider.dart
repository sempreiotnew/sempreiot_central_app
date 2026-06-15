import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../iot/data/repositories/iot_mqtt_repository_impl.dart';
import '../../iot/domain/entities/mqtt_message_entity.dart';
import '../../iot/domain/repositories/i_iot_mqtt_repository.dart';
import '../data/services/central_credentials_service.dart';

export '../../../core/connectivity/connectivity_provider.dart' show NetworkStatus;

final centralMqttRepositoryProvider = Provider<IIotMqttRepository>((_) {
  return IotMqttRepositoryImpl.forCentral(
    credentialsService: CentralCredentialsService(),
  );
});

final centralIotConnectionProvider =
    AsyncNotifierProvider<CentralIotConnectionNotifier, bool>(
  CentralIotConnectionNotifier.new,
);

/// Messages received on [_kCentralTopic] from the Central's MQTT session.
final centralMqttMessagesProvider = StreamProvider<MqttMessageEntity>((ref) {
  return ref.watch(centralIotConnectionProvider.notifier).messages;
});

class CentralIotConnectionNotifier extends AsyncNotifier<bool> {
  static const _retryInterval = Duration(seconds: 5);
  static const _kTopics = ['teste-central'];

  bool _shouldReconnect = false;
  bool _connecting = false;
  bool _disposed = false;

  final List<StreamSubscription<MqttMessageEntity>> _topicSubs = [];
  final _messagesCtrl = StreamController<MqttMessageEntity>.broadcast();

  Stream<MqttMessageEntity> get messages => _messagesCtrl.stream;

  @override
  Future<bool> build() async {
    _disposed = false;
    _shouldReconnect = true;

    // Connect immediately on startup — the PIN is a UI lock only.
    // The machine MQTT session must run regardless of lock state.
    Future.microtask(_doConnect);

    ref.onDispose(() {
      _disposed = true;
      _shouldReconnect = false;
      _cancelSubs();
      _messagesCtrl.close();
      ref.read(centralMqttRepositoryProvider).disconnect();
    });

    return false;
  }

  void _cancelSubs() {
    for (final s in _topicSubs) {
      s.cancel();
    }
    _topicSubs.clear();
  }

  Future<void> _doConnect() async {
    if (!_shouldReconnect || _connecting) return;
    _connecting = true;
    state = const AsyncLoading();
    try {
      final repo = ref.read(centralMqttRepositoryProvider);
      await repo.connect(onDisconnected: _onUnexpectedDisconnect);
      if (_disposed) return;

      _cancelSubs();
      for (final topic in _kTopics) {
        _topicSubs.add(repo.subscribe(topic).listen(
          (msg) {
            if (!_messagesCtrl.isClosed) _messagesCtrl.add(msg);
            debugPrint('[Central] ← [${msg.topic}] ${msg.payload}');
          },
          onError: (_) {},
          cancelOnError: false,
        ));
      }

      state = const AsyncData(true);
      debugPrint('[Central] ✓ MQTT connected, subscribed to $_kTopics');
    } catch (e, st) {
      debugPrint('[Central] ✗ MQTT connection failed: $e');
      if (_disposed) return;
      state = AsyncError(e, st);
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onUnexpectedDisconnect() {
    if (!_shouldReconnect) return;
    debugPrint('[Central] ! MQTT disconnected unexpectedly');
    _cancelSubs();
    state = const AsyncData(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    debugPrint('[Central] reconnecting in ${_retryInterval.inSeconds}s…');
    Future.delayed(_retryInterval, _doConnect);
  }
}

/// Network status for the Central device — tracks the machine MQTT session
/// independently of the UI lock state.
final centralNetworkStatusProvider = Provider<NetworkStatus>((ref) {
  final connState = ref.watch(connectivityProvider);
  if (connState.isLoading) return NetworkStatus.online;

  final hasInterface = connState.valueOrNull ?? false;
  if (!hasInterface) return NetworkStatus.offline;

  final iotState = ref.watch(centralIotConnectionProvider);
  if (iotState.valueOrNull == true) return NetworkStatus.online;
  if (iotState.hasError || iotState.valueOrNull == false) return NetworkStatus.limited;

  return NetworkStatus.online;
});
