import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/device_info_provider.dart';
import '../widgets/device_detail_widgets.dart';

class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(deviceInfoProvider);

    final info = infoAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Informações',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: context.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: infoAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                const InfoSectionHeader('IDENTIDADE'),
                const SizedBox(height: 10),
                InfoCard(
                  children: [
                    InfoReadRow(
                      label: 'Nome',
                      value: info['name'] as String? ?? '',
                      icon: Icons.label_rounded,
                    ),
                    const InfoRowDivider(),
                    _HashRow(hash: info['hash'] as String? ?? ''),
                    const InfoRowDivider(),
                    InfoReadRow(
                      label: 'Firmware',
                      value: info['firmware_version'] as String? ?? '',
                      icon: Icons.memory_rounded,
                    ),
                    const InfoRowDivider(),
                    InfoReadRow(
                      label: 'Hash anterior',
                      value: info['old_hash'] as String? ?? '',
                      icon: Icons.history_rounded,
                      mono: true,
                    ),
                    const InfoRowDivider(),
                    InfoReadRow(
                      label: 'Criado em',
                      value: info['created_at'] as String? ?? '',
                      icon: Icons.calendar_today_rounded,
                    ),
                    const InfoRowDivider(),
                    InfoReadRow(
                      label: 'Atualizado em',
                      value: info['updated_at'] as String? ?? '',
                      icon: Icons.update_rounded,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ── Hash row — inline QR preview + copy / expand actions ─────────────────────

class _HashRow extends StatelessWidget {
  const _HashRow({required this.hash});
  final String hash;

  static const _qrDark = Color(0xFF111827);

  void _copyHash(BuildContext context) {
    Clipboard.setData(ClipboardData(text: hash));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hash copiado.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hash ID',
                style: TextStyle(
                  color: _qrDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: hash.isEmpty ? 'sem-hash' : hash,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _qrDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _qrDark,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                hash.isEmpty ? '—' : hash,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHash = hash.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasHash ? () => _showQr(context) : null,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasHash
                      ? AppColors.secondary.withValues(alpha: 0.3)
                      : context.borderColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
                boxShadow: hasHash
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: hasHash
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: QrImageView(
                        data: hash,
                        version: QrVersions.auto,
                        size: 76,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.secondary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.qr_code_2_rounded,
                      size: 36,
                      color: context.textSecondary.withValues(alpha: 0.2),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hash ID',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasHash
                      ? '${hash.substring(0, hash.length.clamp(0, 14))}…'
                      : '—',
                  style: TextStyle(
                    color: hasHash
                        ? AppColors.secondary
                        : context.textSecondary.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasHash) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.copy_rounded,
                        label: 'Copiar',
                        onTap: () => _copyHash(context),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.open_in_full_rounded,
                        label: 'Ampliar',
                        onTap: () => _showQr(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.secondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
