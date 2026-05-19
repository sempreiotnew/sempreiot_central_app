import 'iot_mqtt_bridge_io.dart' if (dart.library.html) 'iot_mqtt_bridge_web.dart';

export 'iot_mqtt_bridge_io.dart' if (dart.library.html) 'iot_mqtt_bridge_web.dart'
    show IotMqttBridge;

IotMqttBridge createIotMqttBridge() => IotMqttBridge();
