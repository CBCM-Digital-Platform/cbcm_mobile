import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../data/logbook_providers.dart';
import 'edit_logbook_sheet.dart';

class MenteeLogbookDetailPage extends ConsumerWidget {
  const MenteeLogbookDetailPage({super.key, required this.entryId});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entryAsync = ref.watch(logbookDetailProvider(entryId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Logbook Entry Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading entry: $e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(logbookDetailProvider(entryId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (entry) {
          final statusColor = entry.statusColor(context);
          final dateStr = entry.datePerformed != null
              ? '${entry.datePerformed!.year}-${entry.datePerformed!.month.toString().padLeft(2, '0')}-${entry.datePerformed!.day.toString().padLeft(2, '0')}'
              : 'N/A';

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(logbookDetailProvider(entryId).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.isApproved
                            ? Icons.check_circle
                            : (entry.isRevisionRequested
                                ? Icons.warning_amber_rounded
                                : (entry.isSubmitted ? Icons.hourglass_top : Icons.edit_note)),
                        size: 28,
                        color: statusColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.displayStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.isApproved
                                  ? 'Verified and signed off by mentor'
                                  : (entry.isRevisionRequested
                                      ? 'Action required: mentor requested revisions'
                                      : (entry.isSubmitted
                                          ? 'Submitted to mentor and awaiting review'
                                          : 'Draft entry — not yet submitted')),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Revision comment banner (if revision requested)
                if (entry.isRevisionRequested &&
                    entry.revisionReason != null &&
                    entry.revisionReason!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.feedback_outlined, color: AppColors.warning, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mentor Revision Comment',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.revisionReason!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Mentor Feedback banner (if approved)
                if (entry.isApproved &&
                    entry.mentorFeedback != null &&
                    entry.mentorFeedback!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.verified, color: Color(0xFF16A34A), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mentor Sign-off Feedback',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${entry.mentorFeedback!}"',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Procedure Details Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.procedureName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (entry.thematicAreaName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.thematicAreaName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      _detailRow('Date Performed', dateStr),
                      if (entry.hours != null) _detailRow('Hours Spent', '${entry.hours} hours'),
                      _detailRow('Clinical Role', entry.displayRole),
                      _detailRow('Supervision Level', '${entry.displaySupervision} Supervision'),
                      _detailRow('Clinical Outcome', entry.displayOutcome),
                      if (entry.patientIdentifier != null && entry.patientIdentifier!.isNotEmpty)
                        _detailRow('Patient Identifier', entry.patientIdentifier!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Clinical Notes & Reflections Card
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Notes & Case Reflections',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. Action Button for revision requested
                if (entry.isRevisionRequested) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Edit & Resubmit',
                      icon: const Icon(Icons.edit_note),
                      onPressed: () async {
                        final result = await showEditLogbookSheet(
                          context,
                          entry: entry,
                        );
                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Text('Logbook resubmitted for mentor review!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

