import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/central/application/central_auth_provider.dart';
import '../../widgets/iot_network_animation.dart';
import '../auth/login_screen.dart';
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
  bool _pinOverlayVisible = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = AppConfig.isCentral &&
        ref.watch(centralAuthProvider) is! CentralAuthenticated;

    ref.listen(centralAuthProvider, (_, next) {
      if (next is CentralAuthenticated && _pinOverlayVisible) {
        setState(() => _pinOverlayVisible = false);
      }
      if (next is CentralUnauthenticated) {
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
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;
    return AppConfig.isCentral
        ? _CentralDashboard(isOnline: isOnline)
        : _AppDashboard(isOnline: isOnline);
  }
}

// ── Central dashboard ────────────────────────────────────────────────────────

class _CentralDashboard extends StatelessWidget {
  const _CentralDashboard({required this.isOnline});

  final bool isOnline;

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
          _CentralStatusCard(isOnline: isOnline),
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
        ],
      ),
    );
  }
}

// ── App dashboard (non-Central) ──────────────────────────────────────────────

class _AppDashboard extends StatelessWidget {
  const _AppDashboard({required this.isOnline});

  final bool isOnline;

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
          _AppStatusCard(isOnline: isOnline),
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
        ],
      ),
    );
  }
}

class _AppStatusCard extends StatelessWidget {
  const _AppStatusCard({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.success : AppColors.error;
    final statusLabel = isOnline ? 'Conectado' : 'Sem conexão';

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
          _PulsingStatusDot(color: statusColor, active: isOnline),
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
  const _CentralStatusCard({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.success : AppColors.error;
    final statusLabel = isOnline ? 'Operacional' : 'Sem conexão';

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
          _PulsingStatusDot(color: statusColor, active: isOnline),
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
    if (_digits.length >= 4) return;
    setState(() => _digits.add(d));
    if (_digits.length == 4) {
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
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.valueOrNull ?? false;

    ref.listen(centralAuthProvider, (_, next) {
      if (next is CentralPinError) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _clear();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(child: IoTNetworkAnimation()),
          SafeArea(
            child: Column(
              children: [
                _ConnectivityBanner(isOnline: isOnline),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _PinHeader(),
                            const SizedBox(height: 48),
                            _PinDots(
                              filledCount: _digits.length,
                              hasError: hasError,
                            ),
                            const SizedBox(height: 12),
                            _ErrorLabel(message: errorMessage),
                            const SizedBox(height: 40),
                            _Numpad(onDigit: _onDigit, onDelete: _onDelete),
                            const SizedBox(height: 28),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0.0,
                                end: _escapeVisible ? 1.0 : 0.0,
                              ),
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
                            ),
                          ],
                        ),
                      ),
                    ),
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
  const _PinHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        const Text(
          'Central SempreIoT',
          style: TextStyle(
            fontSize: 22,
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
      children: List.generate(4, (i) {
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
  const _Numpad({required this.onDigit, required this.onDelete});

  final void Function(String) onDigit;
  final VoidCallback onDelete;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80, height: 64);
              if (key == 'del') {
                return _NumpadKey(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondaryDark,
                    size: 20,
                  ),
                );
              }
              return _NumpadKey(
                onTap: () => onDigit(key),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 24,
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
  const _NumpadKey({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 72,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
  const _ConnectivityBanner({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 28,
      color: isOnline ? const Color(0xFF1A3A28) : const Color(0xFF3A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 14,
            color: isOnline ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Sem conexão — modo offline',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
