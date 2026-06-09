import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class _SidebarItem {
  const _SidebarItem(this.icon, this.label, this.tabIndex);
  final IconData icon;
  final String label;
  final int? tabIndex;
}

const _mainItems = [
  _SidebarItem(Icons.home_rounded, 'Início', 0),
  _SidebarItem(Icons.sensors_rounded, 'Dispositivos', 1),
  _SidebarItem(Icons.hub_rounded, 'Rede', 2),
  _SidebarItem(Icons.people_rounded, 'Social', 3),
];

const _secondaryItems = [
  _SidebarItem(Icons.notifications_rounded, 'Alertas', null),
  _SidebarItem(Icons.tune_rounded, 'Configurações', null),
];

class CollapsibleSidebar extends StatelessWidget {
  const CollapsibleSidebar({
    super.key,
    required this.selectedIndex,
    required this.isExpanded,
    required this.animation,
    required this.onItemSelected,
    required this.onToggle,
  });

  final int selectedIndex;
  final bool isExpanded;
  final Animation<double> animation;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ..._mainItems.map(
            (item) => _NavItem(
              item: item,
              isActive: item.tabIndex == selectedIndex,
              animation: animation,
              onTap: item.tabIndex != null
                  ? () => onItemSelected(item.tabIndex!)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          _Divider(animation: animation),
          const SizedBox(height: 4),
          ..._secondaryItems.map(
            (item) => _NavItem(
              item: item,
              isActive: false,
              animation: animation,
              onTap: null,
            ),
          ),
          const Spacer(),
          _ToggleButton(isExpanded: isExpanded, animation: animation, onTap: onToggle),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.animation,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool isActive;
  final Animation<double> animation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color:
                  isActive ? AppColors.accentFire : AppColors.textSecondary,
            ),
            // Label fades + clips as sidebar collapses
            ClipRect(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, child) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: animation.value,
                  child: Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12.0 + animation.value * 8.0,
          vertical: 4,
        ),
        child: const Divider(
          color: AppColors.borderSubtle,
          height: 1,
          thickness: 1,
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            // "Recolher" label shown only when expanded
            ClipRect(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, child) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: animation.value,
                  child: Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Recolher',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
