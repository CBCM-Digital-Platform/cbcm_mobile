import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'theme_toggle_button.dart';
import '../../features/notifications/presentation/notification_bell.dart';
import '../../features/auth/presentation/profile_menu_button.dart';

/// Standard, reusable top navigation AppBar for top-level shell and feature pages.
/// Ensures consistent hamburger drawer menu, brand title, and action icons
/// (Theme toggle, Notification bell, and Profile avatar) across both Mentor and Mentee apps.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showDrawer = true,
    this.leading,
    this.actions,
    this.elevation = 0,
    this.bottom,
  });

  final String title;
  final Widget? titleWidget;
  final bool showDrawer;
  final Widget? leading;
  final List<Widget>? actions;
  final double elevation;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showDrawer) {
      leadingWidget = Builder(
        builder: (c) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open navigation',
          onPressed: () => Scaffold.of(c).openDrawer(),
        ),
      );
    }

    final defaultActions = actions ??
        const [
          ThemeToggleButton(),
          NotificationBell(),
          ProfileMenuButton(),
        ];

    return AppBar(
      leading: leadingWidget,
      title: titleWidget ??
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: AppColors.primary,
      elevation: elevation,
      actions: defaultActions,
      bottom: bottom,
    );
  }
}

