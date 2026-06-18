import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../domain/safr_frame.dart';

class SafrDetailScreen extends StatefulWidget {
  const SafrDetailScreen({super.key, required this.packet});

  final SerialPacket packet;

  @override
  State<SafrDetailScreen> createState() => _SafrDetailScreenState();
}

class _SafrDetailScreenState extends State<SafrDetailScreen> {
  bool _showHex = false;

  @override
  Widget build(BuildContext context) {
    final frame = parseSafrFrame(widget.packet.rawBytes);
    final (evtColor, evtLabel) = safrEventStyle(frame.payload?.event);
    final isDecryptFail = frame.decryptionAttempted && !frame.decryptionSuccess;
    final titleColor = isDecryptFail ? AppColors.error : evtColor;
    final titleLabel = isDecryptFail ? 'DECRYPT ERR' : evtLabel;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textSecondaryDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: titleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: titleColor.withValues(alpha: 0.4), width: 0.7),
              ),
              child: Text(
                titleLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: titleColor,
                ),
              ),
            ),
            if (frame.validSof) ...[
              const SizedBox(width: 10),
              Text(
                'MSG #${frame.msgId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ],
        ),
        actions: [
          _EncBadge(frame: frame),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              _showHex ? Icons.analytics_outlined : Icons.data_array_rounded,
              size: 18,
            ),
            color: AppColors.textSecondaryDark,
            tooltip: _showHex ? 'Mostrar decodificado' : 'Mostrar hex bruto',
            onPressed: () => setState(() => _showHex = !_showHex),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppColors.textSecondaryDark,
            tooltip: 'Copiar',
            onPressed: () => _copy(context, frame),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _showHex
          ? _HexBody(bytes: widget.packet.rawBytes)
          : _DecodedBody(frame: frame, receivedAt: widget.packet.receivedAt),
    );
  }

  void _copy(BuildContext context, SafrFrame frame) {
    final buf = StringBuffer();
    buf.writeln(
        '[${safrTimeLabel(widget.packet.receivedAt)}] MSG #${frame.msgId}');
    final p = frame.payload;
    if (p != null) {
      buf.writeln('Event:    ${p.event.name.toUpperCase()}');
      buf.writeln('Device:   ${frame.srcMac}');
      buf.writeln('Time:     ${safrFmtTs(p.timestamp)}');
      if (p.tempTenths != null) buf.writeln('Temp:     ${safrFmtTemp(p.tempTenths)}');
      if (p.smokeRaw != null) buf.writeln('Smoke:    ${p.smokeRaw} ADU');
      if (p.humidity != null) buf.writeln('Humidity: ${p.humidity} %');
      if (p.faultCode != null) buf.writeln('Fault:    ${safrFaultCodeName(p.faultCode!)}');
      buf.writeln('RSSI:     ${p.rssiDbm} dBm');
    } else if (frame.decryptionAttempted && !frame.decryptionSuccess) {
      buf.writeln('Decryption failed — check PSK and USB connection');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Decoded body ──────────────────────────────────────────────────────────────

class _DecodedBody extends StatelessWidget {
  const _DecodedBody({required this.frame, required this.receivedAt});

  final SafrFrame frame;
  final DateTime receivedAt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (frame.parseError != null)
            _ErrorCard(message: frame.parseError!)
          else ...[
            if (frame.decryptionAttempted && !frame.decryptionSuccess)
              const _DecryptFailureCard(),
            if (frame.payload != null)
              _PayloadSections(frame: frame, receivedAt: receivedAt)
            else if (!frame.decryptionAttempted)
              const _ErrorCard(message: 'Frame sem payload decodificado'),
          ],
        ],
      ),
    );
  }
}

class _PayloadSections extends StatelessWidget {
  const _PayloadSections({required this.frame, required this.receivedAt});

  final SafrFrame frame;
  final DateTime receivedAt;

  @override
  Widget build(BuildContext context) {
    final p = frame.payload!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Device ─────────────────────────────────────────
        _Card(
          label: 'DISPOSITIVO',
          icon: Icons.memory_rounded,
          iconColor: AppColors.secondary,
          children: [
            _InfoRow(label: 'MAC', value: frame.srcMac),
            _InfoRow(label: 'Recebido', value: safrTimeLabel(receivedAt)),
            _InfoRow(label: 'Data/hora', value: safrFmtTs(p.timestamp)),
          ],
        ),

        const SizedBox(height: 12),

        // ── Event ───────────────────────────────────────────
        _EventCard(event: p.event),

        // ── Sensors ─────────────────────────────────────────
        if (p.smokeRaw != null) ...[
          const SizedBox(height: 12),
          _Card(
            label: 'SENSORES',
            icon: Icons.sensors_rounded,
            iconColor: AppColors.secondary,
            children: [
              _InfoRow(label: 'Temperatura', value: safrFmtTemp(p.tempTenths)),
              _InfoRow(label: 'Fumaça', value: '${p.smokeRaw} ADU'),
              _InfoRow(label: 'Umidade', value: '${p.humidity} %'),
            ],
          ),
        ],

        // ── Fault ───────────────────────────────────────────
        if (p.faultCode != null) ...[
          const SizedBox(height: 12),
          _FaultCard(payload: p),
        ],

        // ── Power ───────────────────────────────────────────
        const SizedBox(height: 12),
        _PowerCard(payload: p),

        // ── Signal / mesh ───────────────────────────────────
        const SizedBox(height: 12),
        _Card(
          label: 'REDE / MESH',
          icon: Icons.router_rounded,
          iconColor: AppColors.secondary,
          children: [
            _SignalRow(rssi: p.rssiDbm),
            if (p.childCount > 0)
              _InfoRow(
                label: 'Filhos',
                value: '${p.childCount}  →  ${p.children.join(', ')}',
              )
            else
              const _InfoRow(label: 'Papel', value: 'Nó folha (sem filhos)'),
          ],
        ),
      ],
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final SafrEvent event;

  @override
  Widget build(BuildContext context) {
    final (color, label) = safrEventStyle(event);
    final description = switch (event) {
      SafrEvent.ok => 'Sistema operando normalmente.',
      SafrEvent.alert => 'Atenção — condição de pré-alarme detectada.',
      SafrEvent.alarm => 'Alarme ativo — ação imediata necessária!',
      SafrEvent.trouble => 'Falha no sistema — verifique o dispositivo.',
      SafrEvent.unknown => 'Evento desconhecido.',
    };

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_eventIcon(event), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(SafrEvent e) => switch (e) {
        SafrEvent.ok => Icons.check_circle_outline_rounded,
        SafrEvent.alert => Icons.warning_amber_rounded,
        SafrEvent.alarm => Icons.local_fire_department_rounded,
        SafrEvent.trouble => Icons.error_outline_rounded,
        SafrEvent.unknown => Icons.help_outline_rounded,
      };
}

// ── Fault card ────────────────────────────────────────────────────────────────

class _FaultCard extends StatelessWidget {
  const _FaultCard({required this.payload});

  final SafrPayload payload;

  @override
  Widget build(BuildContext context) {
    final faults = <String>[
      if (payload.faultSmoke == true) 'Fumaça',
      if (payload.faultTemp == true) 'Temperatura',
      if (payload.faultBatt == true) 'Bateria',
    ];
    final label =
        faults.isEmpty ? safrFaultCodeName(payload.faultCode!) : faults.join(', ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.7),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.report_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FALHA DETECTADA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Power card ────────────────────────────────────────────────────────────────

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.payload});

  final SafrPayload payload;

  @override
  Widget build(BuildContext context) {
    final bits = [
      (
        'Rede elétrica',
        payload.pwrAcOk,
        payload.pwrAcOk ? AppColors.success : AppColors.error,
      ),
      (
        'Boost',
        payload.pwrBoost,
        payload.pwrBoost ? AppColors.warning : context.textSecondary.withValues(alpha: 0.3),
      ),
      (
        'Carregando',
        payload.pwrCharging,
        payload.pwrCharging ? AppColors.secondary : context.textSecondary.withValues(alpha: 0.3),
      ),
      (
        'Tamper',
        payload.pwrTamper,
        payload.pwrTamper ? AppColors.error : AppColors.success,
      ),
    ];

    return _Card(
      label: 'ENERGIA',
      icon: Icons.bolt_rounded,
      iconColor: AppColors.warning,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bits.map((b) {
            final (label, active, color) = b;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: color.withValues(alpha: 0.3), width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? color
                          : context.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Signal row ────────────────────────────────────────────────────────────────

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.rssi});

  final int rssi;

  @override
  Widget build(BuildContext context) {
    final color = rssi >= -60
        ? AppColors.success
        : rssi >= -80
            ? AppColors.warning
            : AppColors.error;
    final label = rssi >= -60
        ? 'Excelente'
        : rssi >= -70
            ? 'Bom'
            : rssi >= -80
                ? 'Regular'
                : 'Fraco';

    return Row(
      children: [
        Expanded(
          child: _InfoRow(
            label: 'Sinal (RSSI)',
            value: '$rssi dBm  ·  $label',
            valueColor: color,
          ),
        ),
      ],
    );
  }
}

// ── Decrypt failure card ──────────────────────────────────────────────────────

class _DecryptFailureCard extends StatelessWidget {
  const _DecryptFailureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open_rounded,
                  size: 15, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Falha na decriptografia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'O frame chegou com F_ENC ativo. O firmware só envia '
            'frames após criptografar com sucesso — portanto esta '
            'falha é no lado do app, não no firmware.',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• PSK diferente entre firmware e app\n'
            '• Frame corrompido durante transmissão USB\n'
            '• Diferença no CCM entre mbedTLS e PointyCastle',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hex body ──────────────────────────────────────────────────────────────────

class _HexBody extends StatelessWidget {
  const _HexBody({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bytes.length} bytes  ·  HEX DUMP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: context.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _hexDump(bytes),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: context.textPrimary.withValues(alpha: 0.85),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Enc badge widget ──────────────────────────────────────────────────────────

class _EncBadge extends StatelessWidget {
  const _EncBadge({required this.frame});

  final SafrFrame frame;

  @override
  Widget build(BuildContext context) {
    if (!frame.isEncrypted) {
      return _chip(context, 'PLAINTEXT', AppColors.warning);
    }
    if (!frame.decryptionAttempted) {
      return _chip(context, 'ENC', AppColors.warning);
    }
    return _chip(
      context,
      frame.decryptionSuccess ? 'ENC ✓' : 'ENC ✗',
      frame.decryptionSuccess ? AppColors.success : AppColors.error,
    );
  }
}

// ── Generic card section ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: context.borderColor.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(icon, size: 13, color: iconColor.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: iconColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? context.textPrimary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers (public so serial_logs_screen can use them) ────────────────

(Color, String) safrEventStyle(SafrEvent? event) => switch (event) {
      SafrEvent.ok => (AppColors.success, 'OK'),
      SafrEvent.alert => (AppColors.warning, 'ALERT'),
      SafrEvent.alarm => (AppColors.error, 'ALARM'),
      SafrEvent.trouble => (const Color(0xFFFF8C00), 'TROUBLE'),
      _ => (const Color(0xFF888888), 'UNKNOWN'),
    };

String safrTimeLabel(DateTime t) {
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(t.hour)}:${p(t.minute)}:${p(t.second)}'
      '.${t.millisecond.toString().padLeft(3, '0')}';
}

String safrFmtTs(DateTime ts) {
  String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
  return '${ts.year}-${p(ts.month)}-${p(ts.day)}'
      ' ${p(ts.hour)}:${p(ts.minute)}:${p(ts.second)} UTC';
}

String safrFmtTemp(int? tenths) {
  if (tenths == null) return '—';
  final whole = tenths ~/ 10;
  final frac = tenths.abs() % 10;
  return '$whole.$frac °C';
}

String safrFaultCodeName(int code) => switch (code) {
      0x01 => 'Fumaça',
      0x02 => 'Temperatura',
      0x03 => 'Bateria',
      _ => 'Desconhecido',
    };

Widget _chip(BuildContext context, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      ),
    ),
  );
}

String _hexDump(Uint8List bytes) {
  final buf = StringBuffer();
  for (var i = 0; i < bytes.length; i += 16) {
    final end = (i + 16 < bytes.length) ? i + 16 : bytes.length;
    final row = bytes.sublist(i, end);
    final hex = row.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final ascii = row
        .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
        .join();
    buf.writeln(
        '${i.toRadixString(16).padLeft(6, '0')}  ${hex.padRight(47)}  $ascii');
  }
  return buf.toString().trimRight();
}
