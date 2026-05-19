import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// ignore: avoid_web_libraries_in_flutter
MqttClient createMqttClient(String server, String clientId) {
  // mqtt_client uses the `server` value as-is when it contains '://',
  // so the full signed wss:// URL is passed through unchanged.
  return MqttServerClient(server, clientId)
    ..useWebSocket = true
    ..secure = true
    ..port = 443;
}
