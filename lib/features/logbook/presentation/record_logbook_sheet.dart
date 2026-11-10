import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../messaging/data/messaging_providers.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';

/// Shows the modal bottom sheet for a mentee to record or edit a clinical logbook entry.
Future<void> showRecordLogbookSheet(
  BuildContext context, {
  LogbookEntry? existingEntry,
  int? menteeId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => RecordLogbookSheet(
      existingEntry: existingEntry,
      menteeId: menteeId,
    ),
  );
}

class RecordLogbookSheet extends ConsumerStatefulWidget {
  const RecordLogbookSheet({
    super.key,
    this.existingEntry,
    this.menteeId,
  });

  final LogbookEntry? existingEntry;
  final int? menteeId;

  @override
  ConsumerState<RecordLogbookSheet> createState() => _RecordLogbookSheetState();
}

class _RecordLogbookSheetState extends ConsumerState<RecordLogbookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _procedureController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _hoursController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  int? _selectedThematicAreaId;
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
    'Kangaroo Mother Care (KMC)',
    'Essential Newborn Care',
    'Management of Eclampsia',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    if (e != null) {
      _procedureController.text = e.procedureName;
      _patientIdController.text = e.patientIdentifier ?? '';
      _hoursController.text = (e.hours ?? 1.0).toString();
      _notesController.text = e.notes ?? '';
      _selectedThematicAreaId = e.thematicAreaId;
      _selectedRole = e.role;
      _selectedSupervision = e.supervisionLevel;
      _selectedOutcome = e.outcome;
      if (e.datePerformed != null) _datePerformed = e.datePerformed!;
    }
    _loadThematicAreas();
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _patientIdController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadThematicAreas() async {
    final repo = ref.read(logbookRepositoryProvider);
    final cycleId = widget.existingEntry?.cycleId ?? await repo.getActiveCycleId();
    List<Map<String, dynamic>> areas = [];
    if (cycleId != null) {
      areas = await repo.getThematicAreasForCycle(cycleId);
    }
    if (areas.isEmpty) {
      areas = await repo.getThematicAreas();
    }
    if (!mounted) return;

    setState(() {
      _thematicAreas = areas;
      if (_selectedThematicAreaId == null && areas.isNotEmpty) {
        _selectedThematicAreaId = areas.first['id'] as int?;
      }
    });
  }

  Future<void> _submit({required bool submitImmediately}) async {
    if (!_formKey.currentState!.validate()) return;

    final resolvedMenteeId = widget.menteeId ??
        widget.existingEntry?.menteeId ??
        ref.read(currentUserIdProvider).value;

    if (resolvedMenteeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine mentee ID. Please sign in again.')),
      );
      return;
    }

    if (_selectedThematicAreaId == null && _thematicAreas.isNotEmpty) {
      _selectedThematicAreaId = _thematicAreas.first['id'] as int?;
    }

    if (_selectedThematicAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thematic area.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final repo = ref.read(logbookRepositoryProvider);
      final hours = double.tryParse(_hoursController.text.trim()) ?? 1.0;

      if (widget.existingEntry != null) {
        final delta = widget.existingEntry!.buildPatchDelta(
          newProcedureName: _procedureController.text.trim(),
          newThematicAreaId: _selectedThematicAreaId,
          newHours: hours,
          newOutcome: _selectedOutcome,
          newRole: _selectedRole,
          newSupervisionLevel: _selectedSupervision,
          newPatientIdentifier: _patientIdController.text.trim(),
          newDatePerformed: _datePerformed,
          newNotes: _notesController.text.trim(),
        );
        if (delta.isNotEmpty) {
          await repo.patchEntry(widget.existingEntry!.id, delta);
        }
        if (submitImmediately) {
          await repo.submitEntry(widget.existingEntry!.id);
        }
      } else {
        final cycleId = await repo.getActiveCycleId();
        final req = CreateLogbookRequest(
          menteeId: resolvedMenteeId,
          cycleId: cycleId,
          thematicAreaId: _selectedThematicAreaId!,
          procedureName: _procedureController.text.trim(),
          patientIdentifier: _patientIdController.text.trim().isEmpty
              ? null
              : _patientIdController.text.trim(),
          datePerformed: _datePerformed,
          role: _selectedRole,
          supervisionLevel: _selectedSupervision,
          outcome: _selectedOutcome,
          hours: hours,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          submitImmediately: submitImmediately,
        );
        await repo.createEntry(req);
      }

      ref.invalidate(menteeLogbookEntriesProvider);
      if (widget.menteeId != null) {
        ref.invalidate(mentorMenteeLogbookEntriesProvider(widget.menteeId!));
      }
      ref.invalidate(pendingMentorLogbookEntriesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              submitImmediately
                  ? 'Procedure submitted to mentor for review!'
                  : 'Logbook entry saved as draft.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        final errorMsg = e is ApiException ? e.error.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.existingEntry != null;
    final isRevision = widget.existingEntry?.isNeedsRevision ?? false;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Clinical Logbook' : 'Record Clinical Procedure',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'Update procedure details and resubmit for mentor sign-off'
                              : 'Log a patient procedure or clinical case for mentor review',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Revision banner if needed
              if (isRevision && widget.existingEntry?.revisionReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.feedback_outlined, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mentor Feedback / Revision Request:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.existingEntry!.revisionReason!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Procedure Name
              Text(
                'Clinical Procedure / Case *',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _procedureController,
                decoration: InputDecoration(
                  hintText: 'e.g. Neonatal Resuscitation, AMTSL...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Procedure name is required' : null,
              ),
              const SizedBox(height: 8),

              // Suggestions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _commonProcedures.map((proc) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(proc, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.grey.shade100,
                        onPressed: () {
                          setState(() {
                            _procedureController.text = proc;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Thematic Area
              Text(
                'Thematic Area *',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_thematicAreas.isEmpty)
                Text(
                  'Loading thematic areas...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selectedThematicAreaId ?? (_thematicAreas.isNotEmpty ? _thematicAreas.first['id'] as int : null),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _thematicAreas.map((a) {
                    return DropdownMenuItem<int>(
                      value: a['id'] as int,
                      child: Text(
                        a['name']?.toString() ?? 'Thematic Area',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedThematicAreaId = val),
                  validator: (val) => val == null ? 'Select a thematic area' : null,
                ),
              const SizedBox(height: 16),

              // 3. Date Performed & Hours Spent
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final dateField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Performed',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _datePerformed,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _datePerformed = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            '${_datePerformed.year}-${_datePerformed.month.toString().padLeft(2, '0')}-${_datePerformed.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );

                  final hoursField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hours Spent',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed <= 0) return 'Valid hours';
                          return null;
                        },
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        dateField,
                        const SizedBox(height: 12),
                        hoursField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dateField),
                      const SizedBox(width: 12),
                      Expanded(child: hoursField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4. Clinical Role
              Text(
                'My Role in Procedure',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _roleChip('performed', 'Performed', Icons.check_circle_outline),
                  _roleChip('assisted', 'Assisted', Icons.people_outline),
                  _roleChip('observed', 'Observed', Icons.visibility_outlined),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Supervision Level
              Text(
                'Supervision Level',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _supervisionChip('direct', 'Direct'),
                  _supervisionChip('indirect', 'Indirect'),
                  _supervisionChip('independent', 'Independent'),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Outcome
              Text(
                'Clinical Outcome',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _outcomeChip('successful', 'Successful', const Color(0xFF16A34A)),
                  _outcomeChip('partially_successful', 'Partially Successful', AppColors.warning),
                  _outcomeChip('unsuccessful', 'Unsuccessful', Colors.red.shade700),
                  _outcomeChip('complicated', 'Complicated', Colors.purple.shade700),
                ],
              ),
              const SizedBox(height: 16),

              // 7. Patient Identifier
              Text(
                'Patient Identifier (Optional / Anonymized)',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _patientIdController,
                decoration: InputDecoration(
                  hintText: 'e.g. PT-309, Bed 4...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.person_pin_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Clinical Notes & Case Reflections
              Text(
                'Clinical Notes & Case Reflections',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe patient presentation, steps performed, findings, challenges faced, or key lessons learned...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              if (_submitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: isEdit ? 'Submit Revisions to Mentor' : 'Submit to Mentor for Sign-off',
                        icon: const Icon(Icons.send_outlined),
                        onPressed: () => _submit(submitImmediately: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Save Draft',
                        variant: AppButtonVariant.secondary,
                        icon: const Icon(Icons.save_outlined),
                        onPressed: () => _submit(submitImmediately: false),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String val, String label, IconData icon) {
    final selected = _selectedRole == val;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : AppColors.primary,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedRole = val),
    );
  }

  Widget _supervisionChip(String val, String label) {
    final selected = _selectedSupervision == val;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedSupervision = val),
    );
  }

  Widget _outcomeChip(String val, String label, Color color) {
    final selected = _selectedOutcome == val;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : color,
        ),
      ),
      selected: selected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() => _selectedOutcome = val),
    );
  }
}
