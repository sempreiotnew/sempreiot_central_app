import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_user_entity.dart';
import '../domain/repositories/i_auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>(
  (_) => AuthRepositoryImpl(),
);

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUserEntity?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthUserEntity?> {
  @override
  Future<AuthUserEntity?> build() {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> signInWithGoogle() => _signIn(
        () => ref.read(authRepositoryProvider).signInWithGoogle(),
      );

  Future<void> signInWithApple() => _signIn(
        () => ref.read(authRepositoryProvider).signInWithApple(),
      );

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) =>
      _signIn(
        () => ref.read(authRepositoryProvider).signInWithEmailPassword(
              email: email,
              password: password,
            ),
      );

  Future<void> signOut() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).signOut();
    // On web, Amplify redirects the page to Cognito's logout endpoint and back,
    // so the app reloads fresh — no state update needed here (avoids double render).
    if (!kIsWeb) {
      state = const AsyncData(null);
    }
  }

  Future<void> _signIn(Future<void> Function() signInFn) async {
    state = const AsyncLoading();
    try {
      await signInFn();
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AsyncData(user);
    } on UserCancelledException {
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
