import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
    required bool isPhone,
  }) async {
    final String username;
    if (isPhone) {
      final digits = identifier.replaceAll(RegExp(r'[^\d]'), '');
      username = '$digits@phone.sempreiot';
    } else {
      username = identifier;
    }
    await Amplify.Auth.signIn(username: username, password: password);
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
    // Cognito requires the username to be an email. For phone users we derive
    // a synthetic email from the digits so it's reproducible across sign-in.
    final String username;
    if (isPhone) {
      attrs[AuthUserAttributeKey.phoneNumber] = identifier;
      final digits = identifier.replaceAll(RegExp(r'[^\d]'), '');
      username = '$digits@phone.sempreiot';
    } else {
      attrs[AuthUserAttributeKey.email] = identifier;
      username = identifier;
    }
    try {
      final result = await Amplify.Auth.signUp(
        username: username,
        password: password,
        options: SignUpOptions(userAttributes: attrs),
      );
      return AuthSignUpResult(
        username: username,
        isComplete: result.isSignUpComplete,
      );
    } on UsernameExistsException catch (e) {
      // Cognito creates the user in UNCONFIRMED state immediately on signUp.
      // If they abandon before confirming, the next attempt hits this exception.
      // Try resending the OTP — if it works the account is unconfirmed and we
      // can resume the confirmation flow. If it fails the account is confirmed
      // (real duplicate) and we surface the original error.
      try {
        await Amplify.Auth.resendSignUpCode(username: username);
        return AuthSignUpResult(username: username, isComplete: false);
      } catch (_) {
        throw e;
      }
    }
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

  @override
  Future<({bool exists, bool confirmed, bool hasLocalUser})> checkIdentifierExists(
    String identifier, {
    required bool isPhone,
  }) async {
    final String queryParam;
    if (isPhone) {
      final digits = identifier.replaceAll(RegExp(r'[^\d+]'), '');
      final phone = digits.startsWith('+') ? digits : '+$digits';
      queryParam = 'phone=${Uri.encodeComponent(phone)}';
    } else {
      queryParam = 'email=${Uri.encodeComponent(identifier)}';
    }

    final uri = Uri.parse('https://api.sempreiot.com/user/check-email?$queryParam');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return (exists: false, confirmed: false, hasLocalUser: false);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      exists: data['exists'] == true,
      confirmed: data['confirmed'] == true,
      hasLocalUser: data['hasLocalUser'] == true,
    );
  }

  @override
  Future<String?> getSignedInEmail() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken;
      return idToken.claims.customClaims['email'] as String?;
    } catch (_) {
      return null;
    }
  }
}
