import 'dart:convert';

/// Credentials printed on the device's QR label.
/// Format: {"deviceId":"...","signature":"..."}
class DeviceQrPayload {
  final String deviceId;
  final String signature;

  const DeviceQrPayload({required this.deviceId, required this.signature});

  /// Null on anything that isn't a valid device QR (e.g. a central's subId).
  static DeviceQrPayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic>) return null;
      final id = decoded['deviceId'] as String?;
      final sig = decoded['signature'] as String?;
      if (id == null || id.isEmpty || sig == null || sig.isEmpty) return null;
      return DeviceQrPayload(deviceId: id, signature: sig);
    } on FormatException {
      return null;
    }
  }
}
