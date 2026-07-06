import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/provisioning_wizard_provider.dart';

/// Step 6 (in flight) — provision sent, waiting for the mesh-join verdict.
class ProvisioningProgressStep extends ConsumerWidget {
  const ProvisioningProgressStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkReady =
        ref.watch(provisioningWizardProvider).networkReady;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PulsingMeshIcon(),
          const SizedBox(height: 28),
          Text(
            networkReady
                ? 'Conectando à rede mesh...'
                : 'Salvando configuração...',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              networkReady
                  ? 'Isso pode levar até um minuto. Se o seu aparelho '
                      'desconectar da rede do dispositivo, é normal.'
                  : 'Enviando os dados para o dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMeshIcon extends StatefulWidget {
  const _PulsingMeshIcon();

  @override
  State<_PulsingMeshIcon> createState() => _PulsingMeshIconState();
}

class _PulsingMeshIconState extends State<_PulsingMeshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.06 + 0.10 * t),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3 + 0.4 * t),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.hub_rounded,
            size: 40,
            color: AppColors.secondary.withValues(alpha: 0.6 + 0.4 * t),
          ),
        );
      },
    );
  }
}
