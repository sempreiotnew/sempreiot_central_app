import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory_io.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart';

MqttClient buildMqttClient(String server, String clientId) =>
    createMqttClient(server, clientId);
