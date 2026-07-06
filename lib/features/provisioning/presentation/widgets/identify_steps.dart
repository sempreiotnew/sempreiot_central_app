import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/provisioning_wizard_provider.dart';
import 'wizard_buttons.dart';

/// Step 3a — device reached, verifying deviceId + signature (brief).
class IdentifyingStep extends ConsumerWidget {
  const IdentifyingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(provisioningWizardProvider).deviceInfo;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Dispositivo encontrado!',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verificando identidade...',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          if (info != null) ...[
            const SizedBox(height: 24),
            Text(
              '${info.model} · ${info.deviceId}',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Step 3b — device rejected the credentials.
class IdentifyFailedStep extends ConsumerWidget {
  const IdentifyFailedStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(provisioningWizardProvider).error;
    final notifier = ref.read(provisioningWizardProvider.notifier);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Credenciais rejeitadas',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ??
                  'O dispositivo não reconheceu o ID e a assinatura informados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            WizardPrimaryButton(
              label: 'Escanear novamente',
              icon: Icons.qr_code_scanner_rounded,
              onTap: notifier.backToScan,
            ),
            const SizedBox(height: 12),
            WizardSecondaryButton(
              label: 'Tentar com os mesmos dados',
              onTap: notifier.retryIdentify,
            ),
          ],
        ),
      ),
    );
  }
}
