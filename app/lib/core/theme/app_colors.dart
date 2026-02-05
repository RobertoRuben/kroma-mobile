import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF427A5F);

  static const Color primaryHover = Color(0xFF4B916F);

  static const Color primaryLight = Color(0xFFDFEFEE);

  static const Color secondary = Color(0xFFDDDFDD);

  static const Color secondaryForeground = Color(0xFF222A26);

  static const Color accent = Color(0xFFB38E46);

  static const Color background = Color(0xFFF7F8F7);

  static const Color surface = Colors.white;

  static const Color backgroundDark = Color(0xFF1A1A1A);

  static const Color destructive = Color(0xFFB63A3F);

  static const Color success = Color(0xFF76A166);

  static const Color warning = Color(0xFFE6A23C);

  static const Color info = Color(0xFF409EFF);

  static const Color textPrimary = Color(0xFF222A26);

  static const Color textSecondary = Color(0xFF6B7280);

  static const Color textOnPrimary = Colors.white;

  static const Color textOnDark = Colors.white;

  static const Color border = Color(0xFFE5E7EB);

  static const Color divider = Color(0xFFE5E7EB);

  static const Color disabled = Color(0xFF9CA3AF);

  static const Color shadow = Color(0x1A000000);


  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryHover],
  );

  static const ColorScheme colorScheme = ColorScheme(
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
}
