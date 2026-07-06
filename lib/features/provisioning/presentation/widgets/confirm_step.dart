import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/provisioning_wizard_provider.dart';
import 'wizard_buttons.dart';

/// Step 5 — summary + "the central's network is already up" checkbox.
class ConfirmStep extends ConsumerWidget {
  const ConfirmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provisioningWizardProvider);
    final notifier = ref.read(provisioningWizardProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Confirme a configuração',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _SummaryCard(
            rows: [
              (
                Icons.memory_rounded,
                'Dispositivo',
                state.deviceInfo?.deviceId ??
                    state.credentials?.deviceId ??
                    '—',
              ),
              if (state.deviceInfo != null)
                (Icons.tag_rounded, 'Modelo', state.deviceInfo!.model),
              (
                Icons.sensors_rounded,
                'Central',
                state.centralName?.isNotEmpty == true
                    ? '${state.centralName} (${state.centralId})'
                    : state.centralId ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _NetworkReadyToggle(
            value: state.networkReady,
            onChanged: notifier.setNetworkReady,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.networkReady
                ? Text(
                    'O dispositivo tentará se conectar à rede mesh agora.',
                    key: const ValueKey('now'),
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12),
                  )
                : Text(
                    'A configuração será salva no dispositivo e ele se '
                    'conectará automaticamente quando a rede da central '
                    'estiver disponível.',
                    key: const ValueKey('later'),
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 24),
          WizardPrimaryButton(
            label: 'Configurar Dispositivo',
            icon: Icons.settings_input_antenna_rounded,
            onTap: notifier.submitProvision,
          ),
          const SizedBox(height: 12),
          WizardSecondaryButton(
            label: 'Voltar',
            onTap: notifier.backToSelectCentral,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: context.borderColor, height: 1),
              ),
            Row(
              children: [
                Icon(rows[i].$1, size: 18, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  rows[i].$2,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    rows[i].$3,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NetworkReadyToggle extends StatelessWidget {
  const _NetworkReadyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppColors.secondary.withValues(alpha: 0.06)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppColors.secondary.withValues(alpha: 0.4)
              : context.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A central já está ligada com a rede mesh ativa',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
