import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      // Normal button: dark olive green, filled
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTypography.button,
            minimumSize: const Size(0, 48),
          ),
          child: Text(label),
        );

      // For actions like Back: olive outline, never turns red
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            textStyle: AppTypography.button,
            minimumSize: const Size(0, 48),
          ),
          child: Text(label),
        );

      // For Cancel, Delete, Logout: neutral at rest, red on hover or press
      case AppButtonVariant.danger:
        return OutlinedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(0, 48)),
            textStyle: WidgetStateProperty.all(AppTypography.button),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              final active = states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return active ? AppColors.destructive : AppColors.textPrimary;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              final active = states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return BorderSide(
                color: active ? AppColors.destructive : AppColors.border,
              );
            }),
          ),
          child: Text(label),
        );
    }
  }
}