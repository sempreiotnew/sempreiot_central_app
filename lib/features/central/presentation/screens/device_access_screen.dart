import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/device_metadata_providers.dart';
import '../widgets/device_detail_widgets.dart';
import 'pin_change_screen.dart';

class DeviceAccessScreen extends ConsumerWidget {
  const DeviceAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credAsync = ref.watch(deviceCredentialsProvider);
    final accessAsync = ref.watch(deviceAccessProvider);

    final cred = credAsync.valueOrNull ?? {};
    final access = accessAsync.valueOrNull ?? [];

    final isLoading = credAsync.isLoading || accessAsync.isLoading;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Acessos',
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
                // ── CREDENCIAIS ───────────────────────────────────────────
                const InfoSectionHeader('CREDENCIAIS'),
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
                InfoCard(
                  children: [
                    _PinRow(hasPin: (cred['pin'] as String? ?? '').isNotEmpty),
                    const InfoRowDivider(),
                    _EditableRow(
                      label: 'Root',
                      value: cred['root'] as String? ?? '',
                      icon: Icons.manage_accounts_rounded,
                      onSave: (val) => _saveCredential(
                        context, ref, cred, 'root', val,
                      ),
                    ),
                    const InfoRowDivider(),
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
                const SizedBox(height: 24),

                // ── ACESSO ────────────────────────────────────────────────
                const InfoSectionHeader('ACESSO'),
                const SizedBox(height: 10),
                ..._sortedAccess(access).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AccessUserCard(entry: e),
                  ),
                ),
                const SizedBox(height: 4),
                const _AddAccessButton(),
              ],
            ),
    );
  }

  static List<Map<String, dynamic>> _sortedAccess(
      List<Map<String, dynamic>> entries) {
    const priority = {'OWNER': 0, 'ADMIN': 1, 'OPERATOR': 2, 'VIEWER': 3};
    final sorted = List<Map<String, dynamic>>.from(entries);
    sorted.sort((a, b) {
      final pa = priority[a['role'] as String? ?? ''] ?? 99;
      final pb = priority[b['role'] as String? ?? ''] ?? 99;
      return pa.compareTo(pb);
    });
    return sorted;
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

// ── PIN row ───────────────────────────────────────────────────────────────────

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

// ── Editable row ──────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;

    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _EditSheet(
          label: label,
          currentValue: value,
          obscure: obscure,
          onSave: onSave,
        ),
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
                    side: BorderSide(color: context.borderColor, width: 0.8),
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

// ── Role helpers ──────────────────────────────────────────────────────────────

Color _roleColor(String role) {
  switch (role) {
    case 'OWNER':
      return const Color(0xFFF59E0B);
    case 'ADMIN':
      return const Color(0xFF3B82F6);
    case 'OPERATOR':
      return const Color(0xFF10B981);
    case 'VIEWER':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF6B7280);
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'OWNER':
      return 'Proprietário';
    case 'ADMIN':
      return 'Administrador';
    case 'OPERATOR':
      return 'Operador';
    case 'VIEWER':
      return 'Visualizador';
    default:
      return role.isNotEmpty ? role : 'Sem permissão';
  }
}

// ── Access user card ──────────────────────────────────────────────────────────

class _AccessUserCard extends StatelessWidget {
  const _AccessUserCard({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final subId = entry['subId'] as String? ?? '';
    final role = entry['role'] as String? ?? '';
    final pin = entry['pin'] as String? ?? '';
    final color = _roleColor(role);
    final label = _roleLabel(role);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (role.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subId.isEmpty ? '—' : subId,
                  style: TextStyle(
                    color: context.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.pin_rounded,
                      size: 11,
                      color: pin.isNotEmpty
                          ? context.textSecondary.withValues(alpha: 0.5)
                          : context.textSecondary.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pin.isNotEmpty
                          ? '•' * pin.length.clamp(0, 6)
                          : 'PIN não definido',
                      style: TextStyle(
                        color: pin.isNotEmpty
                            ? context.textSecondary.withValues(alpha: 0.6)
                            : context.textSecondary.withValues(alpha: 0.25),
                        fontSize: 11,
                        letterSpacing: pin.isNotEmpty ? 2.0 : 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (subId.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 16,
                color: context.textSecondary.withValues(alpha: 0.4),
              ),
              tooltip: 'Copiar Sub ID',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: subId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sub ID copiado.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Add access button ─────────────────────────────────────────────────────────

class _AddAccessButton extends StatelessWidget {
  const _AddAccessButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.04),
                AppColors.secondary.withValues(alpha: 0.09),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Adicionar acesso',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
