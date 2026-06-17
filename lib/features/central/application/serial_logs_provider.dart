import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

final serialLogsProvider = StreamProvider<List<SerialPacket>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Fetch the latest 500 DESC, then reverse so newest is at the bottom
  return (db.select(db.serialPackets)
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])
        ..limit(500))
      .watch()
      .map((rows) => rows.reversed.toList());
});
