import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../mentor/mentees/data/assigned_mentees_provider.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';

/// Shows the modal bottom sheet for a mentor to record a clinical logbook entry.
Future<void> showRecordLogbookSheet(
  BuildContext context, {
  int? initialMenteeId,
  String? menteeName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => RecordLogbookSheet(
      initialMenteeId: initialMenteeId,
      initialMenteeName: menteeName,
    ),
  );
}

class RecordLogbookSheet extends ConsumerStatefulWidget {
  const RecordLogbookSheet({
    super.key,
    this.initialMenteeId,
    this.initialMenteeName,
  });

  final int? initialMenteeId;
  final String? initialMenteeName;

  @override
  ConsumerState<RecordLogbookSheet> createState() => _RecordLogbookSheetState();
}

class _RecordLogbookSheetState extends ConsumerState<RecordLogbookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _procedureController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedMenteeId;
  int _selectedThematicAreaId = 1;
  String _selectedRole = 'performed';
  String _selectedSupervision = 'direct';
  String _selectedOutcome = 'successful';
  DateTime _datePerformed = DateTime.now();

  bool _submitting = false;
  List<Map<String, dynamic>> _thematicAreas = [];

  static const _commonProcedures = [
    'Active Management of Third Stage of Labor (AMTSL)',
    'Neonatal Resuscitation (Golden Minute)',
    'Partograph Monitoring & Labor Progress',
    'Pre-eclampsia Management (MgSO4 Loading Dose)',
    'Postpartum Hemorrhage (PPH) Management',
    'Manual Removal of Placenta',
    'Newborn Thermal Care & KMC Initiation',
    'Vacuum-assisted Vaginal Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMenteeId = widget.initialMenteeId;
    _loadMetadata();
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _patientIdController.dispose();
    _feedbackController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final areas = await ref.read(logbookRepositoryProvider).getThematicAreas();
    if (mounted) {
      setState(() {
        _thematicAreas = areas;
        if (areas.isNotEmpty) {
          _selectedThematicAreaId = areas.first['id'] as int;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMenteeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mentee.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final repo = ref.read(logbookRepositoryProvider);
      final cycleId = await repo.getActiveCycleId();

      final req = CreateLogbookRequest(
        menteeId: _selectedMenteeId!,
        cycleId: cycleId,
        thematicAreaId: _selectedThematicAreaId,
        procedureName: _procedureController.text.trim(),
        patientIdentifier: _patientIdController.text.trim().isEmpty
            ? null
            : _patientIdController.text.trim(),
        datePerformed: _datePerformed,
        role: _selectedRole,
        supervisionLevel: _selectedSupervision,
        outcome: _selectedOutcome,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        mentorFeedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      );

      await repo.createEntry(req);

      ref.invalidate(menteeLogbookEntriesProvider);
      ref.invalidate(mentorMenteeLogbookEntriesProvider(_selectedMenteeId!));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Clinical logbook entry recorded successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record logbook: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menteesAsync = ref.watch(assignedMenteesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Clinical Logbook',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record a supervised procedure for your mentee',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Mentee Selector
              Text('Mentee', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              menteesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading mentees: $e'),
                data: (mentees) {
                  if (mentees.isEmpty) {
                    return const Text('No assigned mentees found.');
                  }
                  if (_selectedMenteeId == null && mentees.isNotEmpty) {
                    _selectedMenteeId = mentees.first.id;
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedMenteeId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      for (final m in mentees)
                        DropdownMenuItem<int>(
                          value: m.id,
                          child: Text(m.fullName),
                        ),
                    ],
                    onChanged: (val) => setState(() => _selectedMenteeId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Procedure / Clinical Event
              Text('Clinical Procedure / Event', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _procedureController,
                decoration: InputDecoration(
                  hintText: 'e.g. Active Management of Third Stage of Labor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter the procedure name' : null,
              ),
              const SizedBox(height: 8),

              // Quick suggestion chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in _commonProcedures.take(4))
                    ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _procedureController.text = p),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Thematic Area
              if (_thematicAreas.isNotEmpty) ...[
                Text('Thematic Area', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _selectedThematicAreaId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: [
                    for (final a in _thematicAreas)
                      DropdownMenuItem<int>(
                        value: a['id'] as int,
                        child: Text(a['name'].toString()),
                      ),
                  ],
                  onChanged: (val) => setState(() => _selectedThematicAreaId = val ?? 1),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Role & Supervision Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mentee Role', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'performed', child: Text('Performed')),
                            DropdownMenuItem(value: 'assisted', child: Text('Assisted')),
                            DropdownMenuItem(value: 'observed', child: Text('Observed')),
                          ],
                          onChanged: (v) => setState(() => _selectedRole = v ?? 'performed'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supervision', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSupervision,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'direct', child: Text('Direct (Bedside)')),
                            DropdownMenuItem(value: 'indirect', child: Text('Indirect')),
                            DropdownMenuItem(value: 'independent', child: Text('Independent')),
                          ],
                          onChanged: (v) => setState(() => _selectedSupervision = v ?? 'direct'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Outcome & Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outcome', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedOutcome,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'successful', child: Text('Successful')),
                            DropdownMenuItem(value: 'partially_successful', child: Text('Partially')),
                            DropdownMenuItem(value: 'complicated', child: Text('Complicated')),
                          ],
                          onChanged: (v) => setState(() => _selectedOutcome = v ?? 'successful'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date Performed', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            '${_datePerformed.year}-${_datePerformed.month.toString().padLeft(2, '0')}-${_datePerformed.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _datePerformed,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _datePerformed = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Mentor Clinical Feedback
              Text('Mentor Clinical Feedback', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Good adherence to aseptic technique. Timely administration.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _submitting ? 'Recording Logbook...' : 'Record & Approve Entry',
                  onPressed: _submitting ? null : _submit,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
