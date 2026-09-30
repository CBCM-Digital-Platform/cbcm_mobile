import 'package:flutter/material.dart';
import 'app_button.dart';

class AppButtonRow extends StatelessWidget {
  const AppButtonRow({
    super.key,
    required this.secondary,
    required this.primary,
  });

  final AppButton secondary; // always on the left
  final AppButton primary; // always on the right

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 12),
        Expanded(child: primary),
      ],
    );
  }
}