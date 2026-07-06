import 'dart:math' as math;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/provisioning_wizard_provider.dart';
import 'wizard_buttons.dart';

/// Step 2 — guide the user to join the device's SoftAP. The wizard notifier
/// is already polling /info underneath; the step auto-advances on contact.
class ConnectWifiStep extends ConsumerWidget {
  const ConnectWifiStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId =
        ref.watch(provisioningWizardProvider).credentials?.deviceId ?? '';
    final ssid = 'SEMPREIOT-${deviceId.toUpperCase()}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Center(child: _RadarPulse()),
          const SizedBox(height: 24),
          Text(
            'Conecte-se ao dispositivo',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O dispositivo cria uma rede Wi-Fi própria durante a configuração.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const _InstructionTile(
            index: 1,
            text: 'Abra os ajustes de Wi-Fi do seu aparelho',
          ),
          _InstructionTile.rich(
            index: 2,
            prefix: 'Conecte-se à rede ',
            highlight: ssid,
          ),
          const _InstructionTile(
            index: 3,
            text: 'Volte para este aplicativo',
          ),
          const SizedBox(height: 24),
          if (!kIsWeb) ...[
            WizardPrimaryButton(
              label: 'Abrir Ajustes de Wi-Fi',
              icon: Icons.wifi_rounded,
              onTap: () =>
                  AppSettings.openAppSettings(type: AppSettingsType.wifi),
            ),
            const SizedBox(height: 12),
          ],
          const _SearchingBanner(),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(provisioningWizardProvider.notifier).backToScan(),
              child: Text(
                'Voltar',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Pulsing radar rings around a device icon — "we're listening for it".
class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _RadarPainter(progress: _controller.value),
          child: const Center(
            child: Icon(
              Icons.router_rounded,
              size: 40,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress});

  final double progress;

  static const _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    const minRadius = 32.0;

    for (var i = 0; i < _ringCount; i++) {
      final t = (progress + i / _ringCount) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * t;
      final opacity = (1 - t) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.secondary.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Static inner disc behind the icon.
    canvas.drawCircle(
      center,
      minRadius,
      Paint()..color = AppColors.secondary.withValues(alpha: 0.10),
    );

    // Subtle rotating sweep dot on the middle ring.
    final sweepAngle = progress * 2 * math.pi;
    final dotRadius = minRadius + (maxRadius - minRadius) * 0.5;
    canvas.drawCircle(
      center +
          Offset(math.cos(sweepAngle), math.sin(sweepAngle)) * dotRadius,
      3,
      Paint()..color = AppColors.secondary.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({required this.index, required this.text})
      : prefix = null,
        highlight = null;

  const _InstructionTile.rich({
    required this.index,
    required this.prefix,
    required this.highlight,
  }) : text = null;

  final int index;
  final String? text;
  final String? prefix;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: text != null
                  ? Text(
                      text!,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        text: prefix,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: highlight,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingBanner extends StatelessWidget {
  const _SearchingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Procurando dispositivo... avançaremos automaticamente.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
