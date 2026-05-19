import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String server, String clientId) =>
    MqttBrowserClient(server, clientId);
