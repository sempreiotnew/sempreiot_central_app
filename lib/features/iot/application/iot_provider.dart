import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/iot_mqtt_repository_impl.dart';
import '../domain/entities/mqtt_message_entity.dart';
import '../domain/repositories/i_iot_mqtt_repository.dart';

final iotMqttRepositoryProvider = Provider<IIotMqttRepository>((_) {
  return IotMqttRepositoryImpl();
});

final iotConnectionProvider =
    AsyncNotifierProvider<IotConnectionNotifier, bool>(
  IotConnectionNotifier.new,
);

class IotConnectionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    ref.onDispose(() {
      ref.read(iotMqttRepositoryProvider).disconnect();
    });
    return false;
  }

  Future<void> connect() async {
    state = const AsyncLoading();
    try {
      await ref.read(iotMqttRepositoryProvider).connect();
      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void disconnect() {
    ref.read(iotMqttRepositoryProvider).disconnect();
    state = const AsyncData(false);
  }
}

// Usage: ref.watch(iotMessageStreamProvider('my/topic'))
final iotMessageStreamProvider =
    StreamProvider.family<MqttMessageEntity, String>((ref, topic) {
  return ref.read(iotMqttRepositoryProvider).subscribe(topic);
});
