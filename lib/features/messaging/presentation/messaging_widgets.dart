import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../domain/message_models.dart';

/// Circle with the user's initials. (Profile photos can be added later
/// once avatar URLs are confirmed to be reachable.)
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 24});

  final MessageUser? user;
  final double radius;

  static const _palette = [
    Color(0xFF8E3B5E),
    Color(0xFF2F6B3F),
    Color(0xFF3B5E8E),
    Color(0xFF8E6B3B),
    Color(0xFF5E3B8E),
  ];

  @override
  Widget build(BuildContext context) {
    final u = user;
    if (u == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.group_outlined, color: Colors.white, size: radius),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _palette[u.id.abs() % _palette.length],
      child: Text(
        u.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

class MessagingErrorView extends StatelessWidget {
  const MessagingErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}