/// Steps of the device provisioning wizard, in flow order.
enum ProvisioningStep {
  /// QR scan or manual entry of deviceId + signature.
  scan,

  /// Instructions to join the device's SoftAP; /info polling runs underneath.
  connectWifi,

  /// Device reached — running POST /identify.
  identifying,

  /// Device rejected the credentials (signature mismatch).
  identifyFailed,

  /// Pick which central's mesh the device should join.
  selectCentral,

  /// Summary + "network already up" checkbox.
  confirm,

  /// POST /provision sent — polling /status for the outcome.
  provisioning,

  /// Device confirmed it joined the mesh.
  resultSuccess,

  /// Config stored for a future network (checkbox off) — treated as success.
  resultStored,

  /// Provision was ACKed but the device went silent (SoftAP channel switch
  /// kicked us off) — assume success, tell the user to confirm on the central.
  resultAssumed,

  /// Device reported it could not join the mesh.
  resultFailed,
}

extension ProvisioningStepX on ProvisioningStep {
  /// 0-based index of the visible wizard phase (for the progress header).
  int get phaseIndex => switch (this) {
        ProvisioningStep.scan => 0,
        ProvisioningStep.connectWifi ||
        ProvisioningStep.identifying ||
        ProvisioningStep.identifyFailed =>
          1,
        ProvisioningStep.selectCentral => 2,
        ProvisioningStep.confirm || ProvisioningStep.provisioning => 3,
        _ => 4,
      };

  bool get isResult =>
      this == ProvisioningStep.resultSuccess ||
      this == ProvisioningStep.resultStored ||
      this == ProvisioningStep.resultAssumed ||
      this == ProvisioningStep.resultFailed;
}
