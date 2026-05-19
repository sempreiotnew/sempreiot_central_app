import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/services/sigv4_signer.dart';
import '../../domain/entities/mqtt_message_entity.dart';
import '../../domain/repositories/i_iot_mqtt_repository.dart';
import '../services/iot_credentials_service.dart';
import '../services/iot_mqtt_bridge.dart';

String get _iotEndpoint => dotenv.env['AWS_IOT_ENDPOINT']!;
String get _region => dotenv.env['AWS_REGION']!;

class IotMqttRepositoryImpl implements IIotMqttRepository {
  final IotCredentialsService _credentialsService;
  final IotMqttBridge _bridge;

  IotMqttRepositoryImpl({IotCredentialsService? credentialsService})
      : _credentialsService = credentialsService ?? IotCredentialsService(),
        _bridge = createIotMqttBridge();

  @override
  bool get isConnected => _bridge.isConnected;

  @override
  Future<void> connect({void Function()? onDisconnected}) async {
    final creds = await _credentialsService.fetch();

    final signedUrl = SigV4Signer.buildSignedWebSocketUrl(
      host: _iotEndpoint,
      region: _region,
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken,
    );

    await _bridge.connect(
      signedUrl,
      creds.identityId,
      onDisconnected: onDisconnected,
    );
  }

  @override
  void disconnect() => _bridge.disconnect();

  @override
  void publish(String topic, String payload) => _bridge.publish(topic, payload);

  @override
  Stream<MqttMessageEntity> subscribe(String topic) {
    return _bridge
        .subscribe(topic)
        .map((m) => MqttMessageEntity(topic: m.topic, payload: m.payload));
  }
}
