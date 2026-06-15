import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/connectivity/network_status_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/central/application/central_iot_provider.dart';
import '../../../../features/iot/application/iot_provider.dart';

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.pulse = true});

  final Color color;
  final bool pulse;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.8),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );

    if (!widget.pulse) return dot;
    return FadeTransition(opacity: _opacity, child: dot);
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.icon,
    required this.iconColor,
    required this.dotColor,
    required this.pulse,
    required this.tooltip,
  });

  final IconData icon;
  final Color iconColor;
  final Color dotColor;
  final bool pulse;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            Positioned(
              right: 2,
              bottom: 2,
              child: _PulsingDot(color: dotColor, pulse: pulse),
            ),
          ],
        ),
      ),
    );
  }
}

class WifiIndicator extends ConsumerWidget {
  const WifiIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(connectivityProvider).isLoading;
    final status = loading ? NetworkStatus.online : ref.watch(networkStatusProvider);

    final (icon, color, tooltip, pulse) = switch (status) {
      NetworkStatus.online => (
          Icons.wifi_rounded,
          AppColors.success,
          'Rede e servidor conectados',
          true,
        ),
      NetworkStatus.limited => (
          Icons.wifi_rounded,
          AppColors.warning,
          'Wi-Fi conectado — servidor inacessível',
          false,
        ),
      NetworkStatus.offline => (
          Icons.wifi_off_rounded,
          AppColors.error,
          'Sem conexão de rede',
          false,
        ),
    };

    return _StatusIcon(
      icon: icon,
      iconColor: loading ? AppColors.warning : color,
      dotColor: loading ? AppColors.warning : color,
      pulse: loading ? false : pulse,
      tooltip: loading ? 'Verificando rede...' : tooltip,
    );
  }
}

class MqttIndicator extends ConsumerWidget {
  const MqttIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iot = AppConfig.isCentral
        ? ref.watch(centralIotConnectionProvider)
        : ref.watch(iotConnectionProvider);
    final connected = iot.valueOrNull ?? false;
    final loading = iot.isLoading;

    final color = loading
        ? AppColors.warning
        : connected
            ? AppColors.success
            : AppColors.error;

    return _StatusIcon(
      icon: connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
      iconColor: color,
      dotColor: color,
      pulse: connected && !loading,
      tooltip: loading
          ? 'Conectando ao servidor...'
          : connected
              ? 'Servidor MQTT conectado'
              : 'Servidor desconectado',
    );
  }
}

class UsbIndicator extends StatelessWidget {
  const UsbIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatusIcon(
      icon: Icons.usb_rounded,
      iconColor: AppColors.textSecondaryDark.withValues(alpha: 0.3),
      dotColor: AppColors.textSecondaryDark.withValues(alpha: 0.3),
      pulse: false,
      tooltip: 'USB — Em desenvolvimento',
    );
  }
}
