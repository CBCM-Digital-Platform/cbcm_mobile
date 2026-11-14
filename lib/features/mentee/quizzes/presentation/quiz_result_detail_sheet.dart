import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../domain/quiz_models.dart';

class QuizResultDetailSheet extends StatelessWidget {
  const QuizResultDetailSheet({
    super.key,
    required this.result,
    required this.passScore,
  });

  final QuizResultItem result;
  final double passScore;

  static Future<void> show(
    BuildContext context, {
    required QuizResultItem result,
    required double passScore,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizResultDetailSheet(
        result: result,
        passScore: passScore,
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPassed = result.passed;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attempt #${result.attemptNumber} Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Score Summary Hero Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                        size: 56,
                        color: isPassed ? AppColors.primary : AppColors.destructive,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${result.score.toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPassed ? AppColors.primary : AppColors.destructive,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.destructive.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPassed ? 'Passed' : 'Failed',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPassed ? AppColors.primary : AppColors.destructive,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Required pass score: ${passScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timing & Status Information
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Status',
                        value: result.status.toUpperCase(),
                      ),
                      const Divider(height: 16),
                      _DetailRow(
                        label: 'Completed at',
                        value: _formatDateTime(result.completedAt),
                      ),
                      if (result.startedAt != null) ...[
                        const Divider(height: 16),
                        _DetailRow(
                          label: 'Started at',
                          value: _formatDateTime(result.startedAt),
                        ),
                      ],
                    ],
                  ),
                ),

                // Per-question review (only if the response includes it)
                if (result.hasQuestionReview) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Per-Question Review',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < result.perQuestionReview.length; i++) ...[
                    _QuestionReviewCard(
                      number: i + 1,
                      review: result.perQuestionReview[i],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.number, required this.review});
  final int number;
  final QuizQuestionReview review;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCorrect = review.isCorrect;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q$number',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              if (isCorrect != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCorrect ? 'Correct' : 'Incorrect',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? AppColors.primary : AppColors.destructive,
                    ),
                  ),
                ),
            ],
          ),
          if (review.prompt != null && review.prompt!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.prompt!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
          if (review.selectedOptionText != null) ...[
            const SizedBox(height: 6),
            Text(
              'Your Answer: ${review.selectedOptionText}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
          if (review.explanation != null && review.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Explanation: ${review.explanation}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

