import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';
import 'record_logbook_sheet.dart';
import 'edit_logbook_sheet.dart';
import 'mentee_logbook_detail_page.dart';

class MenteeLogbookPage extends ConsumerStatefulWidget {
  const MenteeLogbookPage({super.key});

  @override
  ConsumerState<MenteeLogbookPage> createState() => _MenteeLogbookPageState();
}

class _MenteeLogbookPageState extends ConsumerState<MenteeLogbookPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entriesAsync = ref.watch(menteeLogbookEntriesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Clinical Logbook'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'record_logbook_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Record Procedure'),
        onPressed: () => showRecordLogbookSheet(context),
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
                onPressed: () => ref.invalidate(menteeLogbookEntriesProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (entries) {
          final approvedCount = entries.where((e) => e.isApproved).length;
          final submittedCount = entries.where((e) => e.isSubmitted).length;
          final revisionCount = entries.where((e) => e.isNeedsRevision).length;
          final draftCount = entries.where((e) => e.isDraft).length;

          final filtered = entries.where((e) {
            if (_selectedFilter == 'all') return true;
            if (_selectedFilter == 'approved') return e.isApproved;
            if (_selectedFilter == 'submitted') return e.isSubmitted;
            if (_selectedFilter == 'needs_revision') return e.isNeedsRevision;
            if (_selectedFilter == 'draft') return e.isDraft;
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(menteeLogbookEntriesProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // 1. Summary Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedSurface : const Color(0xFF1B431E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.menu_book, color: Color(0xFFFACC15), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'CLINICAL EXPERIENCE LOGBOOK',
                            style: TextStyle(
                              color: Color(0xFFFACC15),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatColumn(
                            count: '${entries.length}',
                            label: 'Total Logs',
                            color: Colors.white,
                          ),
                          _StatColumn(
                            count: '$approvedCount',
                            label: 'Approved',
                            color: const Color(0xFF4ADE80),
                          ),
                          _StatColumn(
                            count: '$submittedCount',
                            label: 'Under Review',
                            color: const Color(0xFF60A5FA),
                          ),
                          _StatColumn(
                            count: '$revisionCount',
                            label: 'Needs Rev.',
                            color: const Color(0xFFFACC15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${entries.length})',
                        selected: _selectedFilter == 'all',
                        onSelected: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Needs Revision ($revisionCount)',
                        selected: _selectedFilter == 'needs_revision',
                        color: AppColors.warning,
                        onSelected: () => setState(() => _selectedFilter = 'needs_revision'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Under Review ($submittedCount)',
                        selected: _selectedFilter == 'submitted',
                        onSelected: () => setState(() => _selectedFilter = 'submitted'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Approved ($approvedCount)',
                        selected: _selectedFilter == 'approved',
                        onSelected: () => setState(() => _selectedFilter = 'approved'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Drafts ($draftCount)',
                        selected: _selectedFilter == 'draft',
                        onSelected: () => setState(() => _selectedFilter = 'draft'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Entries List or Empty State
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'No clinical entries yet'
                              : 'No $_selectedFilter entries found',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Record patient encounters and clinical procedures performed in facility. Your mentor will review and sign them off.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Record First Procedure'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => showRecordLogbookSheet(context),
                        ),
                      ],
                    ),
                  )
                else
                  for (final item in filtered) _LogbookEntryCard(item: item),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.count, required this.label, required this.color});
  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
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

class _LogbookEntryCard extends ConsumerWidget {
  const _LogbookEntryCard({required this.item});
  final LogbookEntry item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              builder: (_) => MenteeLogbookDetailPage(entryId: item.id),
            ),
          );
        },
        child: AppCard(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: date, hours & status badge
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
                  child: Row(
                    children: [
                      Icon(
                        item.isApproved
                            ? Icons.check_circle
                            : (item.isNeedsRevision
                                ? Icons.warning_amber_rounded
                                : (item.isSubmitted ? Icons.hourglass_top : Icons.edit_note)),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Procedure Title
            Text(
              item.procedureName,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Tags row: Role, Supervision, Outcome
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

            // Clinical Notes preview
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                ),
              ),
            ],

            // Mentor Feedback / Revision Request Alert Banner
            if (item.isNeedsRevision && item.revisionReason != null && item.revisionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.feedback_outlined, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Revision Requested by Mentor:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.revisionReason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit & Resubmit to Mentor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                  onPressed: () => showEditLogbookSheet(context, entry: item),
                ),
              ),
            ],

            // Draft actions
            if (item.isDraft) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Draft'),
                      onPressed: () => showRecordLogbookSheet(context, existingEntry: item),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(logbookRepositoryProvider).submitEntry(item.id);
                          ref.invalidate(menteeLogbookEntriesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logbook submitted to mentor!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submit failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            // Mentor Approval Feedback box
            if (item.isApproved && item.mentorFeedback != null && item.mentorFeedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkElevatedSurface.withValues(alpha: 0.6)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(
                      color: Color(0xFF16A34A),
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mentor Sign-off: "${item.mentorFeedback!}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
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
