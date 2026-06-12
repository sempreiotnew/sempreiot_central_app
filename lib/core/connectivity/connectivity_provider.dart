import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/iot/application/iot_provider.dart';

/// Layer 1: network interface check (WiFi / mobile / ethernet present).
/// Unchanged — all existing consumers still work.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

enum NetworkStatus {
  /// No network interface detected.
  offline,

  /// Network interface present but SempreIoT backend unreachable.
  limited,

  /// Fully connected — MQTT session is active.
  online,
}

/// Layer 2: derived status combining network interface + MQTT reachability.
///
/// - [NetworkStatus.offline]  → connectivity_plus reports no interface.
/// - [NetworkStatus.online]   → MQTT is connected (AsyncData(true)).
/// - [NetworkStatus.limited]  → interface exists but MQTT actively failed.
///
/// The MQTT repository and iot_provider are intentionally untouched.
/// This provider is a pure read-only observer of already-existing state.
final networkStatusProvider = Provider<NetworkStatus>((ref) {
  final connState = ref.watch(connectivityProvider);

  // While the initial connectivity check is still pending, stay optimistic.
  if (connState.isLoading) return NetworkStatus.online;

  final hasInterface = connState.valueOrNull ?? false;
  if (!hasInterface) return NetworkStatus.offline;

  final iotState = ref.watch(iotConnectionProvider);

  // MQTT session confirmed active.
  if (iotState.valueOrNull == true) return NetworkStatus.online;

  // Actively disconnected (ping timeout, unexpected drop) or failed attempt.
  if (iotState.hasError || iotState.valueOrNull == false) return NetworkStatus.limited;

  // isLoading → still connecting / reconnecting — stay optimistic.
  return NetworkStatus.online;
});
