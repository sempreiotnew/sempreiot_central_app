import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../features/auth/application/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isCentral) {
      ref.listen(authNotifierProvider, (_, next) {
        if (next is AsyncData && next.value == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: context.bgColor,
          appBar: MainAppBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          drawer: MainDrawer(
            currentTab: _currentTab,
            onTabSelected: (tab) => setState(() => _currentTab = tab),
          ),
          body: isWide
              ? _WideLayout(
                  currentTab: _currentTab,
                  onTabSelected: (tab) => setState(() => _currentTab = tab),
                )
              : _TabBody(currentTab: _currentTab),
          bottomNavigationBar: isWide
              ? null
              : MainBottomNav(
                  currentTab: _currentTab,
                  onTabChanged: (tab) => setState(() => _currentTab = tab),
                ),
        );
      },
    );
  }
}

// ── Wide layout (tablet / web) ──────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.currentTab,
    required this.onTabSelected,
  });

  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SideRail(currentTab: currentTab, onTabSelected: onTabSelected),
        VerticalDivider(width: 0.5, color: context.borderColor),
        Expanded(child: _TabBody(currentTab: currentTab)),
      ],
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.currentTab,
    required this.onTabSelected,
  });

  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: context.barColor,
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...MainTab.values.map((tab) {
            final active = tab == currentTab;
            final color = active ? AppColors.secondary : context.textSecondary;
            return Tooltip(
              message: tab.label,
              preferBelow: false,
              child: InkWell(
                onTap: () => onTabSelected(tab),
                child: SizedBox(
                  width: 72,
                  height: 60,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.secondary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tab.icon, size: 20, color: color),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tab body router ─────────────────────────────────────────────────────────

class _TabBody extends StatelessWidget {
  const _TabBody({required this.currentTab});

  final MainTab currentTab;

  @override
  Widget build(BuildContext context) {
    return switch (currentTab) {
      MainTab.principal => const _PrincipalTab(),
      MainTab.devices => const _PlaceholderTab(
          icon: Icons.devices_rounded,
          title: 'Dispositivos',
          subtitle: 'Nenhum dispositivo conectado ainda.',
        ),
      MainTab.network => const _PlaceholderTab(
          icon: Icons.hub_rounded,
          title: 'Rede',
          subtitle: 'Configurações de rede e topologia.',
        ),
      MainTab.social => const _PlaceholderTab(
          icon: Icons.group_rounded,
          title: 'Social',
          subtitle: 'Equipes e contatos.',
        ),
    };
  }
}

// ── Principal tab ────────────────────────────────────────────────────────────

class _PrincipalTab extends ConsumerWidget {
  const _PrincipalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = AppConfig.isCentral
        ? 'Central'
        : (ref.watch(authNotifierProvider).valueOrNull?.userId ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _WelcomeCard(userId: userId),
    );
  }
}

// WelcomeCard always renders on a dark gradient — internal colors are intentionally
// hardcoded to white/light since the background is always dark blue.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152F55), Color(0xFF1A3A6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting!',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.isCentral ? 'Central SempreIoT' : 'SempreIoT',
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.isCentral
                      ? 'Painel de controle da central'
                      : 'Gerencie seus dispositivos IoT',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppColors.secondary,
              size: 24,
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
