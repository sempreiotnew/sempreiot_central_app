import 'package:flutter/material.dart';

enum MainTab {
  principal,
  devices,
  network,
  social;

  String get label => switch (this) {
        MainTab.principal => 'Principal',
        MainTab.devices => 'Dispositivos',
        MainTab.network => 'Rede',
        MainTab.social => 'Social',
      };

  IconData get icon => switch (this) {
        MainTab.principal => Icons.home_rounded,
        MainTab.devices => Icons.devices_rounded,
        MainTab.network => Icons.hub_rounded,
        MainTab.social => Icons.group_rounded,
      };
}
