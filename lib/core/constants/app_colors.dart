import 'package:flutter/material.dart';

/// Internloom Brand Colors & Palette
///
/// Includes semantic aliases (primary, error, meterTrack, etc.) so that
/// profile-module screens which previously imported lib/constants/theme.dart
/// can point here directly without any naming changes at their call sites.
/// AppSpacing is also defined here (was in lib/constants/theme.dart) so
/// that file can be deleted — it only ran standalone during Sprint 1.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color leafGreen = Color(0xFF2E8B4F);
  static const Color bookTeal = Color(0xFF3FA6A6);
  static const Color trunkBrown = Color(0xFF6B4226);

  // Green Shades
  static const Color greenDark = Color(0xFF1E6E3C);
  static const Color greenLight = Color(0xFFE3F3E7);

  // Teal Shades
  static const Color tealDark = Color(0xFF2C7A7A);
  static const Color tealLight = Color(0xFFE0F7F7);

  // Brown Shades
  static const Color brownDark = Color(0xFF4A2E1A);
  static const Color brownLight = Color(0xFFE9DDD1);

  // Neutrals
  static const Color ink = Color(0xFF0F172A);
  static const Color body = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color background = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color white = Color(0xFFFFFFFF);

  // Status Colors (DO NOT ALTER)
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0284C7);

  // ─── Semantic aliases (profile-module compatibility) ──────────────────────
  // These map the profile module's generic names to the real brand tokens so
  // both lib/core and lib/features/profile code resolve to the same values.
  static const Color primary = leafGreen;
  static const Color primaryDark = greenDark;
  static const Color accent = bookTeal;
  static const Color cardBackground = white;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color error = danger;
  static const Color meterTrack = border; // completion meter unfilled track
}

/// Shared spacing scale — previously defined in lib/constants/theme.dart
/// (standalone-module leftover). All profile screens should use this class.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}
