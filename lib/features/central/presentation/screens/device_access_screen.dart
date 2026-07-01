import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../../../access/application/central_access_provider.dart';
import '../../../access/domain/entities/access_level.dart';
import '../../../access/domain/entities/access_relation.dart';
import '../../../access/presentation/screens/my_qr_screen.dart';
import '../../application/device_metadata_providers.dart';
import '../widgets/device_detail_widgets.dart';
import 'pin_change_screen.dart';

class DeviceAccessScreen extends ConsumerWidget {
  const DeviceAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credAsync = ref.watch(deviceCredentialsProvider);
    final pending = ref.watch(centralPendingRequestsProvider);
    final granted = ref.watch(centralGrantedProvider);
    final blocked = ref.watch(centralBlockedProvider);
    final centralIdAsync = ref.watch(centralIdProvider);
    final centralId = centralIdAsync.valueOrNull ?? '';

    final cred = credAsync.valueOrNull ?? {};
    final isLoading = credAsync.isLoading;

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
        actions: [
          const _RefreshButton(),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Meu QR Code',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyQrScreen()),
            ),
          ),
        ],
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
          : RefreshIndicator(
              onRefresh: () => ref.read(centralAccessRelationsProvider.notifier).refresh(),
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── SOLICITAÇÕES PENDENTES ────────────────────────────────
                if (pending.isNotEmpty) ...[
                  _PendingSectionHeader(count: pending.length),
                  const SizedBox(height: 8),
                  ...pending.map(
                    (rel) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PendingRequestCard(
                        relation: rel,
                        centralId: centralId,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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

                // ── ACESSO CONCEDIDO ─────────────────────────────────────
                const InfoSectionHeader('ACESSO CONCEDIDO'),
                const SizedBox(height: 10),
                if (granted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Nenhum usuário com acesso concedido.',
                      style: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...granted.map(
                    (rel) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _GrantedUserCard(relation: rel, centralId: centralId),
                    ),
                  ),
                const SizedBox(height: 4),
                const _AddAccessButton(),

                // ── BLOQUEADOS ────────────────────────────────────────────
                if (blocked.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const InfoSectionHeader('BLOQUEADOS'),
                  const SizedBox(height: 10),
                  ...blocked.map(
                    (rel) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BlockedUserCard(relation: rel),
                    ),
                  ),
                ],
              ],
              ),
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

// ── PIN row ───────────────────────────────────────────────────────────────────

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton();

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref.read(centralAccessRelationsProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_refreshing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.refresh_rounded),
      tooltip: 'Atualizar',
      onPressed: _refresh,
    );
  }
}

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

// ── Granted user card ─────────────────────────────────────────────────────────

class _GrantedUserCard extends ConsumerWidget {
  const _GrantedUserCard({required this.relation, required this.centralId});
  final AccessRelation relation;
  final String centralId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = relation.level ?? AccessLevel.level1;

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
              color: level.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(level.icon, size: 20, color: level.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        level.label,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: level.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: level.color.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        level.shortLabel,
                        style: TextStyle(
                          color: level.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  relation.userSubId,
                  style: TextStyle(
                    color: context.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 16, color: context.textSecondary.withValues(alpha: 0.4)),
            tooltip: 'Copiar Sub ID',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: relation.userSubId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sub ID copiado.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.secondary),
            tooltip: 'Alterar nível',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _LevelChangeSheet(relation: relation, centralId: centralId),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.block_rounded, size: 18, color: AppColors.error),
            tooltip: 'Bloquear',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _confirmBlock(context, ref, relation, centralId),
          ),
        ],
      ),
    );
  }
}

// ── Blocked user card ─────────────────────────────────────────────────────────

class _BlockedUserCard extends ConsumerStatefulWidget {
  const _BlockedUserCard({required this.relation});
  final AccessRelation relation;

  @override
  ConsumerState<_BlockedUserCard> createState() => _BlockedUserCardState();
}

class _BlockedUserCardState extends ConsumerState<_BlockedUserCard> {
  bool _loading = false;

  Future<void> _unblock() async {
    setState(() => _loading = true);
    try {
      await ref.read(centralAccessRelationsProvider.notifier).unblock(relation: widget.relation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.block_rounded, size: 20, color: AppColors.error),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.relation.userSubId,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
            )
          else
            TextButton(
              onPressed: _unblock,
              child: const Text('Desbloquear', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

Future<void> _confirmBlock(
  BuildContext context,
  WidgetRef ref,
  AccessRelation relation,
  String centralId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.surfaceColor,
      title: Text('Bloquear usuário?', style: TextStyle(color: ctx.textPrimary)),
      content: Text(
        'O acesso será revogado imediatamente e futuras solicitações deste usuário serão ignoradas.',
        style: TextStyle(color: ctx.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: TextStyle(color: ctx.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Bloquear', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(centralAccessRelationsProvider.notifier).block(relation: relation, centralId: centralId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ── Level-change PIN sheet ──────────────────────────────────────────────────

class _LevelChangeSheet extends ConsumerStatefulWidget {
  const _LevelChangeSheet({required this.relation, required this.centralId});
  final AccessRelation relation;
  final String centralId;

  @override
  ConsumerState<_LevelChangeSheet> createState() => _LevelChangeSheetState();
}

class _LevelChangeSheetState extends ConsumerState<_LevelChangeSheet> {
  AccessLevel? _selected;
  final List<String> _digits = [];
  String? _error;
  bool _saving = false;

  void _selectLevel(AccessLevel level) {
    if (_saving) return;
    setState(() {
      _selected = level;
      _digits.clear();
      _error = null;
    });
  }

  void _onDigit(String d) {
    if (_selected == null || _digits.length >= 6 || _saving) return;
    setState(() {
      _digits.add(d);
      _error = null;
    });
    if (_digits.length == 6) _submit();
  }

  void _onDelete() {
    if (_digits.isEmpty || _saving) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _submit() async {
    final level = _selected!;
    final entered = _digits.join();

    String expectedPin;
    if (level == AccessLevel.master) {
      final db = ref.read(appDatabaseProvider);
      final raw = await db.getMeta('credentials');
      final map = raw != null && raw.isNotEmpty
          ? jsonDecode(raw) as Map<String, dynamic>
          : <String, dynamic>{};
      expectedPin = map['pin'] as String? ?? '';
      if (expectedPin.isEmpty) {
        setState(() {
          _error = 'PIN da central não configurado em Credenciais.';
          _digits.clear();
        });
        return;
      }
    } else {
      expectedPin = level.fixedPin!;
    }

    if (entered != expectedPin) {
      setState(() => _error = 'PIN incorreto.');
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _digits.clear());
      });
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(centralAccessRelationsProvider.notifier).changeLevel(
            relation: widget.relation,
            level: level,
            centralId: widget.centralId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Erro ao alterar nível.';
          _digits.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentLevel = widget.relation.level;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
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
              'Alterar nível de acesso',
              style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.relation.userSubId,
              style: TextStyle(color: context.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccessLevel.values.map((level) {
                final selected = _selected == level;
                final isCurrent = currentLevel == level;
                return ChoiceChip(
                  label: Text(level.shortLabel),
                  selected: selected,
                  onSelected: (_) => _selectLevel(level),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : level.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: level.color.withValues(alpha: 0.10),
                  selectedColor: level.color,
                  side: BorderSide(
                    color: isCurrent ? level.color : level.color.withValues(alpha: 0.3),
                    width: isCurrent ? 1.4 : 0.8,
                  ),
                  avatar: isCurrent && !selected
                      ? Icon(Icons.check_circle_rounded, size: 14, color: level.color)
                      : null,
                );
              }).toList(),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _selected == AccessLevel.master
                      ? 'Digite o PIN da central'
                      : 'Digite o PIN de ${_selected!.label}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: PinDots(filledCount: _digits.length, hasError: _error != null)),
              const SizedBox(height: 10),
              Center(
                child: AnimatedOpacity(
                  opacity: _error != null ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(_error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedOpacity(
                opacity: _saving ? 0.4 : 1,
                duration: const Duration(milliseconds: 200),
                child: PinPad(onDigit: _onDigit, onDelete: _onDelete),
              ),
            ],
          ],
        ),
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyQrScreen()),
        ),
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

// ── Pending section header ────────────────────────────────────────────────────

class _PendingSectionHeader extends StatelessWidget {
  const _PendingSectionHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SOLICITAÇÕES PENDENTES',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pending request card ──────────────────────────────────────────────────────

class _PendingRequestCard extends ConsumerStatefulWidget {
  const _PendingRequestCard({
    required this.relation,
    required this.centralId,
  });

  final AccessRelation relation;
  final String centralId;

  @override
  ConsumerState<_PendingRequestCard> createState() =>
      _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<_PendingRequestCard> {
  bool _loading = false;

  Future<void> _resolve(String decision) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(centralAccessRelationsProvider.notifier).resolve(
            relation: widget.relation,
            decision: decision,
            centralId: widget.centralId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(centralAccessRelationsProvider.notifier).block(
            relation: widget.relation,
            centralId: widget.centralId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.relation;
    final since = _timeSince(req.requestedAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.userSubId,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Pendente · $since',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              ),
            )
          else ...[
            _ActionButton(
              icon: Icons.check_rounded,
              color: AppColors.success,
              onTap: () => _resolve('ACCEPTED'),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              icon: Icons.close_rounded,
              color: AppColors.error,
              onTap: () => _resolve('REJECTED'),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              icon: Icons.block_rounded,
              color: context.textSecondary,
              onTap: _block,
            ),
          ],
        ],
      ),
    );
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
