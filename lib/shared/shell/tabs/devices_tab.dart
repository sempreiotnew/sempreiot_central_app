import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DevicesHeader(),
          Expanded(
            child: Center(
              child: _EmptyDevices(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISPOSITIVOS',
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '0 dispositivos cadastrados',
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentFireDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16, color: AppColors.accentFire),
                const SizedBox(width: 6),
                Text(
                  'Adicionar',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentFire,
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

class _EmptyDevices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceMid,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.sensors_off_rounded,
            size: 30,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Nenhum dispositivo encontrado',
          style: GoogleFonts.barlow(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adicione dispositivos para monitorar\no sistema de alarme de incêndio',
          textAlign: TextAlign.center,
          style: GoogleFonts.barlow(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
