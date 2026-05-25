import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iotConnectionProvider.notifier).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final iotState = ref.watch(iotConnectionProvider);

    // Latch ready on first successful connect (field assignment in build is
    // safe here — it doesn't call setState so no extra rebuild is triggered;
    // the next rebuild from the provider change will read the updated value).
    if (iotState.valueOrNull == true) _iotReady = true;

    ref.listen(iotConnectionProvider, (_, next) {
      next.whenOrNull(
        error: (e, st) => debugPrint('[IoT] connection error: $e\n$st'),
      );
    });

    if (!_iotReady) return const SplashScreen();

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
