import '../entities/auth_user_entity.dart';

abstract interface class IAuthRepository {
  Future<AuthUserEntity?> getCurrentUser();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  });
}
