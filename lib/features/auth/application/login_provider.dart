import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

sealed class LoginState {
  const LoginState();
}

final class LoginIdle extends LoginState {
  const LoginIdle();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess();
}

final class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

final loginNotifierProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginIdle();

  Future<void> signIn({
    required String identifier,
    required String password,
    required bool isPhone,
  }) async {
    state = const LoginLoading();
    try {
      await ref.read(authNotifierProvider.notifier).signInWithIdentifier(
            identifier: identifier,
            password: password,
            isPhone: isPhone,
          );
      state = const LoginSuccess();
    } catch (e) {
      state = LoginError(_formatError(e, isPhone: isPhone));
    }
  }

  void reset() => state = const LoginIdle();

  String _formatError(Object e, {required bool isPhone}) {
    final msg = e.toString();
    if (msg.contains('NotAuthorizedException') ||
        msg.contains('UserNotFoundException')) {
      return isPhone
          ? 'field:identifier:Número ou senha incorretos.'
          : 'field:identifier:E-mail ou senha incorretos.';
    }
    if (msg.contains('UserNotConfirmedException')) {
      return isPhone
          ? 'field:identifier:Número não confirmado. Verifique seu SMS.'
          : 'field:identifier:E-mail não confirmado. Verifique sua caixa de entrada.';
    }
    if (msg.contains('InvalidParameterException')) {
      return isPhone
          ? 'field:identifier:Telefone inválido. Use o formato: +5511999998888'
          : 'field:identifier:Verifique o e-mail informado.';
    }
    if (msg.contains('TooManyRequestsException') ||
        msg.contains('LimitExceededException')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    return 'Erro ao entrar. Tente novamente.';
  }
}
