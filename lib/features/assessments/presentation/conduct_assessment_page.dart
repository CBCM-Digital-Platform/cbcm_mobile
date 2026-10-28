import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../messaging/data/messaging_providers.dart';
import '../assessments_repository.dart';

class ConductAssessmentPage extends ConsumerStatefulWidget {
  const ConductAssessmentPage({
    super.key,
    required this.menteeId,
    required this.menteeName,
    this.facilityId,
    this.cycleId,
    this.thematicAreaId,
  });

  final int menteeId;
  final String menteeName;
  final int? facilityId;
  final int? cycleId;
  final int? thematicAreaId;

  @override
  ConsumerState<ConductAssessmentPage> createState() => _ConductAssessmentPageState();
}

class _ConductAssessmentPageState extends ConsumerState<ConductAssessmentPage> {
  late String _selectedArea = kAssessmentAreas.first;
  int? _selectedAreaId;
  bool _prerequisitesMet = true;

  final Map<String, int> _criteriaScores = {
    for (final c in kAssessmentCriteria) c: 75,
  };

  final Map<String, bool> _checklist = {
    for (final item in kAssessmentChecklist) item: true,
  };

  final TextEditingController _theoryScoreController = TextEditingController(text: '85');
  final TextEditingController _feedbackController = TextEditingController();

  bool _saving = false;
  List<Map<String, dynamic>> _cycleThematicAreas = [];

  @override
  void initState() {
    super.initState();
    _selectedAreaId = widget.thematicAreaId;
    _loadThematicAreas();
  }

  @override
  void dispose() {
    _theoryScoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadThematicAreas() async {
    final cycleId = widget.cycleId != null && widget.cycleId! > 0 ? widget.cycleId! : 1;
    try {
      final repo = ref.read(assessmentsRepositoryProvider);
      final areas = await repo.getThematicAreasForCycle(cycleId);
      if (mounted && areas.isNotEmpty) {
        setState(() {
          _cycleThematicAreas = areas;
          if (_selectedAreaId != null) {
            final match = areas.firstWhere(
              (a) => a['id'] == _selectedAreaId,
              orElse: () => areas.first,
            );
            _selectedArea = (match['name'] ?? match['code'] ?? _selectedArea).toString();
          } else {
            _selectedAreaId = (areas.first['id'] as num?)?.toInt();
            _selectedArea = (areas.first['name'] ?? areas.first['code'] ?? _selectedArea).toString();
          }
        });
      }
    } catch (_) {
      // Static fallback
    }
  }

  double get _averageCriteriaScore {
    if (_criteriaScores.isEmpty) return 0.0;
    final total = _criteriaScores.values.fold<int>(0, (s, v) => s + v);
    return total / _criteriaScores.length;
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return AppColors.primary;
    return Colors.orange.shade700;
  }

  Future<void> _submitEvaluation({required bool finalizeSignOff}) async {
    if (finalizeSignOff) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Competency Sign-off'),
          content: Text(
            'Are you sure you want to finalize and sign off this evaluation for ${widget.menteeName}?\n\n'
            'This action permanently records the clinical competency sign-off.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Review again'),
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
    }

    setState(() => _saving = true);

    try {
      final mentorId = await ref.read(currentUserIdProvider.future) ?? 0;
      final facilityId = widget.facilityId ?? 1;
      final cycleId = widget.cycleId ?? 1;

      final criteriaList = _criteriaScores.entries
          .map((e) => AssessmentCriterionScore(criterion: e.key, score: e.value.toDouble()))
          .toList();

      final checklistList = _checklist.entries
          .map((e) => AssessmentChecklistItem(item: e.key, checked: e.value))
          .toList();

      double? theoryScore;
      final rawTheory = _theoryScoreController.text.trim();
      if (rawTheory.isNotEmpty) {
        theoryScore = double.tryParse(rawTheory);
      }

      await ref.read(assessmentsRepositoryProvider).conductEvaluation(
            menteeId: widget.menteeId,
            menteeName: widget.menteeName,
            mentorId: mentorId,
            facilityId: facilityId,
            cycleId: cycleId,
            thematicAreaId: _selectedAreaId,
            thematicAreaName: _selectedArea,
            prerequisitesMet: _prerequisitesMet,
            criteriaScores: criteriaList,
            checklistItems: checklistList,
            theoryScore: theoryScore,
            feedback: _feedbackController.text.trim(),
            finalizeSignOff: finalizeSignOff,
          );

      ref.invalidate(assessmentsProvider(widget.menteeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalizeSignOff
                  ? 'Competency evaluation signed off & finalized!'
                  : 'Draft assessment saved successfully.',
            ),
            backgroundColor: finalizeSignOff ? Colors.green.shade700 : null,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save assessment: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Conduct Evaluation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    widget.menteeName.isNotEmpty ? widget.menteeName[0].toUpperCase() : 'M',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.menteeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Formal Clinical Competency Evaluation',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_averageCriteriaScore.round()}% avg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thematic Area Selection
          _buildSectionHeader(context, 'Thematic Area'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: _cycleThematicAreas.isNotEmpty
                ? DropdownButtonFormField<int>(
                    initialValue: _selectedAreaId ?? (_cycleThematicAreas.first['id'] as num).toInt(),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Thematic Area',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final a in _cycleThematicAreas)
                        DropdownMenuItem<int>(
                          value: (a['id'] as num).toInt(),
                          child: Text((a['name'] ?? a['code'] ?? 'Area #${a['id']}').toString()),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedAreaId = val;
                          final match = _cycleThematicAreas.firstWhere((a) => a['id'] == val);
                          _selectedArea = (match['name'] ?? match['code'] ?? '').toString();
                        });
                      }
                    },
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Thematic Area',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final a in kAssessmentAreas)
                        DropdownMenuItem(value: a, child: Text(a)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedArea = val);
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Prerequisites Toggle
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                'Clinical Prerequisites Verified',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Mentee has completed required clinical hours and core training.',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
              value: _prerequisitesMet,
              onChanged: (val) => setState(() => _prerequisitesMet = val),
            ),
          ),
          const SizedBox(height: 20),

          // Criteria Scoring Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'Core Competency Criteria'),
              Text(
                'Avg: ${_averageCriteriaScore.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _scoreColor(_averageCriteriaScore.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final c in _criteriaScores.keys) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _scoreColor(_criteriaScores[c]!).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_criteriaScores[c]}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(_criteriaScores[c]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _criteriaScores[c]!.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: _scoreColor(_criteriaScores[c]!),
                    onChanged: (v) => setState(() => _criteriaScores[c] = v.round()),
                  ),
                  if (c != _criteriaScores.keys.last) const Divider(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Clinical Checklist Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'Procedural Checklist'),
              TextButton(
                onPressed: () {
                  final allChecked = _checklist.values.every((v) => v);
                  setState(() {
                    for (final k in _checklist.keys) {
                      _checklist[k] = !allChecked;
                    }
                  });
                },
                child: Text(_checklist.values.every((v) => v) ? 'Uncheck all' : 'Check all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final item in _checklist.keys)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    activeColor: AppColors.primary,
                    title: Text(item, style: const TextStyle(fontSize: 13)),
                    value: _checklist[item],
                    onChanged: (val) => setState(() => _checklist[item] = val ?? false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theory Score Section
          _buildSectionHeader(context, 'Theory Exam Evaluation (Optional)'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _theoryScoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Theory Score (%)',
                      hintText: 'e.g. 85',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 14),
                Builder(
                  builder: (_) {
                    final score = double.tryParse(_theoryScoreController.text) ?? 0.0;
                    final passed = score >= 80;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: passed
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: passed ? Colors.green.shade300 : Colors.orange.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            passed ? Icons.check_circle : Icons.info_outline,
                            size: 18,
                            color: passed ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            passed ? 'Pass (>= 80%)' : 'Below 80%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green.shade800 : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mentor Observations & Feedback
          _buildSectionHeader(context, 'Mentor Feedback & Clinical Recommendations'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Provide specific feedback, strengths observed, and areas for clinical improvement...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          AppButtonRow(
            secondary: AppButton(
              label: 'Save Draft',
              variant: AppButtonVariant.secondary,
              onPressed: _saving ? null : () => _submitEvaluation(finalizeSignOff: false),
            ),
            primary: AppButton(
              label: _saving ? 'Processing...' : 'Sign-off & Finalize',
              variant: AppButtonVariant.primary,
              onPressed: _saving ? null : () => _submitEvaluation(finalizeSignOff: true),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
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
