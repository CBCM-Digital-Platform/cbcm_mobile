import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/offline_access.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../routing/app_routes.dart';
import 'logout_dialog.dart';

/// The profile avatar shown in the top bar of both Mentee and Mentor.
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      onSelected: (value) async {
        if (value == 'profile') {
          context.push(AppRoutes.profile);
        } else if (value == 'settings') {
          context.push(AppRoutes.settings);
        } else if (value == 'logout') {
          confirmAndLogout(context, ref);
        } else if (value == 'expire') {
          await ref
              .read(secureStorageProvider)
              .write(StorageKeys.accessToken, 'expired-for-testing');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access token spoiled. Now tap Log out.'),
              ),
            );
          }
        } else if (value == 'age') {
          await ref
              .read(offlineAccessProvider.notifier)
              .debugAge(const Duration(days: 8));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offline access aged by 8 days.'),
              ),
            );
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
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
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Log out'),
            ],
          ),
        ),
        // DEBUG ONLY: remove once these are verified.
        if (kDebugMode)
          const PopupMenuItem(
            value: 'expire',
            child: Row(
              children: [
                Icon(Icons.bug_report_outlined, size: 20),
                SizedBox(width: 12),
                Text('Debug: expire token'),
              ],
            ),
          ),
        if (kDebugMode)
          const PopupMenuItem(
            value: 'age',
            child: Row(
              children: [
                Icon(Icons.bug_report_outlined, size: 20),
                SizedBox(width: 12),
                Text('Debug: age access 8d'),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person_outline, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}