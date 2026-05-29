import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../domain/entities/auth_user_entity.dart';
import '../../domain/entities/sign_up_result.dart' show AuthSignUpResult;
import '../../domain/repositories/i_auth_repository.dart';

final class AuthRepositoryImpl implements IAuthRepository {
  @override
  Future<AuthUserEntity?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return AuthUserEntity(userId: user.userId);
    } on SignedOutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.google,
      options: const SignInWithWebUIOptions(
        pluginOptions: CognitoSignInWithWebUIPluginOptions(
          prompt: [CognitoSignInWithWebUIPrompt.selectAccount],
        ),
      ),
    );
  }

  @override
  Future<void> signInWithApple() async {
    await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.apple,
      options: const SignInWithWebUIOptions(
        pluginOptions: CognitoSignInWithWebUIPluginOptions(
          prompt: [CognitoSignInWithWebUIPrompt.selectAccount],
        ),
      ),
    );
  }

  @override
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Amplify.Auth.signIn(username: email, password: password);
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String name,
    required String identifier,
    required String password,
    required bool isPhone,
  }) async {
    final attrs = <AuthUserAttributeKey, String>{
      AuthUserAttributeKey.name: name,
    };
    if (isPhone) {
      attrs[AuthUserAttributeKey.phoneNumber] = identifier;
    } else {
      attrs[AuthUserAttributeKey.email] = identifier;
    }
    final result = await Amplify.Auth.signUp(
      username: identifier,
      password: password,
      options: SignUpOptions(userAttributes: attrs),
    );
    return AuthSignUpResult(
      username: identifier,
      isComplete: result.isSignUpComplete,
    );
  }

  @override
  Future<void> confirmSignUp({
    required String username,
    required String code,
  }) async {
    await Amplify.Auth.confirmSignUp(
      username: username,
      confirmationCode: code,
    );
  }

  @override
  Future<void> resendSignUpCode({required String username}) async {
    await Amplify.Auth.resendSignUpCode(username: username);
  }
}
