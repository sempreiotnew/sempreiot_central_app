import 'dart:convert';
import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:flutter/foundation.dart';

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
  Future<AwsCredentials> fetch() async {
    final session =
        await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

    final identityId = session.identityIdResult.value;
    final userPoolTokens = session.userPoolTokensResult.valueOrNull;
    final creds = session.credentialsResult.value;

    debugPrint('[IoT] ── Credentials diagnostic ─────────────────');
    debugPrint('[IoT] Identity ID   : $identityId');
    debugPrint('[IoT] Is authenticated: ${userPoolTokens != null}');
    debugPrint('[IoT] AccessKeyId   : ${creds.accessKeyId.substring(0, 8)}...');
    debugPrint('[IoT] Has SessionToken: ${(creds.sessionToken ?? '').isNotEmpty}');
    debugPrint('[IoT] ────────────────────────────────────────────');

    final awsCreds = AwsCredentials(
      accessKeyId: creds.accessKeyId,
      secretAccessKey: creds.secretAccessKey,
      sessionToken: creds.sessionToken ?? '',
      identityId: identityId,
    );

    await _diagnoseCallerIdentity(awsCreds);

    return awsCreds;
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
