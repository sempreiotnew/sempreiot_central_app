import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/services/sigv4_signer.dart';
import '../../domain/entities/mqtt_message_entity.dart';
import '../../domain/repositories/i_iot_mqtt_repository.dart';
import '../services/iot_credentials_service.dart';

String get _iotEndpoint => dotenv.env['AWS_IOT_ENDPOINT']!;
String get _region => dotenv.env['AWS_REGION']!;

class IotMqttRepositoryImpl implements IIotMqttRepository {
  // Static singleton so there is never more than one WebSocket open at a time.
  // Flutter Web hot restart does NOT reset static state (JS runtime persists),
  // so the same instance — and its existing connection — survives across
  // restarts. Without this, each restart creates a new instance, connects with
  // the same client-ID, AWS IoT does a session takeover (kicks the old socket),
  // the old notifier sees the disconnect, reschedules a connect, kicks the new
  // socket, and the loop repeats indefinitely.
  static IotMqttRepositoryImpl? _shared;

  factory IotMqttRepositoryImpl({IotCredentialsService? credentialsService}) {
    return _shared ??= IotMqttRepositoryImpl._internal(
      credentialsService ?? IotCredentialsService(),
    );
  }

  IotMqttRepositoryImpl._internal(this._credentialsService);

  final IotCredentialsService _credentialsService;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _nextPacketId = 0;
  int _generation = 0;
  StreamController<({String topic, String payload})>? _publishCtrl;
  Timer? _pingTimer;
  Timer? _pingRespTimer;
  Completer<void>? _connackCompleter;
  bool _connackReceived = false;
  bool _connected = false;
  DateTime? _connectedAt;
  void Function()? _onDisconnected;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect({void Function()? onDisconnected}) async {
    // If the connection survived a hot restart, just transfer the disconnect
    // callback to the new notifier — no new WebSocket, no session takeover.
    if (_connected) {
      _onDisconnected = onDisconnected;
      debugPrint('[IoT] connect() called while already connected — handing off callback');
      return;
    }

    // Bump generation so any _onDone/onError from the previous socket —
    // including the one AWS IoT fires when it kicks the old connection on
    // duplicate client-ID — is silently dropped and cannot trigger a reconnect.
    final gen = ++_generation;
    _onDisconnected = null;
    await _subscription?.cancel();
    _subscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingRespTimer?.cancel();
    _pingRespTimer = null;
    _connected = false;
    _connectedAt = null; // reset so age-check in _onDone is always fresh
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    _publishCtrl?.close();
    _publishCtrl = null;

    final creds = await _credentialsService.fetch();

    final signedUrl = SigV4Signer.buildSignedWebSocketUrl(
      host: _iotEndpoint,
      region: _region,
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken,
    );

    _onDisconnected = onDisconnected;
    _connackCompleter = Completer();
    _connackReceived = false;
    _connected = false;
    _publishCtrl = StreamController.broadcast();

    debugPrint('[IoT] connecting — clientId: ${creds.userId}');

    _channel = WebSocketChannel.connect(
      Uri.parse(signedUrl),
      protocols: const ['mqtt'],
    );
    await _channel!.ready;

    _subscription = _channel!.stream.listen(
      _onData,
      onError: (e) { if (gen == _generation) _onError(e); },
      onDone: () { if (gen == _generation) _onDone(); },
      cancelOnError: false,
    );

    _channel!.sink.add(Uint8List.fromList(_mqttConnect(creds.userId)));

    await _connackCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('MQTT CONNACK timeout'),
    );

    // Guard: _onDone may have fired in the gap between CONNACK and here
    if (_publishCtrl?.isClosed ?? true) {
      throw StateError('Connection closed immediately after CONNACK');
    }

    _connected = true;
    _connectedAt = DateTime.now();
    debugPrint('[IoT] MQTT connected ✓');

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_connected) return;
      _channel?.sink.add(Uint8List.fromList(const [0xC0, 0x00]));
      _pingRespTimer?.cancel();
      final pingGen = _generation;
      _pingRespTimer = Timer(
        const Duration(seconds: 10),
        () => _onPingTimeout(pingGen),
      );
    });
  }

  @override
  void disconnect() {
    _onDisconnected = null; // suppress reconnect callback
    _connected = false;
    _credentialsService.reset();
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingRespTimer?.cancel();
    _pingRespTimer = null;
    try {
      _channel?.sink.add(Uint8List.fromList(const [0xE0, 0x00]));
    } catch (_) {}
    _channel?.sink.close();
    _subscription?.cancel();
    _channel = null;
    _subscription = null;
    _publishCtrl?.close();
    _publishCtrl = null;
    debugPrint('[IoT] disconnected');
  }

  @override
  void publish(String topic, String payload) {
    if (!_connected) throw StateError('Not connected');
    debugPrint('[IoT] → publish [$topic]: $payload');
    _channel!.sink.add(Uint8List.fromList(_mqttPublish(topic, payload, _pid())));
  }

  @override
  Stream<MqttMessageEntity> subscribe(String topic) {
    if (!_connected) throw StateError('Not connected');
    debugPrint('[IoT] subscribing to: $topic');
    _channel!.sink.add(Uint8List.fromList(_mqttSubscribe(topic, _pid())));
    return _publishCtrl!.stream
        .where((m) => _topicMatches(m.topic, topic))
        .map((m) => MqttMessageEntity(topic: m.topic, payload: m.payload));
  }

  // ── WebSocket callbacks ───────────────────────────────────────────────────

  void _onData(dynamic raw) {
    final Uint8List data;
    if (raw is Uint8List) {
      data = raw;
    } else if (raw is List<int>) {
      data = Uint8List.fromList(raw);
    } else {
      return;
    }
    if (data.isEmpty) return;
    final type = (data[0] >> 4) & 0x0F;

    if (!_connackReceived) {
      if (type == 2) {
        _connackReceived = true;
        final rc = data.length >= 4 ? data[3] : -1;
        if (rc == 0) {
          _connackCompleter?.complete();
        } else {
          debugPrint('[IoT] CONNACK refused — code $rc');
          _connackCompleter?.completeError(Exception('MQTT CONNACK refused (code $rc)'));
        }
      }
      return;
    }

    if (type == 3) _handlePublish(data);
    if (type == 13) {
      _pingRespTimer?.cancel();
      _pingRespTimer = null;
    }
  }

  void _onError(Object error) {
    debugPrint('[IoT] connection error: $error');
    _pingRespTimer?.cancel();
    _pingRespTimer = null;
    _connected = false;
    if (!(_connackCompleter?.isCompleted ?? true)) {
      _connackCompleter?.completeError(error);
    }
    _publishCtrl?.addError(error);
  }

  void _onDone() {
    debugPrint('[IoT] connection closed');
    _pingRespTimer?.cancel();
    _pingRespTimer = null;
    final wasConnected = _connected;
    final connectedAt = _connectedAt;
    _connected = false;
    _connectedAt = null;
    _publishCtrl?.close();
    if (wasConnected) {
      // Treat null connectedAt as an immediate drop (duration zero) so we
      // always take the deferred path rather than calling _onDisconnected
      // directly. A null here means _onDone raced with the connect path.
      final age = connectedAt != null
          ? DateTime.now().difference(connectedAt)
          : Duration.zero;
      if (age < const Duration(seconds: 3)) {
        // Connection dropped very soon after CONNACK — almost certainly AWS IoT
        // closing the previous session's socket (hot restart / duplicate client ID).
        // Delay the reconnect callback so the old socket is fully gone before
        // we open a new connection with the same client ID.
        final gen = _generation;
        debugPrint('[IoT] connection dropped within ${age.inMilliseconds}ms — deferring reconnect');
        Future.delayed(const Duration(seconds: 10), () {
          if (gen == _generation && !_connected) _onDisconnected?.call();
        });
      } else {
        _onDisconnected?.call();
      }
    } else if (!(_connackCompleter?.isCompleted ?? true)) {
      // Channel closed before CONNACK — fail fast instead of waiting for timeout
      _connackCompleter!.completeError(StateError('Connection closed during handshake'));
    }
  }

  void _onPingTimeout(int gen) {
    if (gen != _generation) return;
    debugPrint('[IoT] PINGRESP timeout — network unreachable, treating as disconnect');
    _pingRespTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _connected = false;
    _connectedAt = null;
    _publishCtrl?.close();
    _publishCtrl = null;
    _subscription?.cancel();
    _subscription = null;
    _onDisconnected?.call();
  }

  void _handlePublish(Uint8List data) {
    var i = 1;
    while ((data[i++] & 0x80) != 0) {}
    final qos = (data[0] >> 1) & 0x03;
    final topicLen = (data[i] << 8) | data[i + 1];
    i += 2;
    final topic = utf8.decode(data.sublist(i, i + topicLen));
    i += topicLen;
    if (qos > 0) {
      _channel?.sink.add(Uint8List.fromList([0x40, 0x02, data[i++], data[i++]])); // PUBACK
    }
    _publishCtrl?.add((topic: topic, payload: utf8.decode(data.sublist(i))));
  }

  int _pid() => _nextPacketId = (_nextPacketId % 0xFFFF) + 1;

  // ── MQTT packet builders ──────────────────────────────────────────────────

  static List<int> _mqttConnect(String clientId, {int keepAliveSec = 60}) {
    final id = utf8.encode(clientId);
    const vh = [0x00, 0x04, 0x4D, 0x51, 0x54, 0x54, 0x04, 0x02];
    final ka = [(keepAliveSec >> 8) & 0xFF, keepAliveSec & 0xFF];
    final pl = [(id.length >> 8) & 0xFF, id.length & 0xFF, ...id];
    final rem = vh.length + ka.length + pl.length;
    return [0x10, ..._remLen(rem), ...vh, ...ka, ...pl];
  }

  static List<int> _mqttPublish(String topic, String msg, int id, {int qos = 1}) {
    final t = utf8.encode(topic);
    final p = utf8.encode(msg);
    final vh = [
      (t.length >> 8) & 0xFF, t.length & 0xFF, ...t,
      if (qos > 0) ...<int>[(id >> 8) & 0xFF, id & 0xFF],
    ];
    return [0x30 | ((qos & 0x03) << 1), ..._remLen(vh.length + p.length), ...vh, ...p];
  }

  static List<int> _mqttSubscribe(String topic, int id, {int qos = 1}) {
    final t = utf8.encode(topic);
    final pl = [(t.length >> 8) & 0xFF, t.length & 0xFF, ...t, qos & 0x03];
    final vh = [(id >> 8) & 0xFF, id & 0xFF];
    return [0x82, ..._remLen(vh.length + pl.length), ...vh, ...pl];
  }

  static List<int> _remLen(int len) {
    final r = <int>[];
    do {
      var b = len & 0x7F;
      len >>= 7;
      if (len > 0) b |= 0x80;
      r.add(b);
    } while (len > 0);
    return r;
  }

  static bool _topicMatches(String topic, String filter) {
    if (filter == '#') return true;
    if (filter.endsWith('/#')) return topic.startsWith(filter.substring(0, filter.length - 2));
    if (filter.contains('+')) {
      final pat = filter.split('/').map((p) => p == '+' ? '[^/]+' : RegExp.escape(p)).join('/');
      return RegExp('^$pat\$').hasMatch(topic);
    }
    return topic == filter;
  }
}
