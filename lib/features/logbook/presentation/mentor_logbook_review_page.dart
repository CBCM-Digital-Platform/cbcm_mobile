import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';
import 'mentor_logbook_detail_page.dart';

class MentorLogbookReviewPage extends ConsumerStatefulWidget {
  const MentorLogbookReviewPage({
    super.key,
    this.menteeId,
    this.menteeName,
  });

  final int? menteeId;
  final String? menteeName;

  @override
  ConsumerState<MentorLogbookReviewPage> createState() => _MentorLogbookReviewPageState();
}

class _MentorLogbookReviewPageState extends ConsumerState<MentorLogbookReviewPage> {
  String _selectedFilter = 'submitted';

  @override
  void initState() {
    super.initState();
    if (widget.menteeId != null) {
      _selectedFilter = 'all';
    }
  }

  Future<void> _approveEntry(LogbookEntry entry) async {
    final feedbackController = TextEditingController();
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Approve Clinical Logbook'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign off and verify procedure: "${entry.procedureName}"?'),
              const SizedBox(height: 14),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Mentor Feedback / Notes (Optional)',
                  hintText: 'e.g. Well handled, observed correct AMTSL timing.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            child: const Text('Approve & Verify'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      final feedback = feedbackController.text.trim();
      await ref.read(logbookRepositoryProvider).approveEntry(
            entry.id,
            mentorFeedback: feedback.isEmpty ? null : feedback,
          );

      _refreshProviders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Logbook entry approved and verified successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _requestRevision(LogbookEntry entry) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Request Logbook Revision'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Specify corrections for "${entry.procedureName}":'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Revision instructions *',
                    hintText: 'e.g. Please document specific complications and blood loss volume.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      await ref.read(logbookRepositoryProvider).requestRevision(
            entry.id,
            revisionReason: reasonController.text.trim(),
          );

      _refreshProviders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Revision request sent to mentee.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request revision: $e')),
        );
      }
    }
  }

  void _refreshProviders() {
    ref.invalidate(mentorAllLogbookEntriesProvider);
    ref.invalidate(pendingMentorLogbookEntriesProvider);
    if (widget.menteeId != null) {
      ref.invalidate(mentorMenteeLogbookEntriesProvider(widget.menteeId!));
    }
    ref.invalidate(menteeLogbookEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final AsyncValue<List<LogbookEntry>> entriesAsync = widget.menteeId != null
        ? ref.watch(mentorMenteeLogbookEntriesProvider(widget.menteeId!))
        : ref.watch(mentorAllLogbookEntriesProvider);

    final title = widget.menteeName != null
        ? '${widget.menteeName}\'s Logbook'
        : 'Mentee Logbook Review';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load logbook entries'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _refreshProviders,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (entries) {
          final submittedCount = entries.where((e) => e.isSubmitted).length;
          final approvedCount = entries.where((e) => e.isApproved).length;
          final revisionCount = entries.where((e) => e.isNeedsRevision).length;

          final filtered = entries.where((e) {
            if (_selectedFilter == 'all') return true;
            if (_selectedFilter == 'submitted') return e.isSubmitted;
            if (_selectedFilter == 'approved') return e.isApproved;
            if (_selectedFilter == 'needs_revision') return e.isNeedsRevision;
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => _refreshProviders(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedSurface : const Color(0xFF1B431E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check, color: Color(0xFFFACC15), size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.menteeName != null
                                  ? 'CLINICAL SIGN-OFF: ${widget.menteeName!.toUpperCase()}'
                                  : 'PENDING CLINICAL SIGN-OFFS',
                              style: const TextStyle(
                                color: Color(0xFFFACC15),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$submittedCount submissions awaiting your verification',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Pending Review ($submittedCount)',
                        selected: _selectedFilter == 'submitted',
                        color: AppColors.primary,
                        onSelected: () => setState(() => _selectedFilter = 'submitted'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Approved ($approvedCount)',
                        selected: _selectedFilter == 'approved',
                        color: const Color(0xFF16A34A),
                        onSelected: () => setState(() => _selectedFilter = 'approved'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Revision Requested ($revisionCount)',
                        selected: _selectedFilter == 'needs_revision',
                        color: AppColors.warning,
                        onSelected: () => setState(() => _selectedFilter = 'needs_revision'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'All (${entries.length})',
                        selected: _selectedFilter == 'all',
                        onSelected: () => setState(() => _selectedFilter = 'all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'submitted'
                              ? 'All caught up! No pending submissions.'
                              : 'No $_selectedFilter logbooks found.',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  for (final item in filtered)
                    _MentorLogbookCard(
                      item: item,
                      onApprove: () => _approveEntry(item),
                      onRequestRevision: () => _requestRevision(item),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: activeColor.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected
            ? activeColor
            : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _MentorLogbookCard extends StatelessWidget {
  const _MentorLogbookCard({
    required this.item,
    required this.onApprove,
    required this.onRequestRevision,
  });

  final LogbookEntry item;
  final VoidCallback onApprove;
  final VoidCallback onRequestRevision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateStr = item.datePerformed != null
        ? '${item.datePerformed!.year}-${item.datePerformed!.month.toString().padLeft(2, '0')}-${item.datePerformed!.day.toString().padLeft(2, '0')}'
        : (item.createdAt != null
            ? '${item.createdAt!.year}-${item.createdAt!.month.toString().padLeft(2, '0')}-${item.createdAt!.day.toString().padLeft(2, '0')}'
            : 'Recently');

    final statusColor = item.statusColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MentorLogbookDetailPage(entryId: item.id),
            ),
          );
        },
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mentee Name Row (if present)
              if (item.menteeName != null && item.menteeName!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      item.menteeName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              // Top row: date, hours, and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                        ),
                      ),
                      if (item.hours != null) ...[
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: theme.dividerColor)),
                        const SizedBox(width: 8),
                        Text(
                          '${item.hours} hrs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.displayStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // Procedure Title
            Text(
              item.procedureName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tags row: Role, Supervision, Outcome, Patient
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag(
                  label: item.displayRole,
                  color: AppColors.primary,
                ),
                _Tag(
                  label: '${item.displaySupervision} Supervision',
                  color: const Color(0xFF2563EB),
                ),
                _Tag(
                  label: item.displayOutcome,
                  color: item.outcomeColor(context),
                ),
                if (item.patientIdentifier != null && item.patientIdentifier!.isNotEmpty)
                  _Tag(
                    label: item.patientIdentifier!,
                    color: Colors.grey.shade700,
                  ),
              ],
            ),

            // Clinical Notes
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface.withValues(alpha: 0.6) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mentee Clinical Notes:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Revision banner if already requested
            if (item.isNeedsRevision && item.revisionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Awaiting mentee updates: "${item.revisionReason}"',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Sign-off Actions for submitted entries
            if (item.isSubmitted) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.assignment_return_outlined, size: 16),
                      label: const Text('Request Revision'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                      ),
                      onPressed: onRequestRevision,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve & Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

