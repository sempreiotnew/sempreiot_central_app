import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kDefaultPin = '4294';

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

  void verify(String pin) {
    if (pin == _kDefaultPin) {
      state = const CentralAuthenticated();
    } else {
      state = const CentralPinError('Código incorreto. Tente novamente.');
    }
  }

  void reset() => state = const CentralUnauthenticated();
}
