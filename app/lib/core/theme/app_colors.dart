import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF427A5F);
  static const Color primaryHover = Color(0xFF4B916F);
  static const Color primaryLight = Color(0xFFDFEFEE);
  static const Color primaryDark = Color(0xFF2D5A45);
  static const Color primaryMuted = Color(0xFFEBF5F0);

  // Secondary colors
  static const Color secondary = Color(0xFFDDDFDD);
  static const Color secondaryForeground = Color(0xFF222A26);

  // Accent
  static const Color accent = Color(0xFFB38E46);
  static const Color accentLight = Color(0xFFFFF8E8);

  // Backgrounds - Light
  static const Color background = Color(0xFFF7F8F7);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color cardElevated = Color(0xFFFCFCFC);

  // Backgrounds - Dark
  static const Color backgroundDark = Color(0xFF0F1110);
  static const Color surfaceDark = Color(0xFF1A1C1A);
  static const Color cardDark = Color(0xFF242624);
  static const Color cardElevatedDark = Color(0xFF2C2E2C);

  // Status colors
  static const Color destructive = Color(0xFFD43B40);
  static const Color destructiveLight = Color(0xFFFEECED);
  static const Color success = Color(0xFF5DA04D);
  static const Color successLight = Color(0xFFEDF7EB);
  static const Color warning = Color(0xFFE6A23C);
  static const Color warningLight = Color(0xFFFFF7E6);
  static const Color info = Color(0xFF409EFF);
  static const Color infoLight = Color(0xFFECF5FF);

  // Text - Light mode
  static const Color textPrimary = Color(0xFF1A1F1C);
  static const Color textSecondary = Color(0xFF6B7770);
  static const Color textTertiary = Color(0xFF9CA8A0);
  static const Color textOnPrimary = Colors.white;

  // Text - Dark mode
  static const Color textPrimaryDark = Color(0xFFF0F2F0);
  static const Color textSecondaryDark = Color(0xFF9CA8A0);
  static const Color textTertiaryDark = Color(0xFF6B7770);
  static const Color textOnDark = Colors.white;

  // Borders
  static const Color border = Color(0xFFE2E5E3);
  static const Color borderDark = Color(0xFF363836);
  static const Color borderSubtle = Color(0xFFEEF0EF);
  static const Color borderSubtleDark = Color(0xFF2C2E2C);
  static const Color divider = Color(0xFFE2E5E3);
  static const Color dividerDark = Color(0xFF363836);

  // Other
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color shadow = Color(0x0D000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryHover],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D5A45), Color(0xFF427A5F), Color(0xFF4B916F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB38E46), Color(0xFFC9A55B)],
  );

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: textOnPrimary,
    primaryContainer: primaryLight,
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: secondaryForeground,
    secondaryContainer: primaryLight,
    onSecondaryContainer: secondaryForeground,
    tertiary: accent,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFF8E1),
    onTertiaryContainer: accent,
    error: destructive,
    onError: Colors.white,
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: destructive,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: secondary,
    onSurfaceVariant: textSecondary,
    outline: border,
    outlineVariant: divider,
    shadow: shadow,
    scrim: Colors.black54,
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryHover,
    onPrimary: textOnPrimary,
    primaryContainer: primaryDark,
    onPrimaryContainer: primaryLight,
    secondary: Color(0xFF363836),
    onSecondary: textPrimaryDark,
    secondaryContainer: Color(0xFF242624),
    onSecondaryContainer: textPrimaryDark,
    tertiary: accent,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF4A3A1A),
    onTertiaryContainer: Color(0xFFFFE0A0),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    surfaceContainerHighest: cardDark,
    onSurfaceVariant: textSecondaryDark,
    outline: borderDark,
    outlineVariant: dividerDark,
    shadow: Colors.black,
    scrim: Colors.black87,
  );

  // For backward compatibility - will use context to determine colors
  static const ColorScheme colorScheme = lightColorScheme;
}

/// Extension to get theme-aware colors
extension AppColorsX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor => isDarkMode ? AppColors.backgroundDark : AppColors.background;
  Color get surfaceColor => isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  Color get cardColor => isDarkMode ? AppColors.cardDark : AppColors.card;
  Color get cardElevatedColor => isDarkMode ? AppColors.cardElevatedDark : AppColors.cardElevated;
  Color get textPrimaryColor => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textTertiaryColor => isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary;
  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.border;
  Color get borderSubtleColor => isDarkMode ? AppColors.borderSubtleDark : AppColors.borderSubtle;
  Color get dividerColor => isDarkMode ? AppColors.dividerDark : AppColors.divider;
  Color get primaryMutedColor => isDarkMode
      ? AppColors.primaryHover.withValues(alpha: 0.12)
      : AppColors.primaryMuted;
}
