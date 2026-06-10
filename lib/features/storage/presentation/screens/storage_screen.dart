import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/storage_provider.dart';
import '../../domain/entities/storage_volume.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _StorageAppBar(
        isRefreshing: storageAsync.isLoading,
        onRefresh: () => ref.read(storageProvider.notifier).refresh(),
      ),
      body: storageAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.secondary,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => _ErrorBody(
          onRetry: () => ref.read(storageProvider.notifier).refresh(),
        ),
        data: (volume) => _StorageBody(volume: volume),
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _StorageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StorageAppBar({required this.isRefreshing, required this.onRefresh});

  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: context.bgColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.textSecondary,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Armazenamento',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: context.textSecondary,
                        size: 20,
                      ),
                      onPressed: onRefresh,
                      tooltip: 'Atualizar',
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Não foi possível ler o armazenamento',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique as permissões do dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tentar novamente'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _StorageBody extends StatelessWidget {
  const _StorageBody({required this.volume});

  final StorageVolume volume;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('ARMAZENAMENTO INTERNO'),
          const SizedBox(height: 4),
          Text(
            volume.label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          _GaugeCard(volume: volume),
          const SizedBox(height: 16),
          _StatsRow(volume: volume),
          const SizedBox(height: 16),
          _LinearBreakdown(volume: volume),
          const SizedBox(height: 16),
          _StatusCard(fraction: volume.usedFraction),
        ],
      ),
    );
  }
}

// ── Gauge card ────────────────────────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.volume});

  final StorageVolume volume;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: volume.usedFraction),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, animatedFraction, _) {
              final color = _gaugeColor(animatedFraction);
              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _GaugePainter(
                    fraction: animatedFraction,
                    color: color,
                    trackColor: context.borderColor,
                  ),
                  child: Center(
                    child: _GaugeCenter(
                      volume: volume,
                      animatedFraction: animatedFraction,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Color _gaugeColor(double fraction) {
  if (fraction < 0.6) return AppColors.success;
  if (fraction < 0.8) {
    return Color.lerp(
      AppColors.success,
      AppColors.warning,
      (fraction - 0.6) / 0.2,
    )!;
  }
  return Color.lerp(
    AppColors.warning,
    AppColors.error,
    (fraction - 0.8) / 0.2,
  )!;
}

// ── Gauge center text ─────────────────────────────────────────────────────────

class _GaugeCenter extends StatelessWidget {
  const _GaugeCenter({
    required this.volume,
    required this.animatedFraction,
    required this.color,
  });

  final StorageVolume volume;
  final double animatedFraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final animatedPercent = (animatedFraction * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.storage_rounded, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          '$animatedPercent%',
          style: TextStyle(
            color: color,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'utilizado',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${volume.formattedUsed} / ${volume.formattedTotal}',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Gauge CustomPainter ───────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  // 150° start, 240° total sweep — classic speedometer shape, gap at the bottom
  static const double _startAngle = 150 * math.pi / 180;
  static const double _totalSweep = 240 * math.pi / 180;
  static const double _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - _strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final valueSweep = _totalSweep * fraction.clamp(0.0, 1.0);

    // Background track
    canvas.drawArc(
      rect,
      _startAngle,
      _totalSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor.withValues(alpha: 0.25),
    );

    if (fraction <= 0) return;

    // Glow behind the value arc
    canvas.drawArc(
      rect,
      _startAngle,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Value arc
    canvas.drawArc(
      rect,
      _startAngle,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Tip dot
    final tipAngle = _startAngle + valueSweep;
    final tipOffset = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );

    // Tip glow
    canvas.drawCircle(
      tipOffset,
      10,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Tip solid dot
    canvas.drawCircle(
      tipOffset,
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.volume});

  final StorageVolume volume;

  @override
  Widget build(BuildContext context) {
    final usedColor = _gaugeColor(volume.usedFraction);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Usado',
            value: volume.formattedUsed,
            icon: Icons.pie_chart_rounded,
            color: usedColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Livre',
            value: volume.formattedAvailable,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: volume.formattedTotal,
            icon: Icons.storage_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Linear breakdown bar ──────────────────────────────────────────────────────

class _LinearBreakdown extends StatelessWidget {
  const _LinearBreakdown({required this.volume});

  final StorageVolume volume;

  @override
  Widget build(BuildContext context) {
    final usedColor = _gaugeColor(volume.usedFraction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribuição',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${volume.percentUsed}% ocupado',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: volume.usedFraction),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, fraction, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 10,
                  child: CustomPaint(
                    painter: _BarPainter(
                      fraction: fraction,
                      usedColor: usedColor,
                      freeColor: context.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BarLegend(color: usedColor, label: 'Usado'),
              const SizedBox(width: 16),
              _BarLegend(
                color: context.borderColor.withValues(alpha: 0.6),
                label: 'Livre',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.fraction,
    required this.usedColor,
    required this.freeColor,
  });

  final double fraction;
  final Color usedColor;
  final Color freeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final usedWidth = size.width * fraction.clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = freeColor,
    );

    if (usedWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, usedWidth, size.height),
        Paint()..color = usedColor,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.usedColor != usedColor ||
      old.freeColor != freeColor;
}

class _BarLegend extends StatelessWidget {
  const _BarLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (fraction) {
      0.0 => (
          Icons.info_outline_rounded,
          'Dados de armazenamento não disponíveis nesta plataforma.',
          AppColors.secondary,
        ),
      < 0.6 => (
          Icons.check_circle_outline_rounded,
          'Armazenamento em bom estado. Espaço suficiente disponível.',
          AppColors.success,
        ),
      < 0.8 => (
          Icons.warning_amber_rounded,
          'Espaço moderado disponível. Considere liberar arquivos antigos.',
          AppColors.warning,
        ),
      _ => (
          Icons.error_outline_rounded,
          'Atenção: pouco espaço disponível. Ação recomendada.',
          AppColors.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
