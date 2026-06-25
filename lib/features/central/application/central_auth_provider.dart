import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

sealed class CentralAuthState {
  const CentralAuthState();
}

final class CentralUnauthenticated extends CentralAuthState {
  const CentralUnauthenticated();
}

final class CentralAuthenticated extends CentralAuthState {
  const CentralAuthenticated();
}

final class CentralPinError extends CentralAuthState {
  const CentralPinError(this.message);
  final String message;
}

final centralAuthProvider =
    NotifierProvider<CentralAuthNotifier, CentralAuthState>(
  CentralAuthNotifier.new,
);

class CentralAuthNotifier extends Notifier<CentralAuthState> {
  @override
  CentralAuthState build() => const CentralUnauthenticated();

  /// Reads the PIN from the local database and validates [pin] against it.
  Future<void> verify(String pin) async {
    final db = ref.read(appDatabaseProvider);

    String storedPin = '';
    try {
      final raw = await db.getMeta('credentials');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        storedPin = map['pin'] as String? ?? '';
      }
    } catch (_) {
      storedPin = '';
    }

    if (storedPin.isEmpty) {
      state = const CentralPinError('PIN não configurado.');
      return;
    }

    if (pin == storedPin) {
      state = const CentralAuthenticated();
    } else {
      state = const CentralPinError('Código incorreto. Tente novamente.');
    }
  }

  void reset() => state = const CentralUnauthenticated();
}
