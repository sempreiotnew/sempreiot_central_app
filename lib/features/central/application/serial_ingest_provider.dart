import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'serial_provider.dart';

final serialIngestProvider = Provider<void>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notifier = ref.watch(serialProvider.notifier);
  final sub = notifier.dataStream.listen((bytes) async {
    final deviceId = notifier.connectedDeviceId ?? 'unknown';
    await db.into(db.serialPackets).insert(SerialPacketsCompanion.insert(
          receivedAt: DateTime.now().toUtc(),
          deviceId: deviceId,
          rawBytes: bytes,
          byteLength: bytes.length,
          hexPreview: _hexPreview(bytes),
        ));
  });
  ref.onDispose(sub.cancel);
});

String _hexPreview(Uint8List bytes) {
  final end = bytes.length < 32 ? bytes.length : 32;
  return bytes
      .sublist(0, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ');
}
