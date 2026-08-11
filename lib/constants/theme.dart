import 'package:flutter/material.dart';

/// Shared visual language for the student-side profile feature.
///
/// UPDATE (2026-08-09): the Authentication module's repo was reviewed
/// (uploaded lib/core/constants/app_colors.dart) and it turns out a
/// real, shared brand palette already exists there — this file's
/// `AppColors` values below have been updated to match it exactly
/// (same hex values, same names where they overlap). It is NOT yet
/// deleted/replaced with a direct import, for two reasons:
///
/// 1. This module still needs to run and be demoed standalone (no
///    access to the merged app's folder structure or package name).
/// 2. Both this file and the real `core/constants/app_colors.dart`
///    declare a class named `AppColors` — if a single file in the
///    merged app ever imports both, that's a name collision. Whoever
///    does the actual merge should delete this class entirely and
///    repoint every `AppColors.xxx` reference in lib/screens,
///    lib/widgets, etc. at the real one (or import this file with an
///    `as` prefix as a stopgap). Not done here since it touches ~15
///    files and this module has no way to verify the result compiles
///    (no Flutter SDK in this environment).
///
/// `AppSpacing` has no equivalent in the auth repo (nothing uploaded
/// defines spacing tokens) — kept as-is.
class AppColors {
  // Mapped from the real palette's brand colors:
  static const primary = Color(0xFF2E8B4F); // = leafGreen
  static const primaryDark = Color(0xFF1E6E3C); // = greenDark
  static const accent = Color(0xFF3FA6A6); // = bookTeal
  static const background = Color(0xFFF1F5F9); // = background
  static const cardBackground = Colors.white; // = white
  static const border = Color(0xFFE2E8F0); // = border
  static const textPrimary = Color(0xFF0F172A); // = ink
  static const textSecondary = Color(0xFF64748B); // = muted
  static const error = Color(0xFFDC2626); // = danger
  static const success = Color(0xFF16A34A); // = success
  static const meterTrack = Color(0xFFE2E8F0); // = border

  // Present in the real palette but not previously used here — kept
  // for parity in case a screen needs them:
  static const greenLight = Color(0xFFE3F3E7);
  static const tealLight = Color(0xFFE0F7F7);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF0284C7);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardBackground,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
