import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/central/application/central_auth_provider.dart';
import '../../../core/connectivity/network_status_provider.dart';
import '../../widgets/iot_network_animation.dart';
import '../auth/login_screen.dart';
import '../../../features/central/presentation/screens/serial_logs_screen.dart';
import 'main_tab.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_bottom_nav.dart';
import 'widgets/main_drawer.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  MainTab _currentTab = MainTab.principal;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _pinOverlayVisible = AppConfig.isCentral;

  @override
  Widget build(BuildContext context) {
    final isLocked = AppConfig.isCentral &&
        ref.watch(centralAuthProvider) is! CentralAuthenticated;

    ref.listen(centralAuthProvider, (prev, next) {
      if (next is CentralAuthenticated && _pinOverlayVisible) {
        setState(() => _pinOverlayVisible = false);
      }
      // Only hide the PIN overlay on explicit lock (prev was Authenticated),
      // not after a failed attempt (prev was CentralPinError → reset()).
      if (next is CentralUnauthenticated && prev is! CentralPinError) {
        setState(() {
          _pinOverlayVisible = false;
          _currentTab = MainTab.principal;
        });
      }
    });

    if (!AppConfig.isCentral) {
      ref.listen(authNotifierProvider, (_, next) {
        if (next is AsyncData && next.value == null) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
            (_) => false,
          );
        }
      });
    }

    return Builder(
      builder: (context) {
        final scaffold = Scaffold(
          key: _scaffoldKey,
          backgroundColor: context.bgColor,
          appBar: MainAppBar(
            isLocked: isLocked,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          drawer: isLocked
              ? null
              : MainDrawer(
                  currentTab: _currentTab,
                  onTabSelected: (tab) => setState(() => _currentTab = tab),
                ),
          body: _TabBody(currentTab: _currentTab),
          bottomNavigationBar: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SizeTransition(
                    sizeFactor: curved,
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              child: isLocked
                  ? const SizedBox.shrink(key: ValueKey('nav_locked'))
                  : MainBottomNav(
                      key: const ValueKey('nav_unlocked'),
                      currentTab: _currentTab,
                      onTabChanged: (tab) =>
                          setState(() => _currentTab = tab),
                    ),
            ),
        );

        return Stack(
          children: [
            scaffold,
            // Touch capture overlay — when locked, any tap shows the PIN
            if (isLocked)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _pinOverlayVisible = true),
                  child: const SizedBox.expand(),
                ),
              ),
            // PIN overlay with fade-in/out
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _pinOverlayVisible
                  ? _PinOverlay(
                      key: const ValueKey('pin_overlay'),
                      onDismiss: () =>
                          setState(() => _pinOverlayVisible = false),
                    )
                  : const SizedBox.shrink(key: ValueKey('pin_empty')),
            ),
          ],
        );
      },
    );
  }
}

// ── Tab body with fade transitions ───────────────────────────────────────────

class _TabBody extends StatelessWidget {
  const _TabBody({required this.currentTab});

  final MainTab currentTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey(currentTab),
        child: switch (currentTab) {
          MainTab.principal => const _PrincipalTab(),
          MainTab.central => const _PlaceholderTab(
              icon: Icons.sensors_rounded,
              title: 'Central',
              subtitle: 'Configurações e detalhes da central.',
            ),
          MainTab.centrais => const _PlaceholderTab(
              icon: Icons.hub_rounded,
              title: 'Centrais',
              subtitle: 'Lista de centrais cadastradas.',
            ),
          MainTab.devices => const _PlaceholderTab(
              icon: Icons.devices_rounded,
              title: 'Dispositivos',
              subtitle: 'Nenhum dispositivo conectado ainda.',
            ),
          MainTab.social => const _PlaceholderTab(
              icon: Icons.group_rounded,
              title: 'Social',
              subtitle: 'Equipes e contatos.',
            ),
          MainTab.logs => const SerialLogsScreen(),
        },
      ),
    );
  }
}

// ── Principal tab — Dashboard ────────────────────────────────────────────────

class _PrincipalTab extends ConsumerWidget {
  const _PrincipalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    return AppConfig.isCentral
        ? _CentralDashboard(networkStatus: networkStatus)
        : _AppDashboard(networkStatus: networkStatus);
  }
}

// ── Central dashboard ────────────────────────────────────────────────────────

class _CentralDashboard extends StatelessWidget {
  const _CentralDashboard({required this.networkStatus});

  final NetworkStatus networkStatus;

  // Placeholder counts — wire to real providers when backend is ready.
  static const _totalDevices = 0;
  static const _totalAlertas = 0;
  static const _totalOk = 0;
  static const _totalAlarme = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CentralStatusCard(networkStatus: networkStatus),
          const SizedBox(height: 12),
          const _SectionLabel('DISPOSITIVOS'),
          const SizedBox(height: 8),
          const _MetricCard(
            icon: Icons.devices_rounded,
            label: 'Total Dispositivos',
            value: _totalDevices,
            accent: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          const _SectionLabel('EVENTOS'),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.notifications_rounded,
                  label: 'Alertas',
                  value: _totalAlertas,
                  accent: AppColors.warning,
                  compact: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'OK',
                  value: _totalOk,
                  accent: AppColors.success,
                  compact: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Alarme',
                  value: _totalAlarme,
                  accent: AppColors.error,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SectionLabel('BATERIA'),
          const SizedBox(height: 8),
          const _GadgetRow(),
        ],
      ),
    );
  }
}

// ── App dashboard (non-Central) ──────────────────────────────────────────────

class _AppDashboard extends StatelessWidget {
  const _AppDashboard({required this.networkStatus});

  final NetworkStatus networkStatus;

  // Placeholder counts — wire to real providers when backend is ready.
  static const _totalCentrals = 0;
  static const _totalDevices = 0;
  static const _totalAlertas = 0;
  static const _totalOk = 0;
  static const _totalAlarme = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AppStatusCard(networkStatus: networkStatus),
          const SizedBox(height: 12),
          const _SectionLabel('REDE'),
          const SizedBox(height: 8),
          const _MetricCard(
            icon: Icons.sensors_rounded,
            label: 'Total Centrais',
            value: _totalCentrals,
            accent: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          const _MetricCard(
            icon: Icons.devices_rounded,
            label: 'Total Dispositivos',
            value: _totalDevices,
            accent: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          const _SectionLabel('EVENTOS'),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.notifications_rounded,
                  label: 'Alertas',
                  value: _totalAlertas,
                  accent: AppColors.warning,
                  compact: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'OK',
                  value: _totalOk,
                  accent: AppColors.success,
                  compact: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Alarme',
                  value: _totalAlarme,
                  accent: AppColors.error,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SectionLabel('BATERIA'),
          const SizedBox(height: 8),
          const _GadgetRow(),
        ],
      ),
    );
  }
}

class _AppStatusCard extends StatelessWidget {
  const _AppStatusCard({required this.networkStatus});

  final NetworkStatus networkStatus;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (networkStatus) {
      NetworkStatus.online  => (AppColors.success, 'Conectado'),
      NetworkStatus.limited => (AppColors.warning, 'Acesso limitado'),
      NetworkStatus.offline => (AppColors.error,   'Sem conexão'),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SempreIoT',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _PulsingStatusDot(color: statusColor, active: networkStatus == NetworkStatus.online),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: context.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CentralStatusCard extends StatelessWidget {
  const _CentralStatusCard({required this.networkStatus});

  final NetworkStatus networkStatus;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (networkStatus) {
      NetworkStatus.online  => (AppColors.success, 'Operacional'),
      NetworkStatus.limited => (AppColors.warning, 'Acesso limitado'),
      NetworkStatus.offline => (AppColors.error,   'Sem conexão'),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sensors_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status da Central',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          _PulsingStatusDot(color: statusColor, active: networkStatus == NetworkStatus.online),
        ],
      ),
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingStatusDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.25),
                ),
              ),
            ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: compact ? _compactContent(context) : _fullContent(context),
    );
  }

  Widget _fullContent(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.toString(),
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 17),
        ),
        const SizedBox(height: 10),
        Text(
          value.toString(),
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Gadget row ───────────────────────────────────────────────────────────────

class _GadgetRow extends StatelessWidget {
  const _GadgetRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _BatteryGadget(percent: 78)),
        SizedBox(width: 8),
        Expanded(child: _TemperatureGadget(celsius: 32)),
      ],
    );
  }
}

class _BatteryGadget extends StatefulWidget {
  const _BatteryGadget({this.percent = 78});
  final int percent;

  @override
  State<_BatteryGadget> createState() => _BatteryGadgetState();
}

class _BatteryGadgetState extends State<_BatteryGadget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0, end: widget.percent / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.percent > 50
        ? AppColors.success
        : widget.percent > 20
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.battery_charging_full_rounded, size: 11, color: color),
              const SizedBox(width: 5),
              Text(
                'BATERIA',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => CustomPaint(
                size: const Size(90, 90),
                painter: _BatteryArcPainter(
                  progress: _anim.value,
                  color: color,
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.percent * _anim.value).round()}%',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'carga',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryArcPainter extends CustomPainter {
  const _BatteryArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;
    const startAngle = 140 * (math.pi / 180);
    const sweepAngle = 260 * (math.pi / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_BatteryArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _TemperatureGadget extends StatefulWidget {
  const _TemperatureGadget({this.celsius = 32});
  final double celsius;

  @override
  State<_TemperatureGadget> createState() => _TemperatureGadgetState();
}

class _TemperatureGadgetState extends State<_TemperatureGadget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Maps 0–80°C range to a 0..1 progress value for the arc.
  double get _progress => (widget.celsius / 80).clamp(0.0, 1.0);

  Color get _color {
    if (widget.celsius < 30) return AppColors.secondary;
    if (widget.celsius < 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_rounded, size: 11, color: color),
              const SizedBox(width: 5),
              Text(
                'TEMPERATURA',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => CustomPaint(
                size: const Size(90, 90),
                painter: _BatteryArcPainter(
                  progress: _progress * _anim.value,
                  color: color,
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.celsius * _anim.value).toStringAsFixed(0)}°',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'celsius',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic placeholder tab ──────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: context.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Central PIN overlay ──────────────────────────────────────────────────────

class _PinOverlay extends ConsumerStatefulWidget {
  const _PinOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  ConsumerState<_PinOverlay> createState() => _PinOverlayState();
}

class _PinOverlayState extends ConsumerState<_PinOverlay> {
  final List<String> _digits = [];
  bool _escapeVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _escapeVisible = true);
    });
  }

  void _onDigit(String d) {
    if (_digits.length >= 6) return;
    setState(() => _digits.add(d));
    if (_digits.length == 6) {
      ref.read(centralAuthProvider.notifier).verify(_digits.join());
    }
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
    final authState = ref.read(centralAuthProvider);
    if (authState is CentralPinError) {
      ref.read(centralAuthProvider.notifier).reset();
    }
  }

  void _clear() {
    setState(() => _digits.clear());
    ref.read(centralAuthProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(centralAuthProvider);
    final hasError = authState is CentralPinError;
    final errorMessage = authState is CentralPinError ? authState.message : null;
    final networkStatus = ref.watch(networkStatusProvider);

    ref.listen(centralAuthProvider, (_, next) {
      if (next is CentralPinError) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _clear();
        });
      }
    });

    final dots = _PinDots(filledCount: _digits.length, hasError: hasError);
    final numpad = _Numpad(onDigit: _onDigit, onDelete: _onDelete);
    final errorLabel = _ErrorLabel(message: errorMessage);
    final escapeBtn = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _escapeVisible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: _EscapeButton(onTap: widget.onDismiss),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(child: IoTNetworkAnimation()),
          SafeArea(
            child: Column(
              children: [
                _ConnectivityBanner(networkStatus: networkStatus),
                Expanded(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      if (orientation == Orientation.landscape) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _PinHeader(showIcon: false),
                                  const SizedBox(height: 10),
                                  dots,
                                  const SizedBox(height: 6),
                                  errorLabel,
                                  const SizedBox(height: 10),
                                  escapeBtn,
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 24),
                              color: AppColors.divider.withValues(alpha: 0.25),
                            ),
                            Expanded(
                              flex: 55,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availH = constraints.maxHeight;
                                  final availW = constraints.maxWidth;
                                  // Fill ~85% of height across 4 rows
                                  final rowGap = (availH * 0.03).clamp(6.0, 16.0);
                                  final keyH = ((availH * 0.85) - rowGap * 4) / 4;
                                  // Each slot = keyW + 2*hPad; hPad = keyW*0.13
                                  // 3 slots fill ~88% of width => keyW = availW*0.88 / (3*1.26)
                                  final keyW = (availW * 0.88) / (3 * 1.26);
                                  return Center(
                                    child: _Numpad(
                                      onDigit: _onDigit,
                                      onDelete: _onDelete,
                                      keyWidth: keyW.clamp(44.0, 96.0),
                                      keyHeight: keyH.clamp(40.0, 82.0),
                                      rowGap: rowGap,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _PinHeader(),
                                const SizedBox(height: 48),
                                dots,
                                const SizedBox(height: 12),
                                errorLabel,
                                const SizedBox(height: 40),
                                numpad,
                                const SizedBox(height: 28),
                                escapeBtn,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

class _PinHeader extends StatelessWidget {
  const _PinHeader({this.showIcon = true});

  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showIcon) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.secondary,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Central SempreIoT',
          style: TextStyle(
            fontSize: showIcon ? 22 : 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Digite o código de acesso',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filledCount, required this.hasError});

  final int filledCount;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.error
                : filled
                    ? AppColors.secondary
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : filled
                      ? AppColors.secondary
                      : AppColors.divider,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorLabel extends StatelessWidget {
  const _ErrorLabel({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: message != null ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        message ?? '',
        style: const TextStyle(fontSize: 13, color: AppColors.error),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    this.keyWidth = 72,
    this.keyHeight = 64,
    this.rowGap = 12,
  });

  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final double keyWidth;
  final double keyHeight;
  final double rowGap;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = (keyWidth * 0.13).clamp(6.0, 12.0);
    final slotW = keyWidth + hPad * 2;
    final fontSize = (keyHeight * 0.38).clamp(16.0, 28.0);
    final iconSize = (keyHeight * 0.30).clamp(14.0, 22.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _keys.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowGap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return SizedBox(width: slotW, height: keyHeight);
              if (key == 'del') {
                return _NumpadKey(
                  onTap: onDelete,
                  width: keyWidth,
                  height: keyHeight,
                  child: Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondaryDark,
                    size: iconSize,
                  ),
                );
              }
              return _NumpadKey(
                onTap: () => onDigit(key),
                width: keyWidth,
                height: keyHeight,
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.child,
    required this.onTap,
    this.width = 72,
    this.height = 64,
  });

  final Widget child;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hPad = (width * 0.13).clamp(6.0, 12.0);
    final radius = (height * 0.22).clamp(10.0, 18.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Material(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Escape button ────────────────────────────────────────────────────────────

class _EscapeButton extends StatelessWidget {
  const _EscapeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        splashColor: AppColors.textSecondaryDark.withValues(alpha: 0.08),
        highlightColor: AppColors.textSecondaryDark.withValues(alpha: 0.05),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: AppColors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 13,
                color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Continuar bloqueado',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Connectivity banner ──────────────────────────────────────────────────────

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.networkStatus});

  final NetworkStatus networkStatus;

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconData, iconColor, label) = switch (networkStatus) {
      NetworkStatus.online => (
          const Color(0xFF1A3A28),
          Icons.wifi_rounded,
          AppColors.success,
          'Online',
        ),
      NetworkStatus.limited => (
          const Color(0xFF3A2D0A),
          Icons.wifi_rounded,
          AppColors.warning,
          'Wi-Fi conectado — servidor inacessível',
        ),
      NetworkStatus.offline => (
          const Color(0xFF3A1A1A),
          Icons.wifi_off_rounded,
          AppColors.error,
          'Sem conexão — modo offline',
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 28,
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
