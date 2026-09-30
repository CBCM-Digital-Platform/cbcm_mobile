import 'package:flutter/material.dart';

/// App-wide color palette based on approved project UI specifications.
class AppColors {
  AppColors._();

  /// Primary / normal button color (Dark Olive Green)
  static const Color primary = Color(0xFF315E26);

  /// Page indicator / active-page color (Golden Yellow)
  static const Color pageIndicator = Color(0xFFFFD22B);

  /// Destructive/negative action color (Delete, Cancel, Logout)
  static const Color destructive = Color(0xFFD32F2F);

  /// Background color for screens
  static const Color background = Color(0xFFF8F9FA);

  /// Surface color for cards, sheets, and dialogs
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text color for high contrast readability
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color for subtitles, hints, and captions
  static const Color textSecondary = Color(0xFF757575);

  /// Neutral border and divider color
  static const Color border = Color(0xFFE0E0E0);
}
