import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_router.dart';
import 'core/theme/colors.dart';
import 'core/theme/typography.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CBCM Mobile',
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.destructive,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          headlineLarge: AppTypography.headingLarge,
          headlineMedium: AppTypography.headingMedium,
          headlineSmall: AppTypography.headingSmall,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.button,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}