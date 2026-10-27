import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_button_row.dart';
import '../messaging/data/messaging_providers.dart';
import 'assessments_repository.dart';

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

class AssessmentsPage extends ConsumerWidget {
  const AssessmentsPage({super.key, this.menteeId, this.menteeName});

  /// Set by a mentor; null when a mentee views her own.
  final int? menteeId;
  final String? menteeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserIdProvider).value;
    final id = menteeId ?? myId;
    final isMentor = menteeId != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isMentor ? 'Assessments: $menteeName' : 'My Assessments',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: isMentor
          ? FloatingActionButton.extended(
              heroTag: 'new_assessment',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New assessment'),
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => AssessmentFormPage(
                      menteeId: menteeId!, menteeName: menteeName ?? 'Mentee'),
                ),
              ),
            )
          : null,
      body: id == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(assessmentsProvider(id)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Could not load assessments.')),
                data: (list) => list.isEmpty
                    ? const Center(child: Text('No assessments yet.'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        children: [for (final a in list) _Tile(a: a)],
                      ),
              ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.a});
  final Assessment a;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(a.area, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${_date(a.createdAt)} • demo data'),
        trailing: Text('${a.score.round()}%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in a.criteria.entries)
            Row(children: [
              Expanded(child: Text(e.key)),
              Text('${e.value}%'),
            ]),
          const SizedBox(height: 8),
          for (final e in a.checklist.entries)
            Row(children: [
              Icon(e.value ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(e.key)),
            ]),
          if (a.feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Feedback: ${a.feedback}'),
          ],
        ],
      ),
    );
  }
}

class AssessmentFormPage extends ConsumerStatefulWidget {
  const AssessmentFormPage({
    super.key,
    required this.menteeId,
    required this.menteeName,
  });
  final int menteeId;
  final String menteeName;

  @override
  ConsumerState<AssessmentFormPage> createState() => _FormState();
}

class _FormState extends ConsumerState<AssessmentFormPage> {
  String _area = kAssessmentAreas.first;
  final _scores = {for (final c in kAssessmentCriteria) c: 70};
  final _checks = {for (final c in kAssessmentChecklist) c: false};
  final _feedback = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _finalize() async {
    setState(() => _saving = true);
    try {
      final mentorId = await ref.read(currentUserIdProvider.future);
      await ref.read(assessmentRepositoryProvider).finalize(
            menteeId: widget.menteeId,
            menteeName: widget.menteeName,
            mentorId: mentorId ?? 0,
            area: _area,
            criteria: Map.of(_scores),
            checklist: Map.of(_checks),
            feedback: _feedback.text.trim(),
          );
      ref.invalidate(assessmentsProvider(widget.menteeId));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('New assessment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _area,
            isExpanded: true,
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkElevatedSurface
                : Colors.white,
            decoration: const InputDecoration(labelText: 'Thematic area'),
            items: [
              for (final a in kAssessmentAreas)
                DropdownMenuItem(value: a, child: Text(a)),
            ],
            onChanged: (v) => setState(() => _area = v ?? _area),
          ),
          const SizedBox(height: 16),
          const Text('Criteria', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final c in kAssessmentCriteria) ...[
            Row(children: [
              Expanded(child: Text(c)),
              Text('${_scores[c]}%'),
            ]),
            Slider(
              value: _scores[c]!.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _scores[c] = v.round()),
            ),
          ],
          const SizedBox(height: 8),
          const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final c in kAssessmentChecklist)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: Text(c),
              value: _checks[c],
              onChanged: (v) => setState(() => _checks[c] = v ?? false),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedback,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Feedback for the mentee'),
          ),
          const SizedBox(height: 20),
          AppButtonRow(
            secondary: AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(),
            ),
            primary: AppButton(
              label: _saving ? 'Saving...' : 'Finalize',
              onPressed: _saving ? null : _finalize,
            ),
          ),
        ],
      ),
    );
  }
}
