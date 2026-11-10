import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';

class MentorLogbookDetailPage extends ConsumerStatefulWidget {
  const MentorLogbookDetailPage({super.key, required this.entryId});

  final int entryId;

  @override
  ConsumerState<MentorLogbookDetailPage> createState() => _MentorLogbookDetailPageState();
}

class _MentorLogbookDetailPageState extends ConsumerState<MentorLogbookDetailPage> {
  bool _acting = false;
  String? _serverError;

  Future<void> _approve(LogbookEntry entry) async {
    final feedbackController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Approve Clinical Procedure'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify and sign off "${entry.procedureName}" for ${entry.menteeName ?? 'this mentee'}?'),
              const SizedBox(height: 14),
              TextField(
                controller: feedbackController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Feedback / Commendation (Optional)',
                  hintText: 'e.g. Correct procedure technique observed.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _acting = true;
      _serverError = null;
    });

    try {
      final repo = ref.read(logbookRepositoryProvider);
      final feedback = feedbackController.text.trim();
      await repo.approveEntry(
        entry.id,
        mentorFeedback: feedback.isEmpty ? null : feedback,
      );

      _refreshAll(entry);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Logbook entry approved and verified successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _acting = false;
          _serverError = e is ApiException ? e.error.message : e.toString();
        });
      }
    }
  }

  Future<void> _requestRevision(LogbookEntry entry) async {
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Request Revision'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter required corrections for "${entry.procedureName}":'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Revision instructions *',
                    hintText: 'e.g. Please document specific complications and blood loss volume.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please provide revision details.' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Send to Mentee'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _acting = true;
      _serverError = null;
    });

    try {
      final repo = ref.read(logbookRepositoryProvider);
      final comment = commentController.text.trim();

      await repo.requestRevision(
        entry.id,
        comment: comment,
      );

      _refreshAll(entry);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Revision request sent to mentee.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _acting = false;
          _serverError = e is ApiException ? e.error.message : e.toString();
        });
      }
    }
  }

  void _refreshAll(LogbookEntry entry) {
    ref.invalidate(logbookDetailProvider(widget.entryId));
    ref.invalidate(mentorAllLogbookEntriesProvider);
    ref.invalidate(pendingMentorLogbookEntriesProvider);
    if (entry.menteeId != null) {
      ref.invalidate(mentorMenteeLogbookEntriesProvider(entry.menteeId!));
    }
    ref.invalidate(menteeLogbookEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entryAsync = ref.watch(logbookDetailProvider(widget.entryId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Review Mentee Logbook'),
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
                onPressed: () => ref.invalidate(logbookDetailProvider(widget.entryId)),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Server Error Banner
              if (_serverError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Mentee & Status Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface : const Color(0xFF1B431E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFACC15),
                      child: Text(
                        (entry.menteeName?.isNotEmpty == true ? entry.menteeName![0] : 'M').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.menteeName ?? 'Mentee Submission',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${entry.displayStatus}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Procedure Details Card
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

              // 3. Clinical Notes Card
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mentee Clinical Notes & Case Reflections',
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

              // 4. Previous Revision comment if any
              if (entry.isRevisionRequested &&
                  entry.revisionReason != null &&
                  entry.revisionReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Revision Request:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.revisionReason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Actions for submitted entry
              if (entry.isSubmitted) ...[
                if (_acting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Approve & Verify Procedure',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _approve(entry),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Request Revision',
                      variant: AppButtonVariant.secondary,
                      icon: const Icon(Icons.assignment_return_outlined),
                      onPressed: () => _requestRevision(entry),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ],
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

