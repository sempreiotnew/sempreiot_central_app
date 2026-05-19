// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Web MQTT 3.1.1 over WebSocket using dart:html directly.
/// Mirrors the IO bridge approach — avoids mqtt_client browser quirks.
class IotMqttBridge {
  html.WebSocket? _ws;
  int _nextPacketId = 0;
  StreamController<({String topic, String payload})>? _publishCtrl;
  Timer? _pingTimer;
  Completer<void>? _connackCompleter;
  bool _connackReceived = false;
  void Function()? _onDisconnected;

  bool get isConnected => _ws?.readyState == html.WebSocket.OPEN;

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

    debugPrint('[IoT] [web] connecting — clientId: $clientId');

    _ws = html.WebSocket(signedUrl, ['mqtt']);
    _ws!.binaryType = 'arraybuffer';

    final openCompleter = Completer<void>();
    late StreamSubscription<html.Event> openSub;
    late StreamSubscription<html.Event> errSub;

    openSub = _ws!.onOpen.listen((_) {
      if (!openCompleter.isCompleted) openCompleter.complete();
      openSub.cancel();
      errSub.cancel();
    });
    errSub = _ws!.onError.listen((event) {
      if (!openCompleter.isCompleted) {
        openCompleter.completeError(Exception('WebSocket open failed'));
        openSub.cancel();
        errSub.cancel();
      }
    });

    await openCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('WebSocket open timeout'),
    );

    _ws!.onMessage.listen(_onMessage);
    _ws!.onError.listen((e) {
      debugPrint('[IoT] [web] connection error: $e');
      if (!(_connackCompleter?.isCompleted ?? true)) {
        _connackCompleter?.completeError(Exception('WebSocket error'));
      }
      _publishCtrl?.addError(Exception('WebSocket error'));
    });
    _ws!.onClose.listen((_) {
      debugPrint('[IoT] [web] connection closed');
      _publishCtrl?.close();
      _onDisconnected?.call();
    });

    _ws!.send(Uint8List.fromList(_buildConnect(clientId, keepAliveSec)));

    await _connackCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('MQTT CONNACK timeout'),
    );

    debugPrint('[IoT] [web] MQTT connected ✓');

    _pingTimer = Timer.periodic(Duration(seconds: keepAliveSec ~/ 2), (_) {
      if (isConnected) _ws!.send(Uint8List.fromList(const [0xC0, 0x00]));
    });
  }

  void disconnect() {
    _onDisconnected = null; // intentional — suppress reconnect callback
    _pingTimer?.cancel();
    if (isConnected) _ws?.send(Uint8List.fromList(const [0xE0, 0x00]));
    _ws?.close();
    _ws = null;
    _publishCtrl?.close();
    debugPrint('[IoT] [web] disconnected');
  }

  void publish(String topic, String payload, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    debugPrint('[IoT] [web] → publish [$topic]: $payload');
    _ws!.send(Uint8List.fromList(_buildPublish(topic, payload, _pid(), qos)));
  }

  Stream<({String topic, String payload})> subscribe(String topic, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    debugPrint('[IoT] [web] subscribing to: $topic');
    _ws!.send(Uint8List.fromList(_buildSubscribe(topic, _pid(), qos)));
    return _publishCtrl!.stream.where((m) => _topicMatches(m.topic, topic));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onMessage(html.MessageEvent event) {
    final raw = event.data;
    if (raw is! ByteBuffer) return;
    final data = Uint8List.view(raw);
    if (data.isEmpty) return;

    final type = (data[0] >> 4) & 0x0F;

    if (!_connackReceived) {
      if (type == 2) {
        final rc = data.length >= 4 ? data[3] : -1;
        _connackReceived = true;
        if (rc == 0) {
          _connackCompleter?.complete();
        } else {
          debugPrint('[IoT] [web] CONNACK refused — code $rc');
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
      _ws?.send(Uint8List.fromList([0x40, 0x02, pMsb, pLsb])); // PUBACK
    }

    _publishCtrl?.add((topic: topic, payload: utf8.decode(data.sublist(i))));
  }

  int _pid() => _nextPacketId = (_nextPacketId % 0xFFFF) + 1;

  // ── Packet builders (identical to IO bridge) ──────────────────────────────

  static List<int> _buildConnect(String clientId, int keepAliveSec) {
    final id = utf8.encode(clientId);
    const vh = [
      0x00, 0x04, 0x4D, 0x51, 0x54, 0x54,
      0x04, 0x02,
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
