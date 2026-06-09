import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('VISÃO GERAL'),
            const SizedBox(height: 16),
            _StatsRow(),
            const SizedBox(height: 32),
            const _SectionTitle('ALERTAS RECENTES'),
            const SizedBox(height: 16),
            const _EmptyAlerts(),
            const SizedBox(height: 32),
            const _SectionTitle('ZONAS MONITORADAS'),
            const SizedBox(height: 16),
            _ZoneGrid(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentFire,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 3 : 1;
        if (crossCount == 1) {
          return Column(
            children: [
              _StatCard(value: '0', label: 'Alertas Ativos', icon: Icons.warning_amber_rounded, valueColor: AppColors.statusOffline),
              const SizedBox(height: 8),
              _StatCard(value: '0/0', label: 'Dispositivos Online', icon: Icons.sensors_rounded, valueColor: AppColors.statusOnline),
              const SizedBox(height: 8),
              _StatCard(value: '0', label: 'Zonas Ativas', icon: Icons.grid_view_rounded, valueColor: AppColors.textPrimary),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _StatCard(value: '0', label: 'Alertas Ativos', icon: Icons.warning_amber_rounded, valueColor: AppColors.statusOffline)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0/0', label: 'Dispositivos Online', icon: Icons.sensors_rounded, valueColor: AppColors.statusOnline)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: 'Zonas Ativas', icon: Icons.grid_view_rounded, valueColor: AppColors.textPrimary)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.valueColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.rajdhani(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.statusOnlineDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 24,
              color: AppColors.statusOnline,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sistema operando normalmente',
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nenhum alerta ativo no momento',
            style: GoogleFonts.barlow(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final zones = List.generate(6, (i) => 'Zona ${String.fromCharCode(65 + i)}');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: zones.length,
      itemBuilder: (_, i) => _ZoneCard(label: zones[i]),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.statusUnknown,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            'Sem dispositivos',
            style: GoogleFonts.barlow(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
