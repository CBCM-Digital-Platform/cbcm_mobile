import 'package:flutter/material.dart';

/// App-wide color palette based on approved project UI specifications.
/// Central place to edit and manage colors globally across the application.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------
  // Brand & Semantic Colors (shared across Light and Dark themes)
  // ---------------------------------------------------------

  /// Primary / normal button color (Dark Olive Green)
  static const Color primary = Color(0xFF315E26);

  /// Primary variant for subtle highlights and headers
  static const Color primaryLight = Color(0xFF4C6A4F);

  /// Page indicator / active-page color (Golden Yellow)
  static const Color pageIndicator = Color(0xFFFFD22B);

  /// Destructive/negative action color (Delete, Cancel, Logout)
  static const Color destructive = Color(0xFFD32F2F);

  // ---------------------------------------------------------
  // Light Theme Palette
  // ---------------------------------------------------------

  /// Background color for screens (Light)
  static const Color background = Color(0xFFF8F9FA);

  /// Surface color for cards, sheets, and dialogs (Light)
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text color for high contrast readability (Light)
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color for subtitles, hints, and captions (Light)
  static const Color textSecondary = Color(0xFF757575);

  /// Neutral border and divider color (Light)
  static const Color border = Color(0xFFE0E0E0);

  // ---------------------------------------------------------
  // Dark Theme Palette
  // ---------------------------------------------------------

  /// Background color for screens (Dark)
  static const Color darkBackground = Color(0xFF121412);

  /// Surface color for cards, sheets, and dialogs (Dark)
  static const Color darkSurface = Color(0xFF1E221E);

  /// Elevated surface color for sheets, dialogs, and popups (Dark)
  static const Color darkElevatedSurface = Color(0xFF262C26);

  /// Primary text color for high contrast readability (Dark)
  static const Color darkTextPrimary = Color(0xFFF0F2EE);

  /// Secondary text color for subtitles, hints, and captions (Dark)
  static const Color darkTextSecondary = Color(0xFFA0A6A0);

  /// Neutral border and divider color (Dark)
  static const Color darkBorder = Color(0xFF303630);
}

/// Convenience extensions for semantic theme access on BuildContext.
extension AppThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
