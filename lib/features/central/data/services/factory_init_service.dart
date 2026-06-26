import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';

/// Applies a factory JSON payload to the [AppDatabase] metadata table.
///
/// The payload is a map of metadata key → JSON-encodable value, e.g.:
/// ```json
/// {
///   "info":        {"firmware_version":"1.0","hash":"abc","old_hash":"","created_at":"2024-01-01","updated_at":"2024-01-01"},
///   "credentials": {"pin":"123456","root":"admin","password":"secret"},
///   "access":      {"subId":"sub-xxxx"}
/// }
/// ```
///
/// All keys are written unconditionally (factory reset semantics).
class FactoryInitService {
  static Future<void> applyFactory(AppDatabase db, String rawJson) async {
    debugPrint('[Factory] Raw JSON received: $rawJson');

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Factory] Failed to parse FACTORY JSON — skipping: $e');
      return;
    }

    // Wipe all previous metadata so keys absent from the FACTORY JSON don't
    // linger from a prior run, then restore clean defaults before overwriting.
    await db.clearAllMeta();
    await db.seedDefaultMetadata();
    debugPrint('[Factory] Metadata cleared and defaults seeded.');

    for (final entry in data.entries) {
      final encoded = entry.value is String
          ? entry.value as String
          : jsonEncode(entry.value);
      await db.setMeta(entry.key, encoded);
      debugPrint('[Factory] Written — key: "${entry.key}", value: $encoded');
    }

    debugPrint(
      '[Factory] Initialization complete. '
      'Keys written: ${data.keys.join(', ')}',
    );
  }
}
