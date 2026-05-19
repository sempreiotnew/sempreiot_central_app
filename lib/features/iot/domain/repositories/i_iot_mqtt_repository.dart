import '../entities/mqtt_message_entity.dart';

abstract interface class IIotMqttRepository {
  bool get isConnected;
  Future<void> connect();
  void disconnect();
  void publish(String topic, String payload);
  Stream<MqttMessageEntity> subscribe(String topic);
}
