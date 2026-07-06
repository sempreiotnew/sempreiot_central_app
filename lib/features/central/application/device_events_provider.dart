import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// Filters applied to the Eventos feed. Severities: 0 ok · 1 trouble ·
/// 2 alert · 3 alarm. Empty severity set = show everything.
class DeviceEventsFilter {
  const DeviceEventsFilter({this.severities = const {}, this.deviceMac});

  final Set<int> severities;
  final String? deviceMac;

  bool get isActive => severities.isNotEmpty || deviceMac != null;

  DeviceEventsFilter copyWith({Set<int>? severities, String? Function()? deviceMac}) {
    return DeviceEventsFilter(
      severities: severities ?? this.severities,
      deviceMac: deviceMac != null ? deviceMac() : this.deviceMac,
    );
  }
}

class DeviceEventsFilterNotifier extends Notifier<DeviceEventsFilter> {
  @override
  DeviceEventsFilter build() => const DeviceEventsFilter();

  void toggleSeverity(int severity) {
    final next = Set<int>.from(state.severities);
    next.contains(severity) ? next.remove(severity) : next.add(severity);
    state = state.copyWith(severities: next);
  }

  void setDevice(String? mac) => state = state.copyWith(deviceMac: () => mac);

  void clear() => state = const DeviceEventsFilter();
}

final deviceEventsFilterProvider =
    NotifierProvider<DeviceEventsFilterNotifier, DeviceEventsFilter>(
        DeviceEventsFilterNotifier.new);

/// Live feed of the latest 300 events matching the current filter,
/// newest first.
final deviceEventsProvider = StreamProvider<List<DeviceEvent>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(deviceEventsFilterProvider);

  final query = db.select(db.deviceEvents)
    ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])
    ..limit(300);
  if (filter.severities.isNotEmpty) {
    query.where((t) => t.severity.isIn(filter.severities));
  }
  if (filter.deviceMac != null) {
    query.where((t) => t.deviceMac.equals(filter.deviceMac!));
  }
  return query.watch();
});

/// Distinct devices seen in the feed — for the device filter chips.
final eventDevicesProvider = StreamProvider<List<MeshDevice>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.meshDevices)
        ..orderBy([(t) => OrderingTerm.asc(t.mac)]))
      .watch();
});

/// Devices whose alarm latch is set (SAFR v3 §7.1.4 — UL 864/NFPA 72):
/// an accepted ALARM latches and only the operator RESET clears it. A
/// RESTORE from the device does NOT — that is the compliance point.
final latchedAlarmsProvider = StreamProvider<List<MeshDevice>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.meshDevices)
        ..where((t) => t.alarmLatched.equals(1))
        ..orderBy([(t) => OrderingTerm.asc(t.alarmLatchedAt)]))
      .watch();
});

/// True while any alarm latch is set — drives the alarm banner and the
/// rearm control at the top of the Eventos screen.
final activeAlarmProvider = Provider<bool>((ref) {
  final latched = ref.watch(latchedAlarmsProvider).valueOrNull;
  return latched != null && latched.isNotEmpty;
});
