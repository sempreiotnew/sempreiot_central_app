import '../entities/auth_user_entity.dart';

abstract interface class IAuthRepository {
  Future<AuthUserEntity?> getCurrentUser();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
