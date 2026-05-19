import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Web MQTT bridge — wraps MqttBrowserClient.
/// The browser's native WebSocket handles the signed URL correctly.
class IotMqttBridge {
  MqttBrowserClient? _client;
  final _publishCtrl = StreamController<({String topic, String payload})>.broadcast();

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect(
    String signedUrl,
    String clientId, {
    int keepAliveSec = 60,
  }) async {
    _client = MqttBrowserClient(signedUrl, clientId)
      ..keepAlivePeriod = keepAliveSec
      ..websocketProtocols = ['mqtt']
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();

    final status = await _client!.connect();
    if (status?.state != MqttConnectionState.connected) {
      _client!.disconnect();
      throw Exception('IoT MQTT connection failed: ${status?.returnCode}');
    }

    _client!.updates?.listen((messages) {
      for (final msg in messages) {
        final pub = msg.payload as MqttPublishMessage;
        final bytes = Uint8List.fromList(pub.payload.message.toList());
        _publishCtrl.add((topic: msg.topic, payload: utf8.decode(bytes)));
      }
    });
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
  }

  void publish(String topic, String payload, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(
      topic,
      qos == 0 ? MqttQos.atMostOnce : MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  Stream<({String topic, String payload})> subscribe(String topic, {int qos = 1}) {
    if (!isConnected) throw StateError('Not connected');
    _client!.subscribe(topic, qos == 0 ? MqttQos.atMostOnce : MqttQos.atLeastOnce);
    return _publishCtrl.stream.where((m) => _topicMatches(m.topic, topic));
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
