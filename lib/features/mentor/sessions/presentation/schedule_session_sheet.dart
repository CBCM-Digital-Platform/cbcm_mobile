import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../data/sessions_repository_provider.dart';

final mentorAssignmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final mentorIdStr = await storage.read(StorageKeys.userId);
  final mentorId = int.tryParse(mentorIdStr ?? '');
  if (mentorId == null) return [];
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(ApiEndpoints.mentorAssignments(mentorId));
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
  } catch (e) {
    debugPrint('[mentorAssignmentsProvider] Error: $e');
  }
  return [];
});

class ScheduleSessionSheet extends ConsumerStatefulWidget {
  const ScheduleSessionSheet({
    super.key,
    this.initialMenteeName,
    this.initialMenteeId,
    this.initialAssignmentId,
  });

  final String? initialMenteeName;
  final int? initialMenteeId;
  final int? initialAssignmentId;

  static Future<void> show(
    BuildContext context, {
    String? menteeName,
    int? menteeId,
    int? assignmentId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleSessionSheet(
        initialMenteeName: menteeName,
        initialMenteeId: menteeId,
        initialAssignmentId: assignmentId,
      ),
    );
  }

  @override
  ConsumerState<ScheduleSessionSheet> createState() =>
      _ScheduleSessionSheetState();
}

class _ScheduleSessionSheetState extends ConsumerState<ScheduleSessionSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09:30 AM';
  String _sessionMode = 'virtual'; // 'virtual' or 'in_person'
  String _selectedTopic = '1:1 Mentoring';
  int? _selectedAssignmentId;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _morningTimes = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '11:30 AM',
  ];

  final List<String> _afternoonTimes = [
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '04:00 PM',
  ];

  final List<String> _topics = [
    '1:1 Mentoring',
    'Clinical Assessment',
    'Skills Review',
    'Fetal Monitoring',
    'Patient Communication',
    'Postnatal Care Review',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Session',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  Text(
                    widget.initialMenteeName != null
                        ? 'With ${widget.initialMenteeName}'
                        : 'Select date and time for clinical supervision',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // 0. Mentee Selection (if multiple assignments exist)
                ref.watch(mentorAssignmentsProvider).when(
                      data: (assignments) {
                        if (assignments.isEmpty) return const SizedBox.shrink();
                        _selectedAssignmentId ??=
                            widget.initialAssignmentId ?? (assignments.first['id'] as int?);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(Icons.person_outline, 'Select Mentee'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedAssignmentId,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: assignments.map((a) {
                                final id = a['id'] as int? ?? 1;
                                final mentee = a['mentee'] as Map? ?? {};
                                final name = (mentee['full_name'] ?? mentee['name'] ?? 'Mentee #$id').toString();
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedAssignmentId = val);
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                // 1. Date selection
                _buildSectionHeader(Icons.calendar_month_outlined, 'Select Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Icon(Icons.edit_calendar, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Available times
                _buildSectionHeader(Icons.access_time_outlined, 'Available Times'),
                const SizedBox(height: 8),
                Text('Morning',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _morningTimes
                      .map((t) => _buildTimeChip(t, _selectedTime == t))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Afternoon',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _afternoonTimes
                      .map((t) => _buildTimeChip(t, _selectedTime == t))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // 3. Session Type (In-person vs Virtual)
                _buildSectionHeader(Icons.videocam_outlined, 'Session Type'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeOption(
                        title: 'Virtual (Jitsi)',
                        icon: Icons.video_call_outlined,
                        isSelected: _sessionMode == 'virtual',
                        onTap: () => setState(() => _sessionMode = 'virtual'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeOption(
                        title: 'In-Person',
                        icon: Icons.person_pin_circle_outlined,
                        isSelected: _sessionMode == 'in_person',
                        onTap: () => setState(() => _sessionMode = 'in_person'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Topic / Competency
                _buildSectionHeader(Icons.assignment_outlined, 'Session Topic / Competency'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTopic,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _topics
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTopic = val);
                  },
                ),
                const SizedBox(height: 20),

                // 5. Notes
                _buildSectionHeader(Icons.notes_outlined, 'Clinical Notes & Preparation'),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Briefly describe what you would like to focus on or review...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _isSubmitting ? 'Scheduling...' : 'Confirm Schedule',
              onPressed: _isSubmitting ? () {} : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time, bool isSelected) {
    return ChoiceChip(
      label: Text(time),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTime = time),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  (int, int) _parseTime(String time) {
    try {
      final parts = time.trim().split(' ');
      final hm = parts[0].split(':');
      var h = int.parse(hm[0]);
      final m = int.parse(hm[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && h < 12) h += 12;
      if (!isPm && h == 12) h = 0;
      return (h, m);
    } catch (_) {
      return (9, 30);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final (hour, minute) = _parseTime(_selectedTime);
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    ).toUtc();

    final assignmentId = _selectedAssignmentId ?? widget.initialAssignmentId ?? 1;

    final sessionPayload = <String, dynamic>{
      'assignment_id': assignmentId,
      'mode': _sessionMode,
      'scheduled_at': scheduledDateTime.toIso8601String(),
      'duration_minutes': 45,
      'session_goals': _selectedTopic,
      if (_notesController.text.trim().isNotEmpty)
        'preparation_notes': _notesController.text.trim(),
      'status': 'scheduled',
    };

    try {
      await ref.read(sessionsRepositoryProvider).createSession(sessionPayload);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session scheduled for ${_formatDate(_selectedDate)} at $_selectedTime!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
