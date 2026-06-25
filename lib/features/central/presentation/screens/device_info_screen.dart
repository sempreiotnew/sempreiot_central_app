import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/device_info_provider.dart';
import '../../application/device_metadata_providers.dart';
import 'pin_change_screen.dart';

class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(deviceInfoProvider);
    final credAsync = ref.watch(deviceCredentialsProvider);
    final accessAsync = ref.watch(deviceAccessProvider);

    final info = infoAsync.valueOrNull ?? {};
    final cred = credAsync.valueOrNull ?? {};
    final access = accessAsync.valueOrNull ?? {};

    final isLoading =
        infoAsync.isLoading || credAsync.isLoading || accessAsync.isLoading;

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── IDENTIDADE ────────────────────────────────────────────
                const _SectionHeader('IDENTIDADE'),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _HashRow(hash: info['hash'] as String? ?? ''),
                    const _Divider(),
                    _ReadRow(
                      label: 'Firmware',
                      value: info['firmware_version'] as String? ?? '',
                      icon: Icons.memory_rounded,
                    ),
                    const _Divider(),
                    _ReadRow(
                      label: 'Hash anterior',
                      value: info['old_hash'] as String? ?? '',
                      icon: Icons.history_rounded,
                      mono: true,
                    ),
                    const _Divider(),
                    _ReadRow(
                      label: 'Criado em',
                      value: info['created_at'] as String? ?? '',
                      icon: Icons.calendar_today_rounded,
                    ),
                    const _Divider(),
                    _ReadRow(
                      label: 'Atualizado em',
                      value: info['updated_at'] as String? ?? '',
                      icon: Icons.update_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── ACESSO ────────────────────────────────────────────────
                const _SectionHeader('ACESSO'),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _ReadRow(
                      label: 'Sub ID',
                      value: access['subId'] as String? ?? '',
                      icon: Icons.fingerprint_rounded,
                      canCopy: true,
                      mono: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── CREDENCIAIS ───────────────────────────────────────────
                const _SectionHeader('CREDENCIAIS'),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'PIN, root e senha podem ser alterados após a inicialização.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                _InfoCard(
                  children: [
                    _PinRow(hasPin: (cred['pin'] as String? ?? '').isNotEmpty),
                    const _Divider(),
                    _EditableRow(
                      label: 'Root',
                      value: cred['root'] as String? ?? '',
                      icon: Icons.manage_accounts_rounded,
                      onSave: (val) => _saveCredential(
                        context, ref, cred, 'root', val,
                      ),
                    ),
                    const _Divider(),
                    _EditableRow(
                      label: 'Senha',
                      value: cred['password'] as String? ?? '',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      onSave: (val) => _saveCredential(
                        context, ref, cred, 'password', val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _saveCredential(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> current,
    String field,
    String value,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final updated = Map<String, dynamic>.from(current)..[field] = value;
    await db.setMeta('credentials', jsonEncode(updated));
    ref.invalidate(deviceCredentialsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$field atualizado com sucesso.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: context.borderColor.withValues(alpha: 0.5),
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
          // ── Inline QR preview (tappable to expand) ──────────────────
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
                          spreadRadius: 0,
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

          // ── Info + action chips ───────────────────────────────────────
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

// ── PIN row — navigates to the dedicated PIN change flow ──────────────────────

class _PinRow extends StatelessWidget {
  const _PinRow({required this.hasPin});
  final bool hasPin;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinChangeScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.pin_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPin ? '••••••' : 'Não definido',
                    style: TextStyle(
                      color: hasPin
                          ? context.textPrimary
                          : context.textSecondary.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.secondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Read-only row ─────────────────────────────────────────────────────────────

class _ReadRow extends StatelessWidget {
  const _ReadRow({
    required this.label,
    required this.value,
    required this.icon,
    this.canCopy = false,
    this.mono = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool canCopy;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: context.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? '—' : value,
                  style: TextStyle(
                    color: empty
                        ? context.textSecondary.withValues(alpha: 0.4)
                        : context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy && !empty)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 16,
                color: context.textSecondary.withValues(alpha: 0.5),
              ),
              tooltip: 'Copiar',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copiado.'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: context.textSecondary.withValues(alpha: 0.25),
            ),
        ],
      ),
    );
  }
}

// ── Editable row — opens a bottom sheet to edit the value ────────────────────

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onSave,
    this.obscure = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Future<void> Function(String) onSave;
  final bool obscure;

  void _edit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditSheet(
        label: label,
        currentValue: value,
        obscure: obscure,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;

    return InkWell(
      onTap: () => _edit(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empty
                        ? 'Não definido'
                        : (obscure ? '•' * value.length.clamp(0, 8) : value),
                    style: TextStyle(
                      color: empty
                          ? context.textSecondary.withValues(alpha: 0.4)
                          : context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: AppColors.secondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit bottom sheet ─────────────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  const _EditSheet({
    required this.label,
    required this.currentValue,
    required this.onSave,
    this.obscure = false,
  });

  final String label;
  final String currentValue;
  final Future<void> Function(String) onSave;
  final bool obscure;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = _ctrl.text.trim();
    if (val == widget.currentValue) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(val);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Editar ${widget.label}',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              obscureText: widget.obscure && !_showText,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: InputBorder.none,
                counterText: '',
                suffixIcon: widget.obscure
                    ? IconButton(
                        icon: Icon(
                          _showText
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: context.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _showText = !_showText),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: context.borderColor,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
