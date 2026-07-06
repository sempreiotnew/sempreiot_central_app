import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../access/application/user_access_provider.dart';
import '../../../access/domain/entities/saved_central.dart';
import '../../application/provisioning_wizard_provider.dart';
import 'wizard_buttons.dart';

/// Step 4 — pick which central's mesh the device should join: one of the
/// user's accepted centrals, or a manually typed central ID.
class SelectCentralStep extends ConsumerStatefulWidget {
  const SelectCentralStep({super.key});

  @override
  ConsumerState<SelectCentralStep> createState() => _SelectCentralStepState();
}

class _SelectCentralStepState extends ConsumerState<SelectCentralStep> {
  final _manualCtrl = TextEditingController();
  String? _selectedSubId;

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  /// A picked central takes priority: the manual field is disabled until the
  /// card is deselected.
  bool get _manualBlocked => _selectedSubId != null;

  bool get _canContinue =>
      _selectedSubId != null || _manualCtrl.text.trim().isNotEmpty;

  void _continue(List<SavedCentral> accepted) {
    final manual = _manualCtrl.text.trim();
    if (_selectedSubId != null) {
      final matches =
          accepted.where((c) => c.subId == _selectedSubId).toList();
      final central = matches.isNotEmpty ? matches.first : null;
      ref.read(provisioningWizardProvider.notifier).selectCentral(
            centralId: _selectedSubId!,
            centralName: central?.name,
          );
    } else if (manual.isNotEmpty) {
      ref
          .read(provisioningWizardProvider.notifier)
          .selectCentral(centralId: manual);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accepted = ref
        .watch(savedCentralsProvider)
        .where((c) => c.status == 'ACCEPTED')
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Escolha a central',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O dispositivo se conectará à rede mesh desta central.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (accepted.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você ainda não tem centrais vinculadas. '
                      'Digite o ID da central abaixo.',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...accepted.map(
              (central) => _CentralCard(
                central: central,
                selected: central.subId == _selectedSubId,
                onTap: () => setState(() {
                  _selectedSubId =
                      _selectedSubId == central.subId ? null : central.subId;
                  if (_selectedSubId != null) _manualCtrl.clear();
                }),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'OU DIGITE O ID DA CENTRAL',
            style: TextStyle(
              color: context.textSecondary
                  .withValues(alpha: _manualBlocked ? 0.5 : 1),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _manualBlocked ? 0.45 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _manualBlocked
                      ? context.borderColor
                      : AppColors.secondary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _manualCtrl,
                enabled: !_manualBlocked,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: _manualBlocked
                      ? 'Desmarque a central para digitar'
                      : 'ID da central...',
                  hintStyle: TextStyle(
                    color: context.textSecondary.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _continue(accepted),
              ),
            ),
          ),
          const SizedBox(height: 24),
          WizardPrimaryButton(
            label: 'Continuar',
            onTap: _canContinue ? () => _continue(accepted) : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CentralCard extends StatelessWidget {
  const _CentralCard({
    required this.central,
    required this.selected,
    required this.onTap,
  });

  final SavedCentral central;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondary.withValues(alpha: 0.08)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.6)
              : context.borderColor,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        central.name.isNotEmpty ? central.name : 'Central',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        central.subId,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? AppColors.secondary
                      : context.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
