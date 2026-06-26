import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

final deviceCredentialsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final raw = await db.getMeta('credentials');
  if (raw == null || raw.isEmpty) return {};
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
});

final deviceAccessProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final raw = await db.getMeta('access');
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    // Backwards-compat: single object stored before array migration
    if (decoded is Map<String, dynamic>) {
      final subId = decoded['subId'] as String? ?? '';
      return subId.isNotEmpty ? [decoded] : [];
    }
    return [];
  } catch (_) {
    return [];
  }
});
