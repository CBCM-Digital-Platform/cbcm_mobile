import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../routing/app_routes.dart';
import 'logout_dialog.dart';

/// 3-dots overflow popup menu button (Icons.more_vert).
/// Opens a dropdown menu with shortcuts for My Profile, Settings, Help & Support,
/// and a prominent Logout action that triggers the confirmation dialog.
class AppOverflowMenuButton extends ConsumerWidget {
  const AppOverflowMenuButton({
    super.key,
    this.color,
    this.showProfile = true,
  });

  final Color? color;
  final bool showProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      tooltip: 'More options',
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        switch (val) {
          case 'profile':
            context.push(AppRoutes.profile);
            break;
          case 'settings':
            context.push(AppRoutes.settings);
            break;
          case 'help':
            context.push(AppRoutes.help);
            break;
          case 'logout':
            confirmAndLogout(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        if (showProfile)
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20),
                SizedBox(width: 12),
                Text('My Profile'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 20),
              SizedBox(width: 12),
              Text('Help & Support'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.destructive),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.destructive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

