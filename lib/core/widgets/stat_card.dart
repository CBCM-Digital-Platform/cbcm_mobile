import 'package:flutter/material.dart';
import 'app_card.dart';
import '../theme/colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? accentColor; // left border strip
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: mutedColor)),
              if (icon != null) Icon(icon, color: iconColor ?? mutedColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          if (actionLabel != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              child: Text('$actionLabel →',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );

    if (accentColor == null) return card;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accentColor!, width: 4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: card,
    );
  }
}