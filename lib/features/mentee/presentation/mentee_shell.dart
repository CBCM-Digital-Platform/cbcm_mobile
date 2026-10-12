import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_bottom_nav_shell.dart';

class MenteeShell extends StatelessWidget {
  const MenteeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavShell(
      navigationShell: navigationShell,
      items: const [
        NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
        NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school, label: 'Learn'),
        NavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Message'),
        NavItem(icon: Icons.smart_toy_outlined, selectedIcon: Icons.smart_toy, label: 'AI Assist'),
        NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Mentor'),
      ],
    );
  }
}