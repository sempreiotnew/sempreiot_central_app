import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class SerialPackets extends Table {
  IntColumn get id          => integer().autoIncrement()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get deviceId   => text()();
  BlobColumn get rawBytes   => blob()();
  IntColumn get byteLength  => integer()();
  TextColumn get hexPreview => text()();
}

/// Key/value store for app settings and device configuration.
/// Values are JSON-encoded strings to support any future type.
class DeviceMetadata extends Table {
  TextColumn get key   => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [SerialPackets, DeviceMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sempreiot'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_received_at ON serial_packets(received_at DESC)',
      );
      await seedDefaultMetadata();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(deviceMetadata);
      }
      if (from < 3) {
        // Seeds new defaults; insertOrIgnore preserves existing rows.
        await seedDefaultMetadata();
      }
    },
  );

  Future<void> deleteOlderThan(DateTime cutoff) =>
      (delete(serialPackets)
            ..where((t) => t.receivedAt.isSmallerThanValue(cutoff)))
          .go();

  Future<void> deleteAllPackets() => delete(serialPackets).go();

  /// Seeds the three default metadata rows. Safe to call multiple times —
  /// uses insertOrIgnore so existing values (e.g. user-set pin) are preserved.
  Future<void> seedDefaultMetadata() async {
    Future<void> seed(String key, Object defaults) =>
        into(deviceMetadata).insert(
          DeviceMetadataCompanion.insert(key: key, value: jsonEncode(defaults)),
          mode: InsertMode.insertOrIgnore,
        );

    await seed('info', {
      'name': '',
      'firmware_version': '',
      'hash': '',
      'old_hash': '',
      'created_at': '',
      'updated_at': '',
    });
    await seed('credentials', {'pin': '', 'root': '', 'password': ''});
    await seed('access', <dynamic>[]);
    await seed('iot', {'iot_client_id': '', 'iot_password': ''});
  }

  Future<void> clearAllMeta() => delete(deviceMetadata).go();

  // Metadata helpers — upsert and read by key
  Future<void> setMeta(String key, String value) =>
      into(deviceMetadata).insertOnConflictUpdate(
        DeviceMetadataCompanion.insert(key: key, value: value),
      );

  Future<String?> getMeta(String key) async {
    final row = await (select(deviceMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
