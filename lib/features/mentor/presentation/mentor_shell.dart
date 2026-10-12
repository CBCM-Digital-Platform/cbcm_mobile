import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_bottom_nav_shell.dart';

class MentorShell extends StatelessWidget {
  const MentorShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavShell(
      navigationShell: navigationShell,
      items: const [
        NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
        NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Mentees'),
        NavItem(icon: Icons.event_note_outlined, selectedIcon: Icons.event_note, label: 'Sessions'),
        NavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Message'),
        NavItem(icon: Icons.psychology_outlined, selectedIcon: Icons.psychology, label: 'Ask AI'),
      ],
    );
  }
}