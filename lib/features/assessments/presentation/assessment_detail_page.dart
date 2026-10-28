import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/current_role_provider.dart';
import '../assessments_repository.dart';

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  const AssessmentDetailPage({
    super.key,
    required this.assessment,
  });

  final Assessment assessment;

  @override
  ConsumerState<AssessmentDetailPage> createState() => _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage> {
  late Assessment _current = widget.assessment;
  bool _finalizing = false;

  Future<void> _finalize() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Competency Sign-off'),
        content: Text(
          'Are you sure you want to officially sign off and finalize this clinical competency assessment for ${_current.menteeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Sign-off'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _finalizing = true);
    try {
      final updated = await ref
          .read(assessmentsRepositoryProvider)
          .finalize(_current.id);

      ref.invalidate(assessmentsProvider(_current.menteeId));

      if (mounted) {
        setState(() => _current = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Competency evaluation signed off & finalized!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not finalize: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _finalizing = false);
    }
  }

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
        return 'Admin Reviewed';
      case 'in_review':
        return 'In Review';
      default:
        return 'Draft Evaluation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMentor = ref.watch(currentRoleProvider) == UserRole.mentor;
    final a = _current;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(a.area, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score and Status Hero
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: a.isFinalized
                        ? Colors.green.shade50
                        : AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: a.isFinalized ? Colors.green.shade400 : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${a.displayScore.round()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: a.isFinalized ? Colors.green.shade800 : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(a.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(a.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(a.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.menteeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Evaluated ${_fmtDate(a.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview Details
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _detailRow(context, 'Thematic Area', a.area),
                const Divider(height: 16),
                _detailRow(context, 'Prerequisites', a.prerequisitesMet ? 'Verified & Met' : 'Pending'),
                if (a.theoryScore != null) ...[
                  const Divider(height: 16),
                  _detailRow(
                    context,
                    'Theory Exam',
                    '${a.theoryScore!.round()}% (${a.theoryPassed == true ? "Passed" : "Did not pass"})',
                  ),
                ],
                if (a.mentorName != null && a.mentorName!.isNotEmpty) ...[
                  const Divider(height: 16),
                  _detailRow(context, 'Mentor', a.mentorName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Criteria breakdown
          _buildSectionHeader(context, 'Competency Criteria Breakdown'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (a.criteriaScores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No individual criteria scores recorded.'),
                  )
                else
                  for (final c in a.criteriaScores) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.criterion,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                        Text(
                          '${c.score.round()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.score / 100.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          c.score >= 80 ? Colors.green.shade600 : AppColors.primary,
                        ),
                      ),
                    ),
                    if (c != a.criteriaScores.last) const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Checklist breakdown
          _buildSectionHeader(context, 'Procedural Checklist Items'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (a.checklistItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No checklist items logged.'),
                  )
                else
                  for (final item in a.checklistItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.checked ? Icons.check_circle : Icons.cancel_outlined,
                            size: 18,
                            color: item.checked ? Colors.green.shade600 : Colors.red.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.item,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.checked ? null : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feedback notes
          if (a.feedback.isNotEmpty) ...[
            _buildSectionHeader(context, 'Mentor Clinical Feedback'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                a.feedback,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Sign-off button if not finalized
          if (!a.isFinalized && isMentor) ...[
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _finalizing ? 'Finalizing Sign-off...' : 'Sign-off & Finalize Competency',
                variant: AppButtonVariant.primary,
                onPressed: _finalizing ? null : _finalize,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
