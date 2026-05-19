import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/iot_mqtt_repository_impl.dart';
import '../domain/entities/mqtt_message_entity.dart';
import '../domain/repositories/i_iot_mqtt_repository.dart';

final iotMqttRepositoryProvider = Provider<IIotMqttRepository>((_) {
  return IotMqttRepositoryImpl();
});

final iotConnectionProvider =
    AsyncNotifierProvider<IotConnectionNotifier, bool>(
  IotConnectionNotifier.new,
);

class IotConnectionNotifier extends AsyncNotifier<bool> {
  static const _retryInterval = Duration(seconds: 5);
  bool _shouldReconnect = false;

  @override
  Future<bool> build() async {
    ref.onDispose(() {
      _shouldReconnect = false;
      ref.read(iotMqttRepositoryProvider).disconnect();
    });
    return false;
  }

  Future<void> connect() async {
    _shouldReconnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (!_shouldReconnect) return;
    state = const AsyncLoading();
    try {
      await ref.read(iotMqttRepositoryProvider).connect(
        onDisconnected: _onUnexpectedDisconnect,
      );
      state = const AsyncData(true);
      debugPrint('[IoT] ✓ connected');

      // Invalidate stream providers so existing subscribers re-attach
      ref.invalidate(iotMessageStreamProvider);

      // DEBUG: log all incoming messages
      ref.read(iotMqttRepositoryProvider).subscribe('#').listen(
        (msg) => debugPrint('[IoT] ← [${msg.topic}]: ${msg.payload}'),
        onError: (e) => debugPrint('[IoT] # subscription error: $e'),
        onDone: () => debugPrint('[IoT] # subscription stream closed'),
      );
    } catch (e, st) {
      debugPrint('[IoT] ✗ connection failed: $e');
      state = AsyncError(e, st);
      _scheduleReconnect();
    }
  }

  void _onUnexpectedDisconnect() {
    if (!_shouldReconnect) return;
    debugPrint('[IoT] ! disconnected unexpectedly');
    state = const AsyncData(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    debugPrint('[IoT] reconnecting in ${_retryInterval.inSeconds}s…');
    Future.delayed(_retryInterval, _doConnect);
  }

  void disconnect() {
    _shouldReconnect = false;
    ref.read(iotMqttRepositoryProvider).disconnect();
    state = const AsyncData(false);
    debugPrint('[IoT] manually disconnected');
  }
}

// Usage: ref.watch(iotMessageStreamProvider('my/topic'))
final iotMessageStreamProvider =
    StreamProvider.family<MqttMessageEntity, String>((ref, topic) {
  final repo = ref.watch(iotMqttRepositoryProvider);
  if (!repo.isConnected) {
    return const Stream.empty();
  }
  debugPrint('[IoT] stream provider subscribing to: $topic');
  return repo.subscribe(topic);
});
