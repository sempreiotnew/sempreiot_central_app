import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../domain/repositories/i_auth_repository.dart';

sealed class RegisterState {
  const RegisterState();
}

final class RegisterIdle extends RegisterState {
  const RegisterIdle();
}

final class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

final class RegisterSuccess extends RegisterState {
  const RegisterSuccess({required this.requiresConfirmation});
  final bool requiresConfirmation;
}

final class RegisterError extends RegisterState {
  const RegisterError(this.message);
  final String message;
}

final registerNotifierProvider =
    NotifierProvider<RegisterNotifier, RegisterState>(RegisterNotifier.new);

class RegisterNotifier extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterIdle();

  IAuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const RegisterLoading();
    try {
      final isComplete = await _repo.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = RegisterSuccess(requiresConfirmation: !isComplete);
    } catch (e) {
      state = RegisterError(_formatError(e));
    }
  }

  void reset() => state = const RegisterIdle();

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('UsernameExistsException')) {
      return 'Já existe uma conta com esse e-mail.';
    }
    if (msg.contains('InvalidPasswordException')) {
      return 'Senha inválida. Use ao menos 8 caracteres com letras e números.';
    }
    if (msg.contains('InvalidParameterException')) {
      return 'Verifique os dados informados e tente novamente.';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }
}
