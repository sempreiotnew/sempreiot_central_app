import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Mobile/desktop MQTT 3.1.1 over WebSocket.
/// Uses dart:io WebSocket.connect() directly — bypasses mqtt_client's
/// Uri.replace(port) call, which corrupts percent-encoded SigV4 query params.
class IotMqttBridge {
  WebSocket? _ws;
  int _nextPacketId = 0;
  StreamController<({String topic, String payload})>? _publishCtrl;
  Timer? _pingTimer;
  Completer<void>? _connackCompleter;
  bool _connackReceived = false;
  void Function()? _onDisconnected;

  bool get isConnected => _ws?.readyState == WebSocket.open;

  Future<void> connect(
    String signedUrl,
    String clientId, {
    int keepAliveSec = 60,
    void Function()? onDisconnected,
  }) async {
    _onDisconnected = onDisconnected;
    _connackCompleter = Completer();
    _connackReceived = false;
    _publishCtrl = StreamController.broadcast();

    debugPrint('[IoT] connecting — clientId: $clientId');
    try {
      _ws = await WebSocket.connect(signedUrl, protocols: const ['mqtt']);
    } on WebSocketException catch (e) {
      debugPrint('[IoT] WebSocket upgrade failed');
      await _diagnose(signedUrl, e);
      rethrow;
    }

    _ws!.listen(_onData, onError: _onError, onDone: _onDone, cancelOnError: false);
    _ws!.add(Uint8List.fromList(_buildConnect(clientId, keepAliveSec)));

    await _connackCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('MQTT CONNACK timeout'),
    );

    debugPrint('[IoT] MQTT connected ✓');

    _pingTimer = Timer.periodic(Duration(seconds: keepAliveSec ~/ 2), (_) {
      if (isConnected) _ws!.add(Uint8List.fromList(const [0xC0, 0x00]));
    });
  }

  void disconnect() {
    _onDisconnected = null; // intentional — suppress reconnect callback
    _pingTimer?.cancel();
    if (isConnected) _ws?.add(Uint8List.fromList(const [0xE0, 0x00]));
    _ws?.close();
    _ws = null;
    _publishCtrl?.close();
    debugPrint('[IoT] disconnected');
  }

  void publish(String topic, String payload, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    debugPrint('[IoT] → publish [$topic]: $payload');
    _ws!.add(Uint8List.fromList(_buildPublish(topic, payload, _pid(), qos)));
  }

  Stream<({String topic, String payload})> subscribe(String topic, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    debugPrint('[IoT] subscribing to: $topic');
    _ws!.add(Uint8List.fromList(_buildSubscribe(topic, _pid(), qos)));
    return _publishCtrl!.stream.where((m) => _topicMatches(m.topic, topic));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    final data = raw is Uint8List ? raw : Uint8List.fromList(raw as List<int>);
    if (data.isEmpty) return;
    final type = (data[0] >> 4) & 0x0F;

    if (!_connackReceived) {
      if (type == 2) {
        final rc = data.length >= 4 ? data[3] : -1;
        _connackReceived = true;
        if (rc == 0) {
          _connackCompleter?.complete();
        } else {
          debugPrint('[IoT] CONNACK refused — code $rc');
          _connackCompleter?.completeError(
            Exception('MQTT connection refused (code $rc)'),
          );
        }
      }
      return;
    }

    switch (type) {
      case 3:
        _handlePublish(data);
      case 4: // PUBACK
        break;
      case 13: // PINGRESP
        break;
    }
  }

  void _onError(Object error) {
    debugPrint('[IoT] connection error: $error');
    if (!(_connackCompleter?.isCompleted ?? true)) {
      _connackCompleter?.completeError(error);
    }
    _publishCtrl?.addError(error);
  }

  void _onDone() {
    debugPrint('[IoT] connection closed');
    _publishCtrl?.close();
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
      final pMsb = data[i++];
      final pLsb = data[i++];
      _ws?.add(Uint8List.fromList([0x40, 0x02, pMsb, pLsb])); // PUBACK
    }

    _publishCtrl?.add((topic: topic, payload: utf8.decode(data.sublist(i))));
  }

  int _pid() => _nextPacketId = (_nextPacketId % 0xFFFF) + 1;

  static Future<void> _diagnose(String wsUrl, WebSocketException original) async {
    try {
      final httpUrl = wsUrl.replaceFirst(RegExp(r'^wss://'), 'https://');
      final client = HttpClient();
      final request = await client.openUrl('GET', Uri.parse(httpUrl));
      request.headers
        ..set('Connection', 'Upgrade')
        ..set('Upgrade', 'websocket')
        ..set('Sec-WebSocket-Version', '13')
        ..set('Sec-WebSocket-Protocol', 'mqtt')
        ..set('Sec-WebSocket-Key',
            base64.encode(List<int>.generate(16, (_) => Random().nextInt(256))));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close(force: true);
      debugPrint('[IoT] AWS response ${response.statusCode}: $body');
    } catch (e) {
      debugPrint('[IoT] diagnostic failed: $e — original: $original');
    }
  }

  // ── Packet builders ───────────────────────────────────────────────────────

  static List<int> _buildConnect(String clientId, int keepAliveSec) {
    final id = utf8.encode(clientId);
    const vh = [
      0x00, 0x04, 0x4D, 0x51, 0x54, 0x54, // "MQTT"
      0x04, // Level 4 = MQTT 3.1.1
      0x02, // Flags: clean session
    ];
    final ka = [(keepAliveSec >> 8) & 0xFF, keepAliveSec & 0xFF];
    final payload = [(id.length >> 8) & 0xFF, id.length & 0xFF, ...id];
    final rem = vh.length + ka.length + payload.length;
    return [0x10, ..._remLen(rem), ...vh, ...ka, ...payload];
  }

  static List<int> _buildPublish(String topic, String msg, int id, int qos) {
    final t = utf8.encode(topic);
    final p = utf8.encode(msg);
    final vh = [
      (t.length >> 8) & 0xFF, t.length & 0xFF, ...t,
      if (qos > 0) ...<int>[(id >> 8) & 0xFF, id & 0xFF],
    ];
    return [0x30 | ((qos & 0x03) << 1), ..._remLen(vh.length + p.length), ...vh, ...p];
  }

  static List<int> _buildSubscribe(String topic, int id, int qos) {
    final t = utf8.encode(topic);
    final payload = [(t.length >> 8) & 0xFF, t.length & 0xFF, ...t, qos & 0x03];
    final vh = [(id >> 8) & 0xFF, id & 0xFF];
    return [0x82, ..._remLen(vh.length + payload.length), ...vh, ...payload];
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
    if (filter.endsWith('/#')) {
      return topic.startsWith(filter.substring(0, filter.length - 2));
    }
    if (filter.contains('+')) {
      final pat = filter
          .split('/')
          .map((p) => p == '+' ? '[^/]+' : RegExp.escape(p))
          .join('/');
      return RegExp('^$pat\$').hasMatch(topic);
    }
    return topic == filter;
  }
}
