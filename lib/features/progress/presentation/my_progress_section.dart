import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../messaging/data/messaging_providers.dart';
import 'mentee_progress_card.dart';

/// The signed-in mentee's own competencies.
class MyProgressSection extends ConsumerWidget {
  const MyProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(currentUserIdProvider);
    final id = a.isLoading ? null : a.value;
    if (id == null) return const SizedBox.shrink();
    return MenteeProgressCard(menteeId: id);
  }
}