import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/progress_repository.dart';

/// A mentee's competency scores. Used by the mentor (mentee details) and the
/// mentee (Learn tab).
class MenteeProgressCard extends ConsumerWidget {
  const MenteeProgressCard({super.key, required this.menteeId});
  final int menteeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(menteeProgressProvider(menteeId));
    final names =
        ref.watch(thematicAreaNamesProvider).value ?? const <int, String>{};

    return AppCard(
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Row(
          children: [
            Expanded(
              child: Text(e is ApiException
                  ? e.error.message
                  : 'Could not load progress.'),
            ),
            TextButton(
              onPressed: () => ref.invalidate(menteeProgressProvider(menteeId)),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (p) {
          final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
          final trackColor = Theme.of(context).dividerColor;

          if (p.competencies.isEmpty) {
            return Text('No data yet', style: TextStyle(color: mutedColor));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Average score: ${p.average!.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final c in p.competencies) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        names[c.thematicAreaId] ?? 'Area #${c.thematicAreaId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${c.score.round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (c.score / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: trackColor,
                    color: AppColors.primary,
                  ),
                ),
                if (c.level.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${c.level[0].toUpperCase()}${c.level.substring(1)}',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}