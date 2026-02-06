import 'package:flutter/material.dart';

/// Centralized color definitions for the app.
/// Use these through `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color accent;
  final Color accentSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color iconPrimary;
  final Color border;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.accent,
    required this.accentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.iconPrimary,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Dark theme colors (current app style)
  static const dark = AppColors(
    background: Color(0xFF0B1218), // Dark Navy Background (matches web tone)
    surface: Color(0xFF10161D), // Deep Navy Surface
    surfaceVariant: Color(0xFF1A222C), // Navy Surface Variant
    accent: Color(0xFF122E41), // Compensated Brand color (lighter for Flutter)
    accentSecondary: Color(0xFF1E3A8A), // Lighter blue for active states
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFF9AA0AA),
    textTertiary: Color(0xFF6B7280),
    iconPrimary: Color(0xFF8A8F98),
    border: Color(0xFF2A2E3A),
    divider: Color(0xFF1F2937),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFACC15),
    error: Color(0xFFF87171),
  );

  /// Light theme colors
  static const light = AppColors(
    background: Color(0xFFF1F5F9), // Slate 100 - Better depth than F8F9FA
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE2E8F0), // Slate 200
    accent: Color(0xFF122E41), // Compensated Brand color
    accentSecondary: Color(0xFF1E3A8A),
    textPrimary: Color(0xFF0F172A), // Slate 900 - Richer navy/black
    textSecondary: Color(0xFF475569), // Slate 600
    textTertiary: Color(0xFF94A3B8), // Slate 400
    iconPrimary: Color(0xFF64748B), // Slate 500
    border: Color(0xFFE2E8F0), // Slate 200
    divider: Color(0xFFCBD5E1), // Slate 300
    success: Color(0xFF10B981), // Emerald 500
    warning: Color(0xFFF59E0B), // Amber 500
    error: Color(0xFFEF4444), // Red 500
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? accent,
    Color? accentSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? iconPrimary,
    Color? border,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Extension to easily access AppColors from BuildContext
extension AppColorsExtension on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
