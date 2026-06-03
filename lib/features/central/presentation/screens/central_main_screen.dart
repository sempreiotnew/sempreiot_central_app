import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/central_auth_provider.dart';

class CentralMainScreen extends ConsumerWidget {
  const CentralMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Central SempreIoT',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: isOnline ? const Color(0xFF52B788) : Colors.red.shade400,
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondaryDark),
            tooltip: 'Bloquear',
            onPressed: () => ref.read(centralAuthProvider.notifier).reset(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Tela principal da Central\n(em desenvolvimento)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
        ),
      ),
    );
  }
}
