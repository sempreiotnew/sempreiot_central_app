import '../entities/auth_user_entity.dart';
import '../entities/sign_up_result.dart';

abstract interface class IAuthRepository {
  Future<AuthUserEntity?> getCurrentUser();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthSignUpResult> signUp({
    required String name,
    required String identifier,
    required String password,
    required bool isPhone,
  });

  Future<void> confirmSignUp({
    required String username,
    required String code,
  });

  Future<void> resendSignUpCode({
    required String username,
  });
}
