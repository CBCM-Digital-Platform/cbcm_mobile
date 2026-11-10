import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../data/logbook_providers.dart';
import '../domain/logbook_entry.dart';

Future<bool?> showEditLogbookSheet(
  BuildContext context, {
  required LogbookEntry entry,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => EditLogbookSheet(entry: entry),
  );
}

class EditLogbookSheet extends ConsumerStatefulWidget {
  const EditLogbookSheet({super.key, required this.entry});

  final LogbookEntry entry;

  @override
  ConsumerState<EditLogbookSheet> createState() => _EditLogbookSheetState();
}

class _EditLogbookSheetState extends ConsumerState<EditLogbookSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _procedureController;
  late final TextEditingController _patientIdController;
  late final TextEditingController _hoursController;
  late final TextEditingController _notesController;

  int? _selectedThematicAreaId;
  late String _selectedRole;
  late String _selectedSupervision;
  late String _selectedOutcome;
  late DateTime _datePerformed;

  bool _submitting = false;
  String? _serverError;
  List<Map<String, dynamic>> _thematicAreas = [];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _procedureController = TextEditingController(text: e.procedureName);
    _patientIdController = TextEditingController(text: e.patientIdentifier ?? '');
    _hoursController = TextEditingController(text: (e.hours ?? 1.0).toString());
    _notesController = TextEditingController(text: e.notes ?? '');
    _selectedThematicAreaId = e.thematicAreaId;
    _selectedRole = e.role;
    _selectedSupervision = e.supervisionLevel;
    _selectedOutcome = e.outcome;
    _datePerformed = e.datePerformed ?? DateTime.now();

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
    final cycleId = widget.entry.cycleId ?? await repo.getActiveCycleId();
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

  Future<void> _saveAndResubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    try {
      final hours = double.tryParse(_hoursController.text.trim()) ?? widget.entry.hours;

      // 1. Compute delta of ONLY changed fields
      final delta = widget.entry.buildPatchDelta(
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

      final repo = ref.read(logbookRepositoryProvider);

      // 2. PATCH changed fields (if any)
      if (delta.isNotEmpty) {
        await repo.patchEntry(widget.entry.id, delta);
      }

      // 3. Resubmit to mentor review
      await repo.submitEntry(widget.entry.id);

      // 4. Refresh lists and detail
      ref.invalidate(logbookDetailProvider(widget.entry.id));
      ref.invalidate(menteeLogbookEntriesProvider);
      ref.invalidate(pendingMentorLogbookEntriesProvider);
      if (widget.entry.menteeId != null) {
        ref.invalidate(mentorMenteeLogbookEntriesProvider(widget.entry.menteeId!));
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _serverError = e is ApiException ? e.error.message : e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                        'Edit & Resubmit Logbook',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Changes are PATCHed and submitted to mentor',
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

              // Server Error Banner if any
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

              // Revision banner
              if (widget.entry.revisionReason != null && widget.entry.revisionReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.feedback_outlined, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mentor Revision Request:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.entry.revisionReason!,
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

              // Procedure Name
              Text(
                'Procedure Name *',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _procedureController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Procedure name is required' : null,
              ),
              const SizedBox(height: 16),

              // Thematic Area
              Text(
                'Thematic Area',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_thematicAreas.isNotEmpty)
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
                ),
              const SizedBox(height: 16),

              // Date Performed & Hours
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

              // Role
              Text(
                'Clinical Role',
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

              // Supervision Level
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

              // Outcome
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

              // Patient Identifier
              Text(
                'Patient Identifier (Optional / Anonymized)',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _patientIdController,
                decoration: InputDecoration(
                  hintText: 'e.g. PT-402',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Clinical Notes
              Text(
                'Clinical Notes & Case Reflections',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add clinical details, findings, complications or corrections...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              if (_submitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Resubmit for Mentor Review',
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _saveAndResubmit,
                  ),
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

