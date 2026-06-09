import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Text(
              'SOCIAL',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
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
                      Icons.people_outline_rounded,
                      size: 30,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Área social em desenvolvimento',
                    style: GoogleFonts.barlow(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comunicação entre operadores\ne notificações serão exibidas aqui',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
