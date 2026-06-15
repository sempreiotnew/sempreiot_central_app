import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/serial_provider.dart';

class SerialLogsScreen extends ConsumerStatefulWidget {
  const SerialLogsScreen({super.key});

  @override
  ConsumerState<SerialLogsScreen> createState() => _SerialLogsScreenState();
}

class _SerialLogsScreenState extends ConsumerState<SerialLogsScreen> {
  final List<_LogEntry> _entries = [];
  final ScrollController _scroll = ScrollController();
  static const _maxEntries = 1000;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _addData(Uint8List data) {
    final raw = String.fromCharCodes(data);
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    setState(() {
      for (final line in lines) {
        _entries.add(_LogEntry(DateTime.now(), line));
      }
      if (_entries.length > _maxEntries) {
        _entries.removeRange(0, _entries.length - _maxEntries);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _clear() => setState(() => _entries.clear());

  void _copyAll() {
    if (_entries.isEmpty) return;
    final text =
        _entries.map((e) => '[${e.timeLabel}] ${e.text}').join('\n');
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
    ref.listen(serialDataProvider, (_, next) {
      next.whenData(_addData);
    });

    final status = ref.watch(serialProvider);
    final isConnected = status == SerialStatus.connected;

    return Column(
      children: [
        _ToolBar(
          entryCount: _entries.length,
          status: status,
          onClear: _entries.isEmpty ? null : _clear,
          onCopy: _entries.isEmpty ? null : _copyAll,
        ),
        Expanded(
          child: _entries.isEmpty
              ? _EmptyState(status: status, isConnected: isConnected)
              : _LogList(entries: _entries, scroll: _scroll),
        ),
      ],
    );
  }
}

// ── Toolbar ──────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.entryCount,
    required this.status,
    required this.onClear,
    required this.onCopy,
  });

  final int entryCount;
  final SerialStatus status;
  final VoidCallback? onClear;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final (dotColor, statusText) = switch (status) {
      SerialStatus.connected    => (AppColors.success, 'Conectado'),
      SerialStatus.connecting   => (AppColors.warning, 'Conectando...'),
      SerialStatus.error        => (AppColors.error,   'Erro'),
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
                        blurRadius: 4,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const Spacer(),
          if (onCopy != null)
            _BarButton(
              icon: Icons.copy_rounded,
              tooltip: 'Copiar tudo',
              onTap: onCopy!,
            ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            _BarButton(
              icon: Icons.delete_sweep_rounded,
              tooltip: 'Limpar',
              onTap: onClear!,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
          ],
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
            child: Icon(
              icon,
              size: 17,
              color: color ?? context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Log list ─────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({required this.entries, required this.scroll});

  final List<_LogEntry> entries;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) => _LogLine(entry: entries[i]),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${entry.timeLabel}]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: context.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 0,
              height: 1.6,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.success.withValues(alpha: 0.9),
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
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
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 0.8,
              ),
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
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _LogEntry {
  const _LogEntry(this.time, this.text);

  final DateTime time;
  final String text;

  String get timeLabel =>
      '${_pad(time.hour)}:${_pad(time.minute)}:${_pad(time.second)}'
      '.${time.millisecond.toString().padLeft(3, '0')}';

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
