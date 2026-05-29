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
  const RegisterSuccess({
    required this.username,
    required this.password,
    required this.isPhone,
    required this.requiresConfirmation,
  });
  final String username;
  final String password;
  final bool isPhone;
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
    required String identifier,
    required String password,
    required bool isPhone,
  }) async {
    state = const RegisterLoading();
    try {
      final result = await _repo.signUp(
        name: name,
        identifier: identifier,
        password: password,
        isPhone: isPhone,
      );
      state = RegisterSuccess(
        username: result.username,
        password: password,
        isPhone: isPhone,
        requiresConfirmation: !result.isComplete,
      );
    } catch (e) {
      state = RegisterError(_formatError(e));
    }
  }

  void reset() => state = const RegisterIdle();

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('UsernameExistsException')) {
      return 'Já existe uma conta com esse identificador.';
    }
    if (msg.contains('InvalidPasswordException')) {
      return 'Senha inválida. Use ao menos 8 caracteres com letras e números.';
    }
    if (msg.contains('InvalidParameterException')) {
      return 'Verifique os dados informados e tente novamente.';
    }
    if (msg.contains('InvalidSmsRoleTrustRelationship') ||
        msg.contains('SNSSandbox')) {
      return 'Envio de SMS indisponível. Tente usar e-mail.';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }
}
