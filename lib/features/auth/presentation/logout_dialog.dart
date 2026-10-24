import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_button_row.dart';
import '../../../routing/app_routes.dart';
import '../data/auth_repository_provider.dart';
import 'current_role_provider.dart';

/// Shows the confirmation dialog and, if confirmed, signs the user out.
/// Shared by Mentee and Mentor.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _LogoutDialog(),
  );
  if (confirmed != true) return;

  // Tell the backend first (it revokes the refresh token) while the token
  // is still stored. Never block logging out if this fails, e.g. offline.
  try {
    await ref
        .read(authRepositoryProvider)
        .logout()
        .timeout(const Duration(seconds: 3));
  } catch (_) {}

  // Clears the stored session and the role, which also re-checks the router.
  await ref.read(currentRoleProvider.notifier).logout();
  if (context.mounted) context.go(AppRoutes.login);
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout, color: AppColors.destructive, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              'Log Out',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of ${AppInfo.appName}? '
              "You'll need to enter your credentials to access your "
              'clinical logs and learning modules again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            AppButtonRow(
              secondary: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.danger,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              primary: AppButton(
                label: 'Log Out',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}