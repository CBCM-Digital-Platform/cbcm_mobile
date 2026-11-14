import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_mode_provider.dart';

/// An AppBar action button that toggles between light and dark theme mode.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: color,
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme(
              Theme.of(context).brightness,
            );
      },
    );
  }
}

