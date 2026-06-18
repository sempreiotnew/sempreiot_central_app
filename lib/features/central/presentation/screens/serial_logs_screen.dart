import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/serial_logs_provider.dart';
import '../../application/serial_provider.dart';
import '../../domain/safr_frame.dart';
import 'safr_detail_screen.dart';

class SerialLogsScreen extends ConsumerStatefulWidget {
  const SerialLogsScreen({super.key});

  @override
  ConsumerState<SerialLogsScreen> createState() => _SerialLogsScreenState();
}

class _SerialLogsScreenState extends ConsumerState<SerialLogsScreen> {
  final ScrollController _scroll = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 48;
    if (_autoScroll != atBottom) setState(() => _autoScroll = atBottom);
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _jumpToBottomAndResume() {
    setState(() => _autoScroll = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clear() {
    ref.read(appDatabaseProvider).deleteAllPackets();
  }

  void _copyAll(List<SerialPacket> entries) {
    if (entries.isEmpty) return;
    final text = entries
        .map((e) =>
            '[${safrTimeLabel(e.receivedAt)}] ${e.deviceId} ${e.hexPreview}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copiados'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(serialLogsProvider);
    final status = ref.watch(serialProvider);
    final isConnected = status == SerialStatus.connected;

    ref.listen(serialLogsProvider, (prev, next) {
      final prevLen = prev?.valueOrNull?.length ?? 0;
      final nextLen = next.valueOrNull?.length ?? 0;
      if (nextLen > prevLen) _scrollToBottom();
    });

    return logsAsync.when(
      data: (entries) => Column(
        children: [
          _ToolBar(
            entryCount: entries.length,
            status: status,
            autoScroll: _autoScroll,
            onClear: entries.isEmpty ? null : _clear,
            onCopy: entries.isEmpty ? null : () => _copyAll(entries),
          ),
          Expanded(
            child: entries.isEmpty
                ? _EmptyState(status: status, isConnected: isConnected)
                : Stack(
                    children: [
                      _LogList(entries: entries, scroll: _scroll),
                      if (!_autoScroll)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: _ScrollResumeButton(
                            onTap: _jumpToBottomAndResume,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      loading: () => Column(
        children: [
          _ToolBar(
            entryCount: 0,
            status: status,
            autoScroll: _autoScroll,
            onClear: null,
            onCopy: null,
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.entryCount,
    required this.status,
    required this.autoScroll,
    required this.onClear,
    required this.onCopy,
  });

  final int entryCount;
  final SerialStatus status;
  final bool autoScroll;
  final VoidCallback? onClear;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final (dotColor, statusText) = switch (status) {
      SerialStatus.connected => (AppColors.success, 'Conectado'),
      SerialStatus.connecting => (AppColors.warning, 'Conectando...'),
      SerialStatus.error => (AppColors.error, 'Erro'),
      SerialStatus.disconnected => (
          context.textSecondary.withValues(alpha: 0.4),
          'Desconectado',
        ),
    };

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: status == SerialStatus.connected
                  ? [
                      BoxShadow(
                          color: dotColor.withValues(alpha: 0.6),
                          blurRadius: 4)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'USB — $statusText',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          if (entryCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.borderColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$entryCount',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Icon(
            autoScroll
                ? Icons.vertical_align_bottom_rounded
                : Icons.pause_rounded,
            size: 13,
            color: autoScroll
                ? AppColors.success.withValues(alpha: 0.6)
                : AppColors.warning.withValues(alpha: 0.7),
          ),
          const Spacer(),
          if (onCopy != null) ...[
            _BarButton(
              icon: Icons.copy_rounded,
              tooltip: 'Copiar tudo',
              onTap: onCopy!,
            ),
            const SizedBox(width: 4),
          ],
          if (onClear != null)
            _BarButton(
              icon: Icons.delete_sweep_rounded,
              tooltip: 'Limpar',
              onTap: onClear!,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child:
                Icon(icon, size: 17, color: color ?? context.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Log list ──────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({required this.entries, required this.scroll});

  final List<SerialPacket> entries;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) => _LogRow(packet: entries[i]),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.packet});

  final SerialPacket packet;

  @override
  Widget build(BuildContext context) {
    final frame = parseSafrFrame(packet.rawBytes);
    final (evtColor, evtLabel) = safrEventStyle(frame.payload?.event);
    final isDecryptFail =
        frame.decryptionAttempted && !frame.decryptionSuccess;
    final badgeColor = isDecryptFail ? AppColors.error : evtColor;
    final badgeLabel = isDecryptFail ? 'DECRYPT ERR' : evtLabel;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SafrDetailScreen(packet: packet),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Timestamp
            Text(
              safrTimeLabel(packet.receivedAt),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: context.textSecondary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 8),
            // Event badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Summary text
            Expanded(
              child: Text(
                _rowSummary(frame, packet),
                style: TextStyle(
                  fontSize: 11,
                  color: isDecryptFail
                      ? AppColors.error.withValues(alpha: 0.7)
                      : context.textPrimary.withValues(alpha: 0.75),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: context.textSecondary.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

String _rowSummary(SafrFrame frame, SerialPacket packet) {
  if (!frame.validSof) return 'Frame inválido · ${packet.byteLength}B';
  if (frame.decryptionAttempted && !frame.decryptionSuccess) {
    return '${frame.srcMac} · falha na decriptografia';
  }
  final p = frame.payload;
  if (p == null) return '${frame.srcMac} · sem payload';

  final parts = <String>[frame.srcMac];
  if (p.tempTenths != null) parts.add(safrFmtTemp(p.tempTenths));
  if (p.smokeRaw != null) parts.add('Fumaça ${p.smokeRaw}');
  if (p.humidity != null) parts.add('${p.humidity}% UR');
  if (p.faultCode != null) parts.add('Falha: ${safrFaultCodeName(p.faultCode!)}');
  return parts.join(' · ');
}

// ── Scroll resume button ──────────────────────────────────────────────────────

class _ScrollResumeButton extends StatelessWidget {
  const _ScrollResumeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vertical_align_bottom_rounded,
              size: 14,
              color: AppColors.warning,
            ),
            SizedBox(width: 6),
            Text(
              'Retomar scroll',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status, required this.isConnected});

  final SerialStatus status;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, color) = switch (status) {
      SerialStatus.connected => (
          Icons.usb_rounded,
          'Aguardando dados...',
          'Conectado — nenhum dado recebido ainda.',
          AppColors.success,
        ),
      SerialStatus.connecting => (
          Icons.usb_rounded,
          'Conectando...',
          'Aguardando o dispositivo serial.',
          AppColors.warning,
        ),
      SerialStatus.error => (
          Icons.usb_off_rounded,
          'Erro de conexão',
          'Verifique o cabo e reconecte o dispositivo.',
          AppColors.error,
        ),
      SerialStatus.disconnected => (
          Icons.usb_off_rounded,
          'USB desconectado',
          'Conecte um dispositivo serial para ver os logs.',
          context.textSecondary.withValues(alpha: 0.4),
        ),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Icon(icon, size: 28, color: color.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
