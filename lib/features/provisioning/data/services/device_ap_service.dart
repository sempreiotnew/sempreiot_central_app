import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/device_ap_info.dart';

/// HTTP client for the device's provisioning SoftAP.
///
/// A real device answers at http://192.168.4.1 (port 80). During development
/// the mocked-device-autoconnect Node server stands in — point the app at it
/// with --dart-define=DEVICE_AP_URL=http://<mac-lan-ip>:8080.
class DeviceApService {
  static const _base = String.fromEnvironment(
    'DEVICE_AP_URL',
    defaultValue: 'http://192.168.4.1',
  );

  /// Short timeout: the SoftAP either answers fast or isn't there.
  static const _timeout = Duration(seconds: 3);

  static Future<DeviceApInfo> fetchInfo() async {
    final res = await http.get(Uri.parse('$_base/info')).timeout(_timeout);
    if (res.statusCode != 200) {
      throw DeviceApException(res.statusCode, res.body);
    }
    return DeviceApInfo.fromMap(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> identify({
    required String deviceId,
    required String signature,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/identify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceId': deviceId, 'signature': signature}),
        )
        .timeout(_timeout);
    debugPrint('[DeviceAp] identify ← ${res.statusCode}: ${res.body}');

    if (res.statusCode == 403) throw const SignatureMismatchException();
    if (res.statusCode != 200) {
      throw DeviceApException(res.statusCode, res.body);
    }
  }

  static Future<void> provision({
    required String centralId,
    required bool networkReady,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/provision'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'centralId': centralId,
            'networkReady': networkReady,
          }),
        )
        .timeout(_timeout);
    debugPrint('[DeviceAp] provision ← ${res.statusCode}: ${res.body}');

    if (res.statusCode != 202 && res.statusCode != 200) {
      throw DeviceApException(res.statusCode, res.body);
    }
  }

  static Future<DeviceApStatus> fetchStatus() async {
    final res = await http.get(Uri.parse('$_base/status')).timeout(_timeout);
    if (res.statusCode != 200) {
      throw DeviceApException(res.statusCode, res.body);
    }
    return DeviceApStatus.fromMap(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}

class SignatureMismatchException implements Exception {
  const SignatureMismatchException();

  @override
  String toString() => 'SignatureMismatchException';
}

class DeviceApException implements Exception {
  const DeviceApException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'DeviceApException($statusCode): $body';
}
