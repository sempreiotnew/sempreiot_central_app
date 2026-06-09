import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';

class NetworkTab extends ConsumerWidget {
  const NetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;

    return Container(
      color: AppColors.panelBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REDE',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            _ConnectionCard(
              label: 'Internet',
              detail: isOnline ? 'Conectado' : 'Sem conexão',
              icon: Icons.wifi_rounded,
              online: isOnline,
            ),
            const SizedBox(height: 10),
            const _ConnectionCard(
              label: 'Servidor MQTT',
              detail: 'Aguardando configuração',
              icon: Icons.cloud_queue_rounded,
              online: false,
            ),
            const SizedBox(height: 10),
            const _ConnectionCard(
              label: 'USB',
              detail: 'Aguardando dispositivo',
              icon: Icons.usb_rounded,
              online: false,
            ),
            const SizedBox(height: 32),
            Text(
              'DIAGNÓSTICO',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _DiagCard(),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.label,
    required this.detail,
    required this.icon,
    required this.online,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final stateColor = online ? AppColors.statusOnline : AppColors.statusUnknown;
    final stateBg = online ? AppColors.statusOnlineDim : AppColors.statusUnknownDim;
    final stateLabel = online ? 'ONLINE' : 'OFFLINE';

    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stateBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              stateLabel,
              style: GoogleFonts.barlow(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: stateColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const _DiagRow(label: 'Latência MQTT', value: '— ms'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const _DiagRow(label: 'Mensagens recebidas', value: '0'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const _DiagRow(label: 'Erros de conexão', value: '0'),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
