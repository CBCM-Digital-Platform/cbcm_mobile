import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/current_role_provider.dart';
import '../../features/auth/presentation/logout_dialog.dart';
import '../../features/profile/data/user_profile_repository.dart';
import '../../routing/app_routes.dart';
import '../constants/app_info.dart';
import '../theme/colors.dart';

/// Role-aware side navigation drawer (hamburger menu) providing direct access
/// to key features, profile, settings, and the logout action.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final isMentor = role == UserRole.mentor;
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = profileAsync.value;
    final fullName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : (isMentor ? 'Mentor' : 'Mentee');
    final email = profile?.email ?? '';

    final initials = fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drawer Header
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.onPrimary,
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isMentor ? 'Mentor' : 'Mentee',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Home Dashboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(isMentor ? AppRoutes.mentorDashboard : AppRoutes.menteeDashboard);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_outlined,
                    title: isMentor ? 'Review Clinical Logbooks' : 'Clinical Logbook',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(isMentor ? AppRoutes.mentorLogbookReview : AppRoutes.menteeLogbook);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    title: 'Assessments',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.menteeAssessments);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.folder_shared_outlined,
                    title: 'Clinical Resources',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.menteeResources);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.verified_outlined,
                    title: 'Certificates',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.menteeCertificates);
                    },
                  ),

                  // Mentee-specific shortcuts
                  if (!isMentor) ...[
                    _DrawerItem(
                      icon: Icons.school_outlined,
                      title: 'Curriculum & Modules',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.menteeLearn);
                      },
                    ),
                  ],

                  // Mentor-specific shortcuts
                  if (isMentor) ...[
                    _DrawerItem(
                      icon: Icons.people_outline,
                      title: 'My Mentees',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.mentorMentees);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.event_note_outlined,
                      title: 'Clinical Sessions',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.mentorSessions);
                      },
                    ),
                  ],

                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.profile);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.settings);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.help);
                    },
                  ),

                  const Divider(height: 24),

                  // Prominent Log Out item
                  _DrawerItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    color: AppColors.destructive,
                    onTap: () => confirmAndLogout(context, ref),
                  ),
                ],
              ),
            ),

            // Footer branding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${AppInfo.appName} • Clinical Mentorship',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 14.5,
          fontWeight: color != null ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}

