import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_routes.dart';
import '../data/notifications_repository.dart';

/// The bell in the top bar, with an unread-count badge.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).value ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        await context.push(AppRoutes.notifications);
        if (context.mounted) ref.invalidate(unreadCountProvider);
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(Icons.notifications_none, color: color),
      ),
    );
  }
}
