import 'package:flutter/material.dart';
import 'app_colors.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  Color get surfaceColor =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  // AppBar / BottomNav / DrawerFooter background
  Color get barColor =>
      isDark ? const Color(0xFF0E1520) : const Color(0xFFF1F5F9);

  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get borderColor =>
      isDark ? AppColors.divider : const Color(0xFFE5E7EB);
}
