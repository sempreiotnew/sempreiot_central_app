import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'tabs/devices_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/social_tab.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/collapsible_sidebar.dart';
import 'widgets/top_status_bar.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with SingleTickerProviderStateMixin {

  static const double _collapsedW = 64.0;
  static const double _expandedW = 220.0;
  static const double _mobileBreak = 600.0;
  static const double _desktopBreak = 1024.0;

  int _selectedIndex = 0;
  bool _sidebarExpanded = false;
  bool _initialized = false;

  late final AnimationController _sidebarCtrl;
  late final Animation<double> _sidebarAnim;

  static const _tabs = [
    HomeTab(),
    DevicesTab(),
    NetworkTab(),
    SocialTab(),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sidebarAnim = CurvedAnimation(
      parent: _sidebarCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final width = MediaQuery.sizeOf(context).width;
      if (width >= _desktopBreak) {
        _sidebarExpanded = true;
        _sidebarCtrl.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _sidebarCtrl.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarExpanded = !_sidebarExpanded);
    _sidebarExpanded ? _sidebarCtrl.forward() : _sidebarCtrl.reverse();
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < _mobileBreak;

    return Scaffold(
      backgroundColor: AppColors.panelBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopStatusBar(
              isCentral: AppConfig.isCentral,
              isMobile: isMobile,
              onMenuToggle: _toggleSidebar,
            ),
            Expanded(child: _buildBody(isMobile)),
            SafeArea(
              top: false,
              child: ShellBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: _selectTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (isMobile) {
      return Stack(
        children: [
          _buildContent(),
          _buildScrim(),
          _buildMobileDrawer(),
        ],
      );
    }

    return Row(
      children: [
        ClipRect(
          child: AnimatedBuilder(
            animation: _sidebarAnim,
            builder: (_, child) => SizedBox(
              width: _collapsedW +
                  (_expandedW - _collapsedW) * _sidebarAnim.value,
              child: child,
            ),
            child: CollapsibleSidebar(
              selectedIndex: _selectedIndex,
              isExpanded: _sidebarExpanded,
              animation: _sidebarAnim,
              onItemSelected: _selectTab,
              onToggle: _toggleSidebar,
            ),
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: _tabs,
    );
  }

  Widget _buildScrim() {
    return AnimatedBuilder(
      animation: _sidebarAnim,
      builder: (_, __) {
        if (_sidebarAnim.value == 0) return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleSidebar,
          child: Container(
            color: Colors.black.withValues(alpha: 0.55 * _sidebarAnim.value),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer() {
    return AnimatedBuilder(
      animation: _sidebarAnim,
      builder: (_, child) => Positioned(
        left: _expandedW * (_sidebarAnim.value - 1.0),
        top: 0,
        bottom: 0,
        width: _expandedW,
        child: child!,
      ),
      child: CollapsibleSidebar(
        selectedIndex: _selectedIndex,
        isExpanded: true,
        animation: const AlwaysStoppedAnimation(1.0),
        onItemSelected: (i) {
          _selectTab(i);
          _toggleSidebar();
        },
        onToggle: _toggleSidebar,
      ),
    );
  }
}
