import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/device_events_provider.dart';
import '../../application/safr_downlink_provider.dart';
import '../../domain/safr/safr_v2_payloads.dart';
import 'safr_detail_screen.dart';

/// Eventos — the humanized fire-alarm feed. Every card answers three
/// questions at a glance: WHAT happened (big title + severity color),
/// WHERE (device chip) and WHEN (time + delivery double-check).
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(deviceEventsProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          children: [
            const _StatusStrip(),
            const _LatchedAlarmBanner(),
            const _FilterBar(),
            Expanded(
              child: events.when(
                data: (rows) => rows.isEmpty
                    ? const _EmptyState()
                    : _EventFeed(rows: rows),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Erro ao carregar eventos: $e',
                      style: TextStyle(color: context.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Severity presentation ────────────────────────────────────────────────────

class EventSeverityStyle {
  const EventSeverityStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

EventSeverityStyle severityStyle(int severity) => switch (severity) {
      3 => const EventSeverityStyle(
          'ALARME', AppColors.error, Icons.local_fire_department_rounded),
      2 => const EventSeverityStyle(
          'ALERTA', AppColors.warning, Icons.warning_amber_rounded),
      1 => const EventSeverityStyle(
          'FALHA', AppColors.trouble, Icons.build_circle_outlined),
      _ => const EventSeverityStyle(
          'NORMAL', AppColors.success, Icons.check_circle_outline_rounded),
    };

String eventTitle(DeviceEvent e) {
  if (e.errorKind != null) {
    return switch (e.errorKind) {
      'auth_failed' => 'Falha de autenticação',
      'crc_failed' => 'Quadro corrompido',
      _ => 'Quadro não reconhecido',
    };
  }
  final detail = eventDetail(e);
  if (detail['synthetic'] == true) {
    return switch (detail['kind']) {
      'device_missing' => 'Dispositivo sem comunicação',
      'device_restored' => 'Comunicação restabelecida',
      'command_unconfirmed' => 'Comando sem confirmação',
      _ => 'Evento do sistema',
    };
  }
  final code = SafrEventCode.fromWire(e.eventCode ?? 0);
  return switch (code) {
    SafrEventCode.smokeAlarm => 'Fumaça detectada',
    SafrEventCode.heatAlarm => 'Temperatura de alarme',
    SafrEventCode.smokeRising => 'Nível de fumaça subindo',
    SafrEventCode.manualTest => 'Teste manual acionado',
    SafrEventCode.tamper => 'Removido da base',
    SafrEventCode.battLow => 'Bateria baixa',
    SafrEventCode.battCritical => 'Bateria crítica',
    SafrEventCode.sensorFault => 'Falha no sensor',
    SafrEventCode.commFault => 'Falha de comunicação',
    SafrEventCode.acLost => 'Sem energia elétrica',
    SafrEventCode.restore => 'Condição normalizada',
    _ => switch (e.severity) {
        3 => 'Alarme',
        2 => 'Alerta',
        1 => 'Falha',
        _ => 'Situação normal',
      },
  };
}

/// Second line: what it means / what to do — the "understandable" part.
String eventSubtitle(DeviceEvent e) {
  if (e.errorKind != null) {
    return switch (e.errorKind) {
      'auth_failed' =>
        'Dados chegaram mas a chave (PSK) não confere com o firmware',
      'crc_failed' => 'Bytes alterados na transmissão — verifique o cabo',
      _ => 'Não foi possível decodificar este quadro',
    };
  }
  final detail = eventDetail(e);
  if (detail['synthetic'] == true) {
    return switch (detail['kind']) {
      'device_missing' => 'Sem resposta há mais de 3 intervalos de supervisão',
      'device_restored' => 'O dispositivo voltou a reportar normalmente',
      'command_unconfirmed' =>
        'O root não confirmou: ${detail['description'] ?? 'comando'}',
      _ => '',
    };
  }
  final code = SafrEventCode.fromWire(e.eventCode ?? 0);
  return switch (code) {
    SafrEventCode.smokeAlarm => 'Nível de fumaça acima do limite de alarme',
    SafrEventCode.smokeRising => 'Pré-alarme — acompanhando a tendência',
    SafrEventCode.heatAlarm => 'Calor acima do limite de alarme',
    SafrEventCode.tamper => 'Possível violação do equipamento',
    SafrEventCode.battLow => 'Programar troca da bateria',
    SafrEventCode.battCritical => 'Trocar a bateria imediatamente',
    SafrEventCode.sensorFault => 'Sensor precisa de manutenção',
    SafrEventCode.acLost => 'Operando na bateria de backup',
    SafrEventCode.restore => 'Situação anterior resolvida',
    SafrEventCode.manualTest => 'Botão de teste pressionado no dispositivo',
    _ => '',
  };
}

Map<String, dynamic> eventDetail(DeviceEvent e) {
  try {
    return jsonDecode(e.detailJson) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}

String relativeTime(DateTime utc) {
  final diff = DateTime.now().toUtc().difference(utc);
  if (diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  final local = utc.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String clockTime(DateTime utc) {
  final l = utc.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

String shortMac(String mac) =>
    mac.length >= 5 ? mac.substring(mac.length - 5) : mac;

// ── Status strip: live counts by severity ────────────────────────────────────

class _StatusStrip extends ConsumerWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(deviceEventsProvider).valueOrNull ?? const [];
    final alarmActive = ref.watch(activeAlarmProvider);

    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 24));
    var alarms = 0, alerts = 0, troubles = 0, ok = 0;
    for (final e in events) {
      if (e.receivedAt.isBefore(cutoff)) continue;
      switch (e.severity) {
        case 3:
          alarms++;
        case 2:
          alerts++;
        case 1:
          troubles++;
        default:
          ok++;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              style: severityStyle(3),
              count: alarms,
              highlight: alarmActive,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(style: severityStyle(2), count: alerts)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(style: severityStyle(1), count: troubles)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(style: severityStyle(0), count: ok)),
        ],
      ),
    );
  }
}

/// Latched-alarm banner (SAFR v3 §7.1.4 — UL 864/NFPA 72): alarms stay
/// retained here even after the device reports RESTORE. Only the operator's
/// "Rearmar" (RESET command, confirmed by the root) clears them.
class _LatchedAlarmBanner extends ConsumerStatefulWidget {
  const _LatchedAlarmBanner();

  @override
  ConsumerState<_LatchedAlarmBanner> createState() =>
      _LatchedAlarmBannerState();
}

class _LatchedAlarmBannerState extends ConsumerState<_LatchedAlarmBanner> {
  bool _resetting = false;

  Future<void> _rearm() async {
    setState(() => _resetting = true);
    // Broadcast RESET: the central clears latches only after the root ACKs.
    final ok = await ref
        .read(safrDownlinkProvider)
        .sendReset('FF:FF:FF:FF:FF:FF');
    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Sistema rearmado — alarmes retidos liberados'
          : 'Rearme SEM confirmação do root — alarmes continuam retidos'),
      backgroundColor: ok ? null : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final latched = ref.watch(latchedAlarmsProvider).valueOrNull ?? const [];
    if (latched.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latched.length == 1
                      ? 'ALARME RETIDO'
                      : '${latched.length} ALARMES RETIDOS',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${latched.map((d) => d.name ?? d.mac).join(', ')} — '
                  'retido até o rearme do operador (UL 864/NFPA 72)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _resetting ? null : _rearm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: _resetting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.restart_alt_rounded, size: 15),
            label: const Text('Rearmar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.style,
    required this.count,
    this.highlight = false,
  });

  final EventSeverityStyle style;
  final int count;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight
            ? style.color.withValues(alpha: 0.16)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? style.color
              : active
                  ? style.color.withValues(alpha: 0.35)
                  : context.borderColor.withValues(alpha: 0.6),
          width: highlight ? 1.4 : 0.6,
        ),
        boxShadow: highlight
            ? [BoxShadow(color: style.color.withValues(alpha: 0.25), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          Icon(style.icon,
              size: 16,
              color: active ? style.color : context.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: active ? style.color : context.textSecondary,
                    fontSize: 16,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  style.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filters ──────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deviceEventsFilterProvider);
    final notifier = ref.read(deviceEventsFilterProvider.notifier);
    final devices = ref.watch(eventDevicesProvider).valueOrNull ?? const [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          for (final severity in const [3, 2, 1, 0])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SeverityChip(
                style: severityStyle(severity),
                selected: filter.severities.contains(severity),
                onTap: () => notifier.toggleSeverity(severity),
              ),
            ),
          if (devices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _DeviceFilterChip(
                devices: devices,
                selected: filter.deviceMac,
                onSelected: notifier.setDevice,
              ),
            ),
          if (filter.isActive)
            TextButton.icon(
              onPressed: notifier.clear,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Limpar'),
              style: TextButton.styleFrom(
                foregroundColor: context.textSecondary,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final EventSeverityStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? style.color.withValues(alpha: 0.18)
          : context.surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? style.color.withValues(alpha: 0.7)
                  : context.borderColor,
              width: selected ? 1.2 : 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon,
                  size: 14,
                  color: selected ? style.color : context.textSecondary),
              const SizedBox(width: 6),
              Text(
                style.label,
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.4,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? style.color : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceFilterChip extends StatelessWidget {
  const _DeviceFilterChip({
    required this.devices,
    required this.selected,
    required this.onSelected,
  });

  final List<MeshDevice> devices;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    return PopupMenuButton<String?>(
      tooltip: 'Filtrar por dispositivo',
      onSelected: (mac) => onSelected(mac == '' ? null : mac),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Todos os dispositivos')),
        for (final d in devices)
          PopupMenuItem(
            value: d.mac,
            child: Text(d.name?.isNotEmpty == true ? d.name! : d.mac),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.secondary.withValues(alpha: 0.15)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.secondary.withValues(alpha: 0.7)
                : context.borderColor,
            width: active ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_rounded,
                size: 14,
                color: active ? AppColors.secondary : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              active ? shortMac(selected!) : 'Dispositivo',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.secondary : context.textSecondary,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Feed with day separators ─────────────────────────────────────────────────

class _EventFeed extends StatelessWidget {
  const _EventFeed({required this.rows});
  final List<DeviceEvent> rows;

  @override
  Widget build(BuildContext context) {
    // Newest first; insert a day label whenever the (local) date changes.
    final items = <Widget>[];
    DateTime? lastDay;
    for (final e in rows) {
      final local = e.receivedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day != lastDay) {
        items.add(_DayLabel(day: day));
        lastDay = day;
      }
      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _EventCard(event: e),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: items,
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = day == today
        ? 'HOJE'
        : day == today.subtract(const Duration(days: 1))
            ? 'ONTEM'
            : '${day.day.toString().padLeft(2, '0')}/'
                '${day.month.toString().padLeft(2, '0')}/${day.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              height: 1,
              color: context.borderColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event card ───────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});
  final DeviceEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = severityStyle(event.severity);
    final isAlarm = event.severity == 3;
    final critical = event.severity == 3 || event.severity == 1;
    final subtitle = eventSubtitle(event);
    final detail = eventDetail(event);

    return Material(
      color: isAlarm
          ? Color.alphaBlend(
              style.color.withValues(alpha: 0.07), context.surfaceColor)
          : context.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAlarm
                  ? style.color.withValues(alpha: 0.6)
                  : context.borderColor.withValues(alpha: 0.55),
              width: isAlarm ? 1.2 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Severity accent bar
                  Container(width: 4, color: style.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: style.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: isAlarm
                                  ? [
                                      BoxShadow(
                                        color: style.color
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child:
                                Icon(style.icon, color: style.color, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventTitle(event),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isAlarm
                                        ? style.color
                                        : context.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    _DeviceTag(mac: event.deviceMac),
                                    const SizedBox(width: 6),
                                    ..._miniStats(context, detail),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                clockTime(event.receivedAt),
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 10.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (critical && event.errorKind == null)
                                Tooltip(
                                  message: event.ackedAt != null
                                      ? 'Entrega confirmada (ACK)'
                                      : 'Aguardando confirmação',
                                  child: Icon(
                                    event.ackedAt != null
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 17,
                                    color: event.ackedAt != null
                                        ? AppColors.secondary
                                        : context.textSecondary
                                            .withValues(alpha: 0.55),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _miniStats(BuildContext context, Map<String, dynamic> detail) {
    final stats = <(IconData, String)>[
      if (detail['temp_tenths'] != null)
        (
          Icons.thermostat_rounded,
          '${((detail['temp_tenths'] as num) / 10).toStringAsFixed(1)}°'
        ),
      if (detail['smoke_raw'] != null)
        (Icons.cloud_outlined, '${detail['smoke_raw']}'),
      if (detail['battery_pct'] != null)
        (Icons.battery_std_rounded, '${detail['battery_pct']}%'),
    ];
    return [
      for (final (icon, text) in stats)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 11.5,
                  color: context.textSecondary.withValues(alpha: 0.8)),
              const SizedBox(width: 2),
              Text(
                text,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _EventDetailSheet(event: event),
    );
  }
}

class _DeviceTag extends StatelessWidget {
  const _DeviceTag({required this.mac});
  final String mac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.memory_rounded,
              size: 11, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            shortMac(mac),
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────

class _EventDetailSheet extends ConsumerWidget {
  const _EventDetailSheet({required this.event});
  final DeviceEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = severityStyle(event.severity);
    final detail = eventDetail(event);
    final local = event.receivedAt.toLocal();
    final subtitle = eventSubtitle(event);

    // Everything in plain words — the raw bytes live behind "Ver pacote bruto".
    final power = <String>[
      if (detail['ac_ok'] == true) 'rede elétrica',
      if (detail['on_battery'] == true) 'na bateria',
      if (detail['charging'] == true) 'carregando',
      if (detail['tamper'] == true) 'VIOLADO',
    ];
    final facts = <(String, String)>[
      ('Dispositivo', event.deviceMac),
      (
        'Recebido em',
        '${local.day.toString().padLeft(2, '0')}/'
            '${local.month.toString().padLeft(2, '0')}/${local.year} às '
            '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}:'
            '${local.second.toString().padLeft(2, '0')}'
      ),
      if (power.isNotEmpty) ('Alimentação', power.join(' · ')),
      if (detail['battery_pct'] != null)
        ('Bateria', '${detail['battery_pct']}%'),
      if (detail['temp_tenths'] != null)
        (
          'Temperatura',
          '${((detail['temp_tenths'] as num) / 10).toStringAsFixed(1)} °C'
        ),
      if (detail['humidity_pct'] != null)
        ('Umidade do ar', '${detail['humidity_pct']}%'),
      if (detail['smoke_raw'] != null)
        ('Nível de fumaça', '${detail['smoke_raw']} (leitura do sensor)'),
      if (event.errorKind == null &&
          (event.severity == 3 || event.severity == 1))
        (
          'Confirmação (ACK)',
          event.ackedAt != null
              ? 'Enviada ao root ✓✓'
              : 'Pendente — aguardando envio'
        ),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Severity header band
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.10),
              border: Border(
                bottom: BorderSide(
                  color: style.color.withValues(alpha: 0.35),
                  width: 0.7,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(style.icon, color: style.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventTitle(event),
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      color: style.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, value) in facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(label,
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12.5)),
                        ),
                        Expanded(
                          child: Text(value,
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                if (event.packetId != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openRawPacket(context, ref),
                      icon: const Icon(Icons.data_object_rounded, size: 16),
                      label: const Text('Ver pacote bruto'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRawPacket(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final packet = await (db.select(db.serialPackets)
          ..where((t) => t.id.equals(event.packetId!)))
        .getSingleOrNull();
    if (packet == null || !context.mounted) return;
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SafrDetailScreen(packet: packet)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 52, color: context.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Nenhum evento ainda',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Os eventos dos dispositivos aparecerão aqui\nassim que a rede começar a reportar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
