import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
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
  bool _connecting = false;
  bool _disposed = false;
  Timer? _reconnectTimer;

  @override
  Future<bool> build() async {
    _disposed = false;
    // Stop reconnecting if the auth layer signs the user out.
    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncData && next.value == null) {
        _shouldReconnect = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        ref.read(iotMqttRepositoryProvider).disconnect();
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _shouldReconnect = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      ref.read(iotMqttRepositoryProvider).disconnect();
    });
    return false;
  }

  Future<void> connect() async {
    // Guard against duplicate calls: if we're already connected (state is
    // AsyncData(true)), a second connect() from a stale appInitProvider run
    // would open a new WebSocket with the same client-ID, triggering an AWS IoT
    // session takeover that kicks the live connection and creates a reconnect loop.
    if (_connecting) return;
    if (state case AsyncData<bool>(:final value) when value == true) return;
    // Cancel any pending retry so it doesn't race with this external call.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _shouldReconnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (!_shouldReconnect || _connecting) return;
    // If already connected, skip — prevents a stale scheduled reconnect (from
    // _scheduleReconnect, which calls _doConnect directly) from opening a second
    // WebSocket after connect() already succeeded, which would cause AWS IoT to
    // do a session takeover and kick the live connection, restarting the loop.
    if (state.valueOrNull == true) return;
    _connecting = true;
    state = const AsyncLoading();
    try {
      final repo = ref.read(iotMqttRepositoryProvider);
      await repo.connect(onDisconnected: _onUnexpectedDisconnect);
      // connect() returns immediately (without opening a new socket) when the
      // singleton repo is already connected from a previous hot restart. Either
      // way, after connect() returns we own the disconnect callback and can
      // treat the connection as ours.
      if (_disposed) return;
      state = const AsyncData(true);
      debugPrint('[IoT] ✓ connected');

      ref.invalidate(iotMessageStreamProvider);
    } on SessionExpiredException {
      // Refresh token has expired — stop retrying. AuthNotifier's background
      // timer will detect this on its next tick and sign the user out.
      debugPrint('[IoT] session expired — stopping reconnect');
      _shouldReconnect = false;
      if (!_disposed) state = const AsyncData(false);
    } catch (e, st) {
      debugPrint('[IoT] ✗ connection failed: $e');
      if (_disposed) return;
      state = AsyncError(e, st);
      _scheduleReconnect();
    } finally {
      _connecting = false;
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
    _reconnectTimer?.cancel();
    debugPrint('[IoT] reconnecting in ${_retryInterval.inSeconds}s…');
    _reconnectTimer = Timer(_retryInterval, _doConnect);
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
