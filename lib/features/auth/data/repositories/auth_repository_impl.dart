import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../domain/entities/auth_user_entity.dart';
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
}
