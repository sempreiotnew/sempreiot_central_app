import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../features/auth/application/user_sync_provider.dart';
import '../../../features/iot/application/iot_provider.dart';
import '../splash/splash_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Latches true on the first successful MQTT connection so that later
  // reconnects don't flash back to the splash screen.
  bool _iotReady = false;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(userSyncProvider);
    final iotState = ref.watch(iotConnectionProvider);

    // Latch ready on first successful connect (field assignment in build is
    // safe here — it doesn't call setState so no extra rebuild is triggered;
    // the next rebuild from the provider change will read the updated value).
    if (iotState.valueOrNull == true) _iotReady = true;

    // Trigger MQTT connect once user sync succeeds.
    ref.listen(userSyncProvider, (_, next) {
      if (next is AsyncData) {
        ref.read(iotConnectionProvider.notifier).connect();
      }
      if (next is AsyncError) {
        debugPrint('[UserSync] failed — signing out: ${next.error}');
        ref.read(authNotifierProvider.notifier).signOut();
      }
    });

    ref.listen(iotConnectionProvider, (_, next) {
      next.whenOrNull(
        error: (e, st) => debugPrint('[IoT] connection error: $e\n$st'),
      );
    });

    if (syncState.isLoading || syncState.hasError || !_iotReady) {
      return const SplashScreen();
    }

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
