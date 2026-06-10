import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

enum MainTab {
  principal,
  central,
  centrais,
  devices,
  social;

  static List<MainTab> get tabs => AppConfig.isCentral
      ? [principal, central, devices, social]
      : [principal, centrais, social];

  String get label => switch (this) {
        MainTab.principal => 'Principal',
        MainTab.central => 'Central',
        MainTab.centrais => 'Centrais',
        MainTab.devices => 'Dispositivos',
        MainTab.social => 'Social',
      };

  IconData get icon => switch (this) {
        MainTab.principal => Icons.home_rounded,
        MainTab.central => Icons.sensors_rounded,
        MainTab.centrais => Icons.hub_rounded,
        MainTab.devices => Icons.devices_rounded,
        MainTab.social => Icons.group_rounded,
      };
}
