import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/app_card.dart';
import '../auth/domain/user_role.dart';
import '../auth/presentation/current_role_provider.dart';
import '../messaging/data/messaging_providers.dart';
import 'assessments_repository.dart';
import 'presentation/assessment_detail_page.dart';
import 'presentation/conduct_assessment_page.dart';

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

class AssessmentsPage extends ConsumerStatefulWidget {
  const AssessmentsPage({
    super.key,
    this.menteeId,
    this.menteeName,
    this.facilityId,
    this.cycleId,
    this.thematicAreaId,
  });

  /// Set by a mentor; null when a mentee views her own.
  final int? menteeId;
  final String? menteeName;
  final int? facilityId;
  final int? cycleId;
  final int? thematicAreaId;

  @override
  ConsumerState<AssessmentsPage> createState() => _AssessmentsPageState();
}

class _AssessmentsPageState extends ConsumerState<AssessmentsPage> {
  String _selectedFilter = 'all';



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = ref.watch(currentRoleProvider);
    final isMentor = widget.menteeId != null || userRole == UserRole.mentor;

    final myIdAsync = ref.watch(currentUserIdProvider);
    final myId = myIdAsync.isLoading ? null : myIdAsync.value;
    final targetId = widget.menteeId ?? myId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isMentor
              ? 'Assessments: ' + (widget.menteeName ?? 'Mentee')
              : 'My Competency Assessments',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: isMentor && widget.menteeId != null
          ? FloatingActionButton.extended(
              heroTag: 'conduct_assessment_fab',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text('Conduct Evaluation'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ConductAssessmentPage(
                      menteeId: widget.menteeId!,
                      menteeName: widget.menteeName ?? 'Mentee',
                      facilityId: widget.facilityId,
                      cycleId: widget.cycleId,
                      thematicAreaId: widget.thematicAreaId,
                    ),
                  ),
                );
              },
            )
          : null,
      body: targetId == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(assessmentsProvider(targetId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                        const SizedBox(height: 12),
                        const Text('Could not load assessments.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(assessmentsProvider(targetId)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (allList) {
                  final filtered = allList.where((a) {
                    if (_selectedFilter == 'finalized') return a.isFinalized;
                    if (_selectedFilter == 'draft') return !a.isFinalized;
                    return true;
                  }).toList();

                  final finalizedCount = allList.where((a) => a.isFinalized).length;
                  final avgScore = allList.isEmpty
                      ? 0.0
                      : allList.fold<double>(0.0, (s, a) => s + a.displayScore) / allList.length;

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(assessmentsProvider(targetId)),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      children: [
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                context,
                                label: 'Total',
                                value: allList.length.toString(),
                                color: AppColors.primary,
                              ),
                              Container(height: 32, width: 1, color: theme.dividerColor),
                              _statItem(
                                context,
                                label: 'Finalized',
                                value: finalizedCount.toString(),
                                color: Colors.green.shade600,
                              ),
                              Container(height: 32, width: 1, color: theme.dividerColor),
                              _statItem(
                                context,
                                label: 'Avg Score',
                                value: avgScore.round().toString() + '%',
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _filterChip('all', 'All (' + allList.length.toString() + ')'),
                            const SizedBox(width: 8),
                            _filterChip('finalized', 'Finalized (' + finalizedCount.toString() + ')'),
                            const SizedBox(width: 8),
                            _filterChip('draft', 'In Review (' + (allList.length - finalizedCount).toString() + ')'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 56,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilter == 'all'
                                      ? 'No competency evaluations yet.'
                                      : 'No ' + _selectedFilter + ' assessments found.',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isMentor
                                      ? 'Tap "Conduct Evaluation" below to evaluate and sign off clinical competencies.'
                                      : 'Formal clinical competency sign-offs from your mentor will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final item in filtered)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AssessmentCard(
                                assessment: item,
                                isMentor: isMentor,
                                onRefresh: () => ref.invalidate(assessmentsProvider(targetId)),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? AppColors.primary : null,
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _statItem(BuildContext context, {required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.assessment,
    required this.isMentor,
    required this.onRefresh,
  });

  final Assessment assessment;
  final bool isMentor;
  final VoidCallback onRefresh;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'finalized':
      case 'reviewed':
        return Colors.green.shade600;
      case 'in_review':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'finalized':
        return 'Finalized Sign-off';
      case 'reviewed':
        return 'Reviewed';
      case 'in_review':
        return 'In Review';
      default:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    final theme = Theme.of(context);
    final statusCol = _statusColor(a.status);

    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => AssessmentDetailPage(assessment: a),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.area,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusCol.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _statusLabel(a.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusCol,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _date(a.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Text(
                  a.criteriaScores.length.toString() + ' criteria evaluated',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  a.displayScore.round().toString() + '%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: a.isFinalized ? Colors.green.shade700 : AppColors.primary,
                  ),
                ),
              ],
            ),
            if (a.feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"' + a.feedback + '"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      a.prerequisitesMet ? Icons.check_circle_outline : Icons.pending_outlined,
                      size: 14,
                      color: a.prerequisitesMet ? Colors.green.shade600 : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a.prerequisitesMet ? 'Prerequisites met' : 'Prerequisites pending',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'View details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
