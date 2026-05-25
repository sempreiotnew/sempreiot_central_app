import 'dart:convert';
import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AwsCredentials {
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
  final String identityId;

  const AwsCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.identityId,
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

    // debugPrint('[IoT] ── Credentials diagnostic ─────────────────');
    // debugPrint('[IoT] Identity ID   : $identityId');
    // debugPrint('[IoT] Is authenticated: ${userPoolTokens != null}');
    // debugPrint('[IoT] AccessKeyId   : ${creds.accessKeyId.substring(0, 8)}...');
    // debugPrint('[IoT] Has SessionToken: ${(creds.sessionToken ?? '').isNotEmpty}');
    // debugPrint('[IoT] ────────────────────────────────────────────');

    final awsCreds = AwsCredentials(
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken ?? '',
      identityId: identityId,
    );

    // if (!kIsWeb) await _diagnoseCallerIdentity(awsCreds);

    // await _diagnoseUserCreate(userPoolTokens?.idToken.raw);

    return awsCreds;
  }

  static Future<void> _diagnoseUserCreate(String? idToken) async {
    const url = 'https://4lov3vemle.execute-api.us-east-1.amazonaws.com/user/create';
    debugPrint('[API] ── POST /user/create ───────────────────────');

    if (idToken == null) {
      debugPrint('[API] SKIP — no ID token (user not authenticated)');
      debugPrint('[API] ────────────────────────────────────────────');
      return;
    }

    debugPrint('[API] Token  : ${idToken.substring(0, 20)}...${idToken.substring(idToken.length - 10)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      debugPrint('[API] Status : ${response.statusCode}');
      debugPrint('[API] Headers: ${response.headers}');
      debugPrint('[API] Body   : ${response.body}');
    } on http.ClientException catch (e) {
      debugPrint('[API] ClientException: ${e.message}');
    } catch (e, stack) {
      debugPrint('[API] Unexpected error: $e');
      debugPrint('[API] Stack: $stack');
    }

    debugPrint('[API] ────────────────────────────────────────────');
  }

  /// Calls STS GetCallerIdentity to reveal exactly which IAM role these
  /// credentials belong to (authenticated vs unauthenticated Cognito role).
  static Future<void> _diagnoseCallerIdentity(AwsCredentials creds) async {
    try {
      debugPrint('[IoT] ── STS GetCallerIdentity ──────────────────');
      final credentials = AWSCredentials(
        creds.accessKeyId,
        creds.secretAccessKey,
        creds.sessionToken.isEmpty ? null : creds.sessionToken,
      );
      final signer = AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(credentials),
      );
      final scope = AWSCredentialScope(
        region: 'us-east-1',
        service: const AWSService('sts'),
      );
      final body = utf8.encode('Action=GetCallerIdentity&Version=2011-06-15');
      final req = AWSHttpRequest(
        method: AWSHttpMethod.post,
        uri: Uri.parse('https://sts.amazonaws.com/'),
        headers: const {
          'content-type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      final signed = await signer.sign(req, credentialScope: scope);

      final client = HttpClient();
      final httpReq = await client.postUrl(signed.uri);
      for (final e in signed.headers.entries) {
        httpReq.headers.set(e.key, e.value);
      }
      httpReq.add(body);
      final resp = await httpReq.close();
      final respBody = await resp.transform(utf8.decoder).join();
      client.close(force: true);

      debugPrint('[IoT] STS status : ${resp.statusCode}');
      // Extract the Arn value from XML response
      final arnMatch = RegExp(r'<Arn>(.*?)</Arn>').firstMatch(respBody);
      final userIdMatch = RegExp(r'<UserId>(.*?)</UserId>').firstMatch(respBody);
      debugPrint('[IoT] Caller ARN  : ${arnMatch?.group(1) ?? 'not found'}');
      debugPrint('[IoT] Caller UserId: ${userIdMatch?.group(1) ?? 'not found'}');
      debugPrint('[IoT] Full response: $respBody');
      debugPrint('[IoT] ─────────────────────────────────────────────');
    } catch (e) {
      debugPrint('[IoT] STS diagnostic failed: $e');
    }
  }
}
