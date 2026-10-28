import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../routing/app_routes.dart';

/// The profile avatar in the top bar.
/// Tapping it opens the Profile editing page.
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.profile),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person_outline, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
