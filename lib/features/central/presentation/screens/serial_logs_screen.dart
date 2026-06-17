import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/serial_logs_provider.dart';
import '../../application/serial_provider.dart';

class SerialLogsScreen extends ConsumerStatefulWidget {
  const SerialLogsScreen({super.key});

  @override
  ConsumerState<SerialLogsScreen> createState() => _SerialLogsScreenState();
}

enum _ViewMode { hex, text }

class _SerialLogsScreenState extends ConsumerState<SerialLogsScreen> {
  final ScrollController _scroll = ScrollController();
  final Set<int> _expandedIds = {};
  _ViewMode _viewMode = _ViewMode.hex;
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
    if (_autoScroll != atBottom) {
      setState(() => _autoScroll = atBottom);
    }
  }

  void _toggleExpand(int id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _clear() {
    ref.read(appDatabaseProvider).deleteAllPackets();
    setState(() => _expandedIds.clear());
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

  void _copyAll(List<SerialPacket> entries) {
    if (entries.isEmpty) return;
    final text = entries
        .map((e) => '[${_timeLabel(e.receivedAt)}] ${e.deviceId} ${e.hexPreview}')
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

    // Auto-scroll to bottom whenever a new packet arrives
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
            viewMode: _viewMode,
            autoScroll: _autoScroll,
            onToggleView: () => setState(() {
              _viewMode =
                  _viewMode == _ViewMode.hex ? _ViewMode.text : _ViewMode.hex;
            }),
            onClear: entries.isEmpty ? null : _clear,
            onCopy: entries.isEmpty ? null : () => _copyAll(entries),
          ),
          Expanded(
            child: entries.isEmpty
                ? _EmptyState(status: status, isConnected: isConnected)
                : Stack(
                    children: [
                      _LogList(
                        entries: entries,
                        scroll: _scroll,
                        expandedIds: _expandedIds,
                        onToggle: _toggleExpand,
                        viewMode: _viewMode,
                      ),
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
            viewMode: _viewMode,
            autoScroll: _autoScroll,
            onToggleView: () {},
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

String _timeLabel(DateTime t) {
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(t.hour)}:${p(t.minute)}:${p(t.second)}'
      '.${t.millisecond.toString().padLeft(3, '0')}';
}

// ── Toolbar ──────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.entryCount,
    required this.status,
    required this.viewMode,
    required this.autoScroll,
    required this.onToggleView,
    required this.onClear,
    required this.onCopy,
  });

  final int entryCount;
  final SerialStatus status;
  final _ViewMode viewMode;
  final bool autoScroll;
  final VoidCallback onToggleView;
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
                  ? [BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 4)]
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
          _BarButton(
            icon: viewMode == _ViewMode.hex
                ? Icons.text_fields_rounded
                : Icons.data_array_rounded,
            tooltip: viewMode == _ViewMode.hex
                ? 'Mostrar como texto'
                : 'Mostrar como hex',
            onTap: onToggleView,
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            _BarButton(
              icon: Icons.copy_rounded,
              tooltip: 'Copiar tudo',
              onTap: onCopy!,
            ),
          ],
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
            child: Icon(icon, size: 17, color: color ?? context.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Log list ─────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({
    required this.entries,
    required this.scroll,
    required this.expandedIds,
    required this.onToggle,
    required this.viewMode,
  });

  final List<SerialPacket> entries;
  final ScrollController scroll;
  final Set<int> expandedIds;
  final void Function(int id) onToggle;
  final _ViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) => _LogRow(
        packet: entries[i],
        isExpanded: expandedIds.contains(entries[i].id),
        onToggle: () => onToggle(entries[i].id),
        viewMode: viewMode,
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.packet,
    required this.isExpanded,
    required this.onToggle,
    required this.viewMode,
  });

  final SerialPacket packet;
  final bool isExpanded;
  final VoidCallback onToggle;
  final _ViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${_timeLabel(packet.receivedAt)}]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.textSecondary.withValues(alpha: 0.5),
                    height: 1.6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${packet.byteLength}B',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.textSecondary.withValues(alpha: 0.4),
                    height: 1.6,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    packet.hexPreview,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.success.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: context.textSecondary.withValues(alpha: 0.4),
                ),
              ],
            ),
            if (isExpanded)
              _PacketDump(
                bytes: packet.rawBytes,
                deviceId: packet.deviceId,
                viewMode: viewMode,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Packet dump (shown on expand) ────────────────────────────────────────────

class _PacketDump extends StatelessWidget {
  const _PacketDump({
    required this.bytes,
    required this.deviceId,
    required this.viewMode,
  });

  final Uint8List bytes;
  final String deviceId;
  final _ViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    final content =
        viewMode == _ViewMode.hex ? _hexDump(bytes) : _toReadableText(bytes);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'device: $deviceId  |  ${bytes.length} bytes  |  '
            '${viewMode == _ViewMode.hex ? 'HEX' : 'TEXT'}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: context.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: context.textPrimary.withValues(alpha: 0.85),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

/// Parses the known 11-byte ESP32 test packet:
///   [0]     header  (0=OK, 1=FAIL, 2=ALARM)
///   [1..6]  MAC address (6 bytes)
///   [7..10] Chip ID (uint32, big-endian)
String _toReadableText(Uint8List bytes) {
  if (bytes.length < 11) {
    return '⚠ Packet too short (${bytes.length} bytes, expected 11)\n\n'
        '${_hexDump(bytes)}';
  }

  final header = switch (bytes[0]) {
    0 => '✅ OK',
    1 => '❌ FAIL',
    2 => '🔥 ALARM',
    _ => '? UNKNOWN (0x${bytes[0].toRadixString(16).padLeft(2, '0')})',
  };

  final mac = bytes
      .sublist(1, 7)
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');

  final chipId = (bytes[7] << 24) | (bytes[8] << 16) | (bytes[9] << 8) | bytes[10];
  final chipIdHex = chipId.toRadixString(16).toUpperCase().padLeft(8, '0');

  return 'Status  : $header\n'
      'MAC     : $mac\n'
      'Chip ID : 0x$chipIdHex';
}

String _hexDump(Uint8List bytes) {
  final buf = StringBuffer();
  for (var i = 0; i < bytes.length; i += 16) {
    final end = (i + 16 < bytes.length) ? i + 16 : bytes.length;
    final row = bytes.sublist(i, end);
    final hex = row.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final ascii =
        row.map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.').join();
    buf.writeln(
      '${i.toRadixString(16).padLeft(6, '0')}  ${hex.padRight(47)}  $ascii',
    );
  }
  return buf.toString().trimRight();
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
              border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
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
