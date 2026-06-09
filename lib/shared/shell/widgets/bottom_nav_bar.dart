import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _items = [
  _NavItem(Icons.home_outlined, Icons.home_rounded, 'Início'),
  _NavItem(Icons.sensors_outlined, Icons.sensors_rounded, 'Dispositivos'),
  _NavItem(Icons.hub_outlined, Icons.hub_rounded, 'Rede'),
  _NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'Social'),
];

class ShellBottomNavBar extends StatelessWidget {
  const ShellBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(
          _items.length,
          (i) => Expanded(
            child: _BottomNavItem(
              data: _items[i],
              isActive: i == selectedIndex,
              onTap: () => onItemSelected(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isActive ? AppColors.accentFire : AppColors.textSecondary;
    final labelColor =
        widget.isActive ? AppColors.textPrimary : AppColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _pressAnim,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.surfaceHigh
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    widget.isActive
                        ? widget.data.activeIcon
                        : widget.data.icon,
                    key: ValueKey(widget.isActive),
                    size: 22,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: labelColor,
                  ),
                  child: Text(
                    widget.data.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
