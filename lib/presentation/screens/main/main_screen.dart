import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../features/iot/application/iot_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iotConnectionProvider.notifier).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Log IoT state changes to console only — never surface raw errors on screen.
    ref.listen(iotConnectionProvider, (_, next) {
      next.whenOrNull(
        error: (e, st) => debugPrint('[IoT] connection error: $e\n$st'),
      );
    });

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
