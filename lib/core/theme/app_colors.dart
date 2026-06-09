import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Legacy aliases (kept for backward compatibility) ──────────────────────
  static const Color primary = Color(0xFF152F55);
  static const Color secondary = Color(0xFF4A9EBF);
  static const Color backgroundDark = panelBg;
  static const Color surfaceDark = surfaceMid;
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color backgroundLight = Color(0xFFF0F4FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color divider = borderSubtle;

  // ── Panel surfaces (deep navy-slate) ─────────────────────────────────────
  static const Color panelBg = Color(0xFF060B18);
  static const Color surfaceLow = Color(0xFF0B1120);
  static const Color surfaceMid = Color(0xFF0F1826);
  static const Color surfaceHigh = Color(0xFF152030);
  static const Color surfaceRaised = Color(0xFF1C2B40);

  // ── Accent: fire amber ────────────────────────────────────────────────────
  static const Color accentFire = Color(0xFFD97B2E);
  static const Color accentFireBright = Color(0xFFE8953A);
  static const Color accentFireDim = Color(0xFF3A1E08);

  // ── Status colors ─────────────────────────────────────────────────────────
  static const Color statusOnline = Color(0xFF2DAE82);
  static const Color statusOnlineDim = Color(0xFF0C2D22);
  static const Color statusOffline = Color(0xFFD04040);
  static const Color statusOfflineDim = Color(0xFF350E0E);
  static const Color statusWarning = Color(0xFFD97B2E);
  static const Color statusWarningDim = Color(0xFF3A2108);
  static const Color statusUnknown = Color(0xFF4A5567);
  static const Color statusUnknownDim = Color(0xFF1A2130);

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE2E8F2);
  static const Color textSecondary = Color(0xFF62728A);
  static const Color textTertiary = Color(0xFF2E3C50);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF182234);
  static const Color borderMedium = Color(0xFF233047);
}
