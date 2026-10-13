import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/theme/colors.dart';
import 'logout_dialog.dart';

/// The profile avatar shown in the top bar of both Mentee and Mentor.
/// Add future account items (e.g. "Profile", "Settings") to the menu here.
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      onSelected: (value) async {
        if (value == 'logout') {
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
        }
      },
      itemBuilder: (_) => [
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
        // DEBUG ONLY: remove once refresh is verified.
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