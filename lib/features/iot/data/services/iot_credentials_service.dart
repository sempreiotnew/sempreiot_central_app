

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

class AwsCredentials {
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
  final String identityId;
  final String userId; // Cognito User Pool sub — stable, platform-independent primary key

  const AwsCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.identityId,
    required this.userId,
  });
}

class IotCredentialsService {
  static const _forceRefreshAfter = Duration(minutes: 25);
  DateTime? _lastForcedRefresh;

  Future<AwsCredentials> fetch() async {
    // Force a token refresh on the first call (covers hot restart — new instance,
    // _lastForcedRefresh is null) or after 25 min (safety net in case the auth
    // timer missed a beat). Rapid reconnects within that window use Amplify's
    // cache, which avoids hammering Cognito's token endpoint every 5 seconds.
    final now = DateTime.now();
    final shouldForce = _lastForcedRefresh == null ||
        now.difference(_lastForcedRefresh!) >= _forceRefreshAfter;
    if (shouldForce) _lastForcedRefresh = now;

    final session = await Amplify.Auth.fetchAuthSession(
      options: FetchAuthSessionOptions(forceRefresh: shouldForce),
    ) as CognitoAuthSession;

    final identityId = session.identityIdResult.value;
    final creds = session.credentialsResult.value;
    final userId = session.userPoolTokensResult.value.userId;

    debugPrint('[IoT] ── Credentials AUTH ─────────────────');
    debugPrint('[IoT] User Pool sub : $userId');
    debugPrint('[IoT] Identity ID   : $identityId');
    debugPrint('[IoT] AccessKeyId   : ${creds.accessKeyId}');
    debugPrint('[IoT] isSignedIn: ${session.isSignedIn} ');
    debugPrint('[IoT] ────────────────────────────────────────────');

    final awsCreds = AwsCredentials(
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken ?? '',
      identityId: identityId,
      userId: userId,
    );


    return awsCreds;
  }

  void reset() => _lastForcedRefresh = null;
}
