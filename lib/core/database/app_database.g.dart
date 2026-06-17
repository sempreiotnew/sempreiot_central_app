// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SerialPacketsTable extends SerialPackets
    with TableInfo<$SerialPacketsTable, SerialPacket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SerialPacketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawBytesMeta =
      const VerificationMeta('rawBytes');
  @override
  late final GeneratedColumn<Uint8List> rawBytes = GeneratedColumn<Uint8List>(
      'raw_bytes', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _byteLengthMeta =
      const VerificationMeta('byteLength');
  @override
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
      'byte_length', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hexPreviewMeta =
      const VerificationMeta('hexPreview');
  @override
  late final GeneratedColumn<String> hexPreview = GeneratedColumn<String>(
      'hex_preview', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, receivedAt, deviceId, rawBytes, byteLength, hexPreview];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'serial_packets';
  @override
  VerificationContext validateIntegrity(Insertable<SerialPacket> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('raw_bytes')) {
      context.handle(_rawBytesMeta,
          rawBytes.isAcceptableOrUnknown(data['raw_bytes']!, _rawBytesMeta));
    } else if (isInserting) {
      context.missing(_rawBytesMeta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
          _byteLengthMeta,
          byteLength.isAcceptableOrUnknown(
              data['byte_length']!, _byteLengthMeta));
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('hex_preview')) {
      context.handle(
          _hexPreviewMeta,
          hexPreview.isAcceptableOrUnknown(
              data['hex_preview']!, _hexPreviewMeta));
    } else if (isInserting) {
      context.missing(_hexPreviewMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SerialPacket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SerialPacket(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      rawBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}raw_bytes'])!,
      byteLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}byte_length'])!,
      hexPreview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hex_preview'])!,
    );
  }

  @override
  $SerialPacketsTable createAlias(String alias) {
    return $SerialPacketsTable(attachedDatabase, alias);
  }
}

class SerialPacket extends DataClass implements Insertable<SerialPacket> {
  final int id;
  final DateTime receivedAt;
  final String deviceId;
  final Uint8List rawBytes;
  final int byteLength;
  final String hexPreview;
  const SerialPacket(
      {required this.id,
      required this.receivedAt,
      required this.deviceId,
      required this.rawBytes,
      required this.byteLength,
      required this.hexPreview});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['raw_bytes'] = Variable<Uint8List>(rawBytes);
    map['byte_length'] = Variable<int>(byteLength);
    map['hex_preview'] = Variable<String>(hexPreview);
    return map;
  }

  SerialPacketsCompanion toCompanion(bool nullToAbsent) {
    return SerialPacketsCompanion(
      id: Value(id),
      receivedAt: Value(receivedAt),
      deviceId: Value(deviceId),
      rawBytes: Value(rawBytes),
      byteLength: Value(byteLength),
      hexPreview: Value(hexPreview),
    );
  }

  factory SerialPacket.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SerialPacket(
      id: serializer.fromJson<int>(json['id']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      rawBytes: serializer.fromJson<Uint8List>(json['rawBytes']),
      byteLength: serializer.fromJson<int>(json['byteLength']),
      hexPreview: serializer.fromJson<String>(json['hexPreview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'rawBytes': serializer.toJson<Uint8List>(rawBytes),
      'byteLength': serializer.toJson<int>(byteLength),
      'hexPreview': serializer.toJson<String>(hexPreview),
    };
  }

  SerialPacket copyWith(
          {int? id,
          DateTime? receivedAt,
          String? deviceId,
          Uint8List? rawBytes,
          int? byteLength,
          String? hexPreview}) =>
      SerialPacket(
        id: id ?? this.id,
        receivedAt: receivedAt ?? this.receivedAt,
        deviceId: deviceId ?? this.deviceId,
        rawBytes: rawBytes ?? this.rawBytes,
        byteLength: byteLength ?? this.byteLength,
        hexPreview: hexPreview ?? this.hexPreview,
      );
  SerialPacket copyWithCompanion(SerialPacketsCompanion data) {
    return SerialPacket(
      id: data.id.present ? data.id.value : this.id,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      rawBytes: data.rawBytes.present ? data.rawBytes.value : this.rawBytes,
      byteLength:
          data.byteLength.present ? data.byteLength.value : this.byteLength,
      hexPreview:
          data.hexPreview.present ? data.hexPreview.value : this.hexPreview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SerialPacket(')
          ..write('id: $id, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rawBytes: $rawBytes, ')
          ..write('byteLength: $byteLength, ')
          ..write('hexPreview: $hexPreview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, receivedAt, deviceId,
      $driftBlobEquality.hash(rawBytes), byteLength, hexPreview);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SerialPacket &&
          other.id == this.id &&
          other.receivedAt == this.receivedAt &&
          other.deviceId == this.deviceId &&
          $driftBlobEquality.equals(other.rawBytes, this.rawBytes) &&
          other.byteLength == this.byteLength &&
          other.hexPreview == this.hexPreview);
}

class SerialPacketsCompanion extends UpdateCompanion<SerialPacket> {
  final Value<int> id;
  final Value<DateTime> receivedAt;
  final Value<String> deviceId;
  final Value<Uint8List> rawBytes;
  final Value<int> byteLength;
  final Value<String> hexPreview;
  const SerialPacketsCompanion({
    this.id = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rawBytes = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.hexPreview = const Value.absent(),
  });
  SerialPacketsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime receivedAt,
    required String deviceId,
    required Uint8List rawBytes,
    required int byteLength,
    required String hexPreview,
  })  : receivedAt = Value(receivedAt),
        deviceId = Value(deviceId),
        rawBytes = Value(rawBytes),
        byteLength = Value(byteLength),
        hexPreview = Value(hexPreview);
  static Insertable<SerialPacket> custom({
    Expression<int>? id,
    Expression<DateTime>? receivedAt,
    Expression<String>? deviceId,
    Expression<Uint8List>? rawBytes,
    Expression<int>? byteLength,
    Expression<String>? hexPreview,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receivedAt != null) 'received_at': receivedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rawBytes != null) 'raw_bytes': rawBytes,
      if (byteLength != null) 'byte_length': byteLength,
      if (hexPreview != null) 'hex_preview': hexPreview,
    });
  }

  SerialPacketsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? receivedAt,
      Value<String>? deviceId,
      Value<Uint8List>? rawBytes,
      Value<int>? byteLength,
      Value<String>? hexPreview}) {
    return SerialPacketsCompanion(
      id: id ?? this.id,
      receivedAt: receivedAt ?? this.receivedAt,
      deviceId: deviceId ?? this.deviceId,
      rawBytes: rawBytes ?? this.rawBytes,
      byteLength: byteLength ?? this.byteLength,
      hexPreview: hexPreview ?? this.hexPreview,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rawBytes.present) {
      map['raw_bytes'] = Variable<Uint8List>(rawBytes.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (hexPreview.present) {
      map['hex_preview'] = Variable<String>(hexPreview.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SerialPacketsCompanion(')
          ..write('id: $id, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rawBytes: $rawBytes, ')
          ..write('byteLength: $byteLength, ')
          ..write('hexPreview: $hexPreview')
          ..write(')'))
        .toString();
  }
}

class $DeviceMetadataTable extends DeviceMetadata
    with TableInfo<$DeviceMetadataTable, DeviceMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DeviceMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceMetadataData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $DeviceMetadataTable createAlias(String alias) {
    return $DeviceMetadataTable(attachedDatabase, alias);
  }
}

class DeviceMetadataData extends DataClass
    implements Insertable<DeviceMetadataData> {
  final String key;
  final String value;
  const DeviceMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  DeviceMetadataCompanion toCompanion(bool nullToAbsent) {
    return DeviceMetadataCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory DeviceMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  DeviceMetadataData copyWith({String? key, String? value}) =>
      DeviceMetadataData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  DeviceMetadataData copyWithCompanion(DeviceMetadataCompanion data) {
    return DeviceMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class DeviceMetadataCompanion extends UpdateCompanion<DeviceMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const DeviceMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<DeviceMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceMetadataCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return DeviceMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SerialPacketsTable serialPackets = $SerialPacketsTable(this);
  late final $DeviceMetadataTable deviceMetadata = $DeviceMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [serialPackets, deviceMetadata];
}

typedef $$SerialPacketsTableCreateCompanionBuilder = SerialPacketsCompanion
    Function({
  Value<int> id,
  required DateTime receivedAt,
  required String deviceId,
  required Uint8List rawBytes,
  required int byteLength,
  required String hexPreview,
});
typedef $$SerialPacketsTableUpdateCompanionBuilder = SerialPacketsCompanion
    Function({
  Value<int> id,
  Value<DateTime> receivedAt,
  Value<String> deviceId,
  Value<Uint8List> rawBytes,
  Value<int> byteLength,
  Value<String> hexPreview,
});

class $$SerialPacketsTableFilterComposer
    extends Composer<_$AppDatabase, $SerialPacketsTable> {
  $$SerialPacketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get rawBytes => $composableBuilder(
      column: $table.rawBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get byteLength => $composableBuilder(
      column: $table.byteLength, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hexPreview => $composableBuilder(
      column: $table.hexPreview, builder: (column) => ColumnFilters(column));
}

class $$SerialPacketsTableOrderingComposer
    extends Composer<_$AppDatabase, $SerialPacketsTable> {
  $$SerialPacketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get rawBytes => $composableBuilder(
      column: $table.rawBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get byteLength => $composableBuilder(
      column: $table.byteLength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hexPreview => $composableBuilder(
      column: $table.hexPreview, builder: (column) => ColumnOrderings(column));
}

class $$SerialPacketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SerialPacketsTable> {
  $$SerialPacketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<Uint8List> get rawBytes =>
      $composableBuilder(column: $table.rawBytes, builder: (column) => column);

  GeneratedColumn<int> get byteLength => $composableBuilder(
      column: $table.byteLength, builder: (column) => column);

  GeneratedColumn<String> get hexPreview => $composableBuilder(
      column: $table.hexPreview, builder: (column) => column);
}

class $$SerialPacketsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SerialPacketsTable,
    SerialPacket,
    $$SerialPacketsTableFilterComposer,
    $$SerialPacketsTableOrderingComposer,
    $$SerialPacketsTableAnnotationComposer,
    $$SerialPacketsTableCreateCompanionBuilder,
    $$SerialPacketsTableUpdateCompanionBuilder,
    (
      SerialPacket,
      BaseReferences<_$AppDatabase, $SerialPacketsTable, SerialPacket>
    ),
    SerialPacket,
    PrefetchHooks Function()> {
  $$SerialPacketsTableTableManager(_$AppDatabase db, $SerialPacketsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SerialPacketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SerialPacketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SerialPacketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> receivedAt = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<Uint8List> rawBytes = const Value.absent(),
            Value<int> byteLength = const Value.absent(),
            Value<String> hexPreview = const Value.absent(),
          }) =>
              SerialPacketsCompanion(
            id: id,
            receivedAt: receivedAt,
            deviceId: deviceId,
            rawBytes: rawBytes,
            byteLength: byteLength,
            hexPreview: hexPreview,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime receivedAt,
            required String deviceId,
            required Uint8List rawBytes,
            required int byteLength,
            required String hexPreview,
          }) =>
              SerialPacketsCompanion.insert(
            id: id,
            receivedAt: receivedAt,
            deviceId: deviceId,
            rawBytes: rawBytes,
            byteLength: byteLength,
            hexPreview: hexPreview,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SerialPacketsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SerialPacketsTable,
    SerialPacket,
    $$SerialPacketsTableFilterComposer,
    $$SerialPacketsTableOrderingComposer,
    $$SerialPacketsTableAnnotationComposer,
    $$SerialPacketsTableCreateCompanionBuilder,
    $$SerialPacketsTableUpdateCompanionBuilder,
    (
      SerialPacket,
      BaseReferences<_$AppDatabase, $SerialPacketsTable, SerialPacket>
    ),
    SerialPacket,
    PrefetchHooks Function()>;
typedef $$DeviceMetadataTableCreateCompanionBuilder = DeviceMetadataCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$DeviceMetadataTableUpdateCompanionBuilder = DeviceMetadataCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$DeviceMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceMetadataTable> {
  $$DeviceMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$DeviceMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceMetadataTable> {
  $$DeviceMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$DeviceMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceMetadataTable> {
  $$DeviceMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$DeviceMetadataTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeviceMetadataTable,
    DeviceMetadataData,
    $$DeviceMetadataTableFilterComposer,
    $$DeviceMetadataTableOrderingComposer,
    $$DeviceMetadataTableAnnotationComposer,
    $$DeviceMetadataTableCreateCompanionBuilder,
    $$DeviceMetadataTableUpdateCompanionBuilder,
    (
      DeviceMetadataData,
      BaseReferences<_$AppDatabase, $DeviceMetadataTable, DeviceMetadataData>
    ),
    DeviceMetadataData,
    PrefetchHooks Function()> {
  $$DeviceMetadataTableTableManager(
      _$AppDatabase db, $DeviceMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceMetadataCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceMetadataCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeviceMetadataTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeviceMetadataTable,
    DeviceMetadataData,
    $$DeviceMetadataTableFilterComposer,
    $$DeviceMetadataTableOrderingComposer,
    $$DeviceMetadataTableAnnotationComposer,
    $$DeviceMetadataTableCreateCompanionBuilder,
    $$DeviceMetadataTableUpdateCompanionBuilder,
    (
      DeviceMetadataData,
      BaseReferences<_$AppDatabase, $DeviceMetadataTable, DeviceMetadataData>
    ),
    DeviceMetadataData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SerialPacketsTableTableManager get serialPackets =>
      $$SerialPacketsTableTableManager(_db, _db.serialPackets);
  $$DeviceMetadataTableTableManager get deviceMetadata =>
      $$DeviceMetadataTableTableManager(_db, _db.deviceMetadata);
}
