import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';

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
          final performedCount =
              entries.where((e) => e.role == 'performed').length;
          final assistedCount =
              entries.where((e) => e.role == 'assisted').length;
          final observedCount =
              entries.where((e) => e.role == 'observed').length;

          final filtered = entries.where((e) {
            if (_selectedFilter == 'all') return true;
            return e.role == _selectedFilter;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(menteeLogbookEntriesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
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
                          Icon(Icons.verified_outlined, color: Color(0xFFFACC15), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'MENTOR-VERIFIED PROCEDURES',
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
                            count: '$performedCount',
                            label: 'Performed',
                            color: const Color(0xFF4ADE80),
                          ),
                          _StatColumn(
                            count: '$assistedCount',
                            label: 'Assisted',
                            color: const Color(0xFF60A5FA),
                          ),
                          _StatColumn(
                            count: '$observedCount',
                            label: 'Observed',
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
                        label: 'Performed ($performedCount)',
                        selected: _selectedFilter == 'performed',
                        onSelected: () => setState(() => _selectedFilter = 'performed'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Assisted ($assistedCount)',
                        selected: _selectedFilter == 'assisted',
                        onSelected: () => setState(() => _selectedFilter = 'assisted'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Observed ($observedCount)',
                        selected: _selectedFilter == 'observed',
                        onSelected: () => setState(() => _selectedFilter = 'observed'),
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
                          'No entries found',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'When your mentor logs procedures and clinical sessions with you, their verified entries will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
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
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _LogbookEntryCard extends StatelessWidget {
  const _LogbookEntryCard({required this.item});
  final LogbookEntry item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateStr = item.datePerformed != null
        ? '${item.datePerformed!.year}-${item.datePerformed!.month.toString().padLeft(2, '0')}-${item.datePerformed!.day.toString().padLeft(2, '0')}'
        : (item.createdAt != null
            ? '${item.createdAt!.year}-${item.createdAt!.month.toString().padLeft(2, '0')}-${item.createdAt!.day.toString().padLeft(2, '0')}'
            : 'Recently');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: date & approved badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
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
              ],
            ),

            // Mentor Feedback box
            if (item.mentorFeedback != null && item.mentorFeedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkElevatedSurface.withValues(alpha: 0.6)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.mentorFeedback!,
                        style: TextStyle(
                          fontSize: 12.5,
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
