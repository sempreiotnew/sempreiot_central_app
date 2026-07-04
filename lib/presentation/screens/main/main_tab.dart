import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

enum MainTab {
  principal,
  central,
  centrais,
  devices,
  social,
  logs;

  static List<MainTab> get tabs => AppConfig.isCentral
      ? [principal, central, devices, logs, social]
      : [principal, centrais, social];

  /// USER mode drilling into a specific central: the reduced set of tabs
  /// a viewer can navigate inside that central.
  static List<MainTab> get centralDetailTabs => [principal, devices, central];

  String get label => switch (this) {
        MainTab.principal => 'Principal',
        MainTab.central => 'Central',
        MainTab.centrais => 'Centrais',
        MainTab.devices => 'Dispositivos',
        MainTab.social => 'Social',
        MainTab.logs => 'Logs',
      };

  IconData get icon => switch (this) {
        MainTab.principal => Icons.home_rounded,
        MainTab.central => Icons.sensors_rounded,
        MainTab.centrais => Icons.hub_rounded,
        MainTab.devices => Icons.devices_rounded,
        MainTab.social => Icons.group_rounded,
        MainTab.logs => Icons.receipt_long_rounded,
      };
}
