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
    required this.displayIdentifier,
  });
  final String username;
  final String password;
  final bool isPhone;
  final bool requiresConfirmation;
  /// Original email or phone (e.g. +5511999998888) — for display only.
  final String displayIdentifier;
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
        displayIdentifier: identifier,
      );
    } catch (e) {
      state = RegisterError(_formatError(e, isPhone: isPhone));
    }
  }

  void reset() => state = const RegisterIdle();

  String _formatError(Object e, {bool isPhone = false}) {
    final msg = e.toString();
    if (msg.contains('UsernameExistsException')) {
      return isPhone
          ? 'field:identifier:Este número já está cadastrado.'
          : 'field:identifier:Este e-mail já está cadastrado.';
    }
    if (msg.contains('InvalidPasswordException')) {
      return 'field:password:Senha inválida. Use ao menos 8 caracteres com letras e números.';
    }
    if (msg.contains('InvalidParameterException')) {
      return isPhone
          ? 'field:identifier:Telefone inválido. Use o formato: +5511999998888'
          : 'field:identifier:Verifique o e-mail informado.';
    }
    if (msg.contains('InvalidSmsRoleTrustRelationship') ||
        msg.contains('SNSSandbox')) {
      return 'field:identifier:Envio de SMS indisponível. Tente usar e-mail.';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }
}
