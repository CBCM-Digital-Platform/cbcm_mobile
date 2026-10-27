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
    this.icon,
    this.trailingIcon,
    this.shape,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final Widget? trailingIcon;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    Widget content = Text(label);
    if (trailingIcon != null || icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(label),
          if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
        ],
      );
    }

    final defaultShape =
        shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

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
            shape: defaultShape,
          ),
          child: content,
        );

      // For actions like Back: olive outline, never turns red
      case AppButtonVariant.secondary:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
            side: BorderSide(color: isDark ? AppColors.primaryLight : AppColors.primary),
            textStyle: AppTypography.button,
            minimumSize: const Size(0, 48),
            shape: defaultShape,
          ),
          child: content,
        );

      // For Cancel, Delete, Logout: neutral at rest, red on hover or press
      case AppButtonVariant.danger:
        return OutlinedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(0, 48)),
            textStyle: WidgetStateProperty.all(AppTypography.button),
            shape: WidgetStateProperty.all(defaultShape),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              final active = states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return active
                  ? AppColors.destructive
                  : Theme.of(context).colorScheme.onSurface;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              final active = states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return BorderSide(
                color: active
                    ? AppColors.destructive
                    : Theme.of(context).dividerColor,
              );
            }),
          ),
          child: content,
        );
    }
  }
}