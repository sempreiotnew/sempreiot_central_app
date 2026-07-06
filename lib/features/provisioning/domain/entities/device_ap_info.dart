/// Response of GET /info on the device's SoftAP (192.168.4.1).
class DeviceApInfo {
  final String deviceId;
  final String model;
  final String firmwareVersion;
  final String provisionState;

  const DeviceApInfo({
    required this.deviceId,
    required this.model,
    required this.firmwareVersion,
    required this.provisionState,
  });

  factory DeviceApInfo.fromMap(Map<String, dynamic> map) => DeviceApInfo(
        deviceId: map['deviceId'] as String? ?? '',
        model: map['model'] as String? ?? '',
        firmwareVersion: map['firmwareVersion'] as String? ?? '',
        provisionState: map['provisionState'] as String? ?? 'idle',
      );
}

/// Response of GET /status while the device joins the mesh.
/// state: idle | identified | stored | connecting | connected | failed
class DeviceApStatus {
  final String state;
  final String? detail;

  const DeviceApStatus({required this.state, this.detail});

  factory DeviceApStatus.fromMap(Map<String, dynamic> map) => DeviceApStatus(
        state: map['state'] as String? ?? 'idle',
        detail: map['detail'] as String?,
      );
}
