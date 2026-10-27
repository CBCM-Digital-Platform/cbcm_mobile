import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/current_role_provider.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../data/assignments_provider.dart';
import '../data/sessions_repository_provider.dart';
import '../domain/sessions_repository.dart';
import 'mentor_sessions_page.dart';

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
  static const _durationMinutes = 45;

  /// Shown only if the server's availability cannot be read.
  static const _standardSlots = [
    TimeSlot(hour: 9, minute: 0),
    TimeSlot(hour: 9, minute: 30),
    TimeSlot(hour: 10, minute: 0),
    TimeSlot(hour: 11, minute: 30),
    TimeSlot(hour: 13, minute: 30),
    TimeSlot(hour: 14, minute: 0),
    TimeSlot(hour: 14, minute: 30),
    TimeSlot(hour: 16, minute: 0),
  ];

  static const _topics = [
    '1:1 Mentoring',
    'Clinical Assessment',
    'Skills Review',
    'Fetal Monitoring',
    'Patient Communication',
    'Postnatal Care Review',
  ];

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  String _sessionMode = 'virtual'; // 'virtual' or 'in_person'
  String _selectedTopic = _topics.first;
  int? _selectedAssignmentId;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  AvailableTimes? _times;
  bool _loadingTimes = false;
  int _requestId = 0;
  String? _loadedKey;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  int? _idOf(Map<String, dynamic> a) => (a['id'] as num?)?.toInt();

  int? _effectiveAssignmentId(List<Map<String, dynamic>> assignments) {
    final ids = <int>{
      for (final a in assignments)
        if (_idOf(a) != null) _idOf(a)!,
    };
    if (ids.isEmpty) return null;
    if (_selectedAssignmentId != null && ids.contains(_selectedAssignmentId)) {
      return _selectedAssignmentId;
    }
    if (widget.initialAssignmentId != null &&
        ids.contains(widget.initialAssignmentId)) {
      return widget.initialAssignmentId;
    }
    if (widget.initialMenteeId != null) {
      for (final a in assignments) {
        if ((a['mentee_id'] as num?)?.toInt() == widget.initialMenteeId) {
          return _idOf(a);
        }
      }
    }
    return ids.first;
  }

  Future<void> _loadTimes(int assignmentId) async {
    final request = ++_requestId;
    setState(() {
      _loadingTimes = true;
      _times = null;
      _selectedSlot = null;
    });

    final result = await ref.read(sessionsRepositoryProvider).getAvailableTimes(
          assignmentId: assignmentId,
          date: _selectedDate,
          durationMinutes: _durationMinutes,
        );

    if (!mounted || request != _requestId) return; // a newer request won
    setState(() {
      _times = result;
      _loadingTimes = false;
    });
  }

  List<TimeSlot> _visibleSlots() {
    final times = _times;
    if (times == null) return const [];
    final base = times.checked ? times.slots : _standardSlots;

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    return [
      for (final s in base)
        if (!isToday || s.minutesOfDay > nowMinutes) s,
    ];
  }

  String _partnerLabel(Map<String, dynamic> a, UserRole? role) {
    final isMentor = role == UserRole.mentor;
    final nested = a[isMentor ? 'mentee' : 'mentor'];
    final id = (a[isMentor ? 'mentee_id' : 'mentor_id'] as num?)?.toInt();

    if (nested is Map) {
      final name = (nested['full_name'] ?? nested['fullName'] ?? nested['name'])
          ?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    if (id != null) {
      for (final c in ref.read(contactsProvider)) {
        if (c.id == id && c.fullName.isNotEmpty && c.fullName != 'Unknown') {
          return c.fullName;
        }
      }
    }
    return '${isMentor ? 'Mentee' : 'Mentor'} #${id ?? '?'}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final role = ref.watch(currentRoleProvider);
    ref.watch(contactsProvider); // rebuild when names arrive

    final assignmentsAsync = ref.watch(mentorAssignmentsProvider);
    final assignments =
        assignmentsAsync.value ?? const <Map<String, dynamic>>[];
    final effectiveId = _effectiveAssignmentId(assignments);

    // Load the free times whenever the assignment or the date changes.
    if (effectiveId != null) {
      final key = '$effectiveId|${_dateKey(_selectedDate)}';
      if (key != _loadedKey) {
        _loadedKey = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadTimes(effectiveId);
        });
      }
    }

    final canSubmit = effectiveId != null &&
        _selectedSlot != null &&
        !_isSubmitting &&
        _times?.error == null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
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
                          : 'Choose a date and a free time',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? AppColors.darkTextSecondary : null,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildAssignmentSection(assignmentsAsync, assignments,
                    effectiveId, role),
                _header(Icons.calendar_month_outlined, 'Select Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                        ),
                        Icon(Icons.edit_calendar, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _header(Icons.access_time_outlined, 'Available Times'),
                const SizedBox(height: 8),
                _buildTimes(effectiveId),
                const SizedBox(height: 20),
                _header(Icons.videocam_outlined, 'Session Type'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _modeOption(
                        title: 'Virtual',
                        icon: Icons.video_call_outlined,
                        selected: _sessionMode == 'virtual',
                        onTap: () => setState(() => _sessionMode = 'virtual'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modeOption(
                        title: 'In-Person',
                        icon: Icons.person_pin_circle_outlined,
                        selected: _sessionMode == 'in_person',
                        onTap: () => setState(() => _sessionMode = 'in_person'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _header(Icons.assignment_outlined, 'Session Topic'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTopic,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
                  decoration: _fieldDecoration(),
                  items: [
                    for (final t in _topics)
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : null,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedTopic = v);
                  },
                ),
                const SizedBox(height: 20),
                _header(Icons.notes_outlined, 'Preparation Notes'),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    hint: 'What would you like to focus on or review?',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _isSubmitting ? 'Scheduling...' : 'Confirm Schedule',
              onPressed: canSubmit ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
        ),
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade50,
    );
  }

  Widget _buildAssignmentSection(
    AsyncValue<List<Map<String, dynamic>>> async,
    List<Map<String, dynamic>> assignments,
    int? effectiveId,
    UserRole? role,
  ) {
    if (async.isLoading && assignments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: LinearProgressIndicator(),
      );
    }
    if (async.hasError && assignments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Could not load your assignments. Close this and try again.',
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }
    if (assignments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'No active mentor-mentee assignment was found, so a session '
          'cannot be scheduled yet.',
          style: TextStyle(color: Colors.orange.shade800),
        ),
      );
    }
    if (assignments.length == 1) return const SizedBox.shrink();

    final isMentor = role == UserRole.mentor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(Icons.person_outline, isMentor ? 'Select Mentee' : 'Select Mentor'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: effectiveId,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
          decoration: _fieldDecoration(),
          items: [
            for (final a in assignments)
              if (_idOf(a) != null)
                DropdownMenuItem<int>(
                  value: _idOf(a),
                  child: Text(
                    _partnerLabel(a, role),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
                  ),
                ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedAssignmentId = v);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTimes(int? effectiveId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (effectiveId == null) {
      return Text(
        'Free times appear once an assignment is available.',
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
          fontSize: 13,
        ),
      );
    }
    if (_loadingTimes || _times == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
        final error = _times!.error;
    if (error != null) {
      return Text(error,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13));
    }

    final slots = _visibleSlots();
    final checked = _times!.checked;

    if (slots.isEmpty) {
      return Text(
        'No free times on this day. Pick another date.',
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
          fontSize: 13,
        ),
      );
    }

    final morning = slots.where((s) => s.hour < 12).toList();
    final afternoon = slots.where((s) => s.hour >= 12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!checked)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Could not check availability. Standard times are shown, and '
              'the server will confirm your choice.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        if (morning.isNotEmpty) ...[
          _smallLabel('Morning'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in morning) _timeChip(s)],
          ),
          const SizedBox(height: 12),
        ],
        if (afternoon.isNotEmpty) ...[
          _smallLabel('Afternoon'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in afternoon) _timeChip(s)],
          ),
        ],
      ],
    );
  }

  Widget _smallLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
      ),
    );
  }

  Widget _header(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _timeChip(TimeSlot slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedSlot == slot;
    return Material(
      color: selected
          ? AppColors.primary
          : (isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _selectedSlot = slot),
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
            ),
          ),
          child: Text(
            slot.label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : Colors.black87),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeOption({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08)
              : (isDark ? AppColors.darkElevatedSurface : Colors.grey.shade50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? AppColors.darkTextPrimary : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        if (!isDark) return child!;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkElevatedSurface,
              onSurface: AppColors.darkTextPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.darkElevatedSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _submit() async {
    final assignments =
        ref.read(mentorAssignmentsProvider).value ?? const <Map<String, dynamic>>[];
    final assignmentId = _effectiveAssignmentId(assignments);
    final slot = _selectedSlot;
    if (assignmentId == null || slot == null) return;

    setState(() => _isSubmitting = true);

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      slot.hour,
      slot.minute,
    ).toUtc();

    // Only the fields documented for POST /sessions.
    final payload = <String, dynamic>{
      'assignment_id': assignmentId,
      'mode': _sessionMode,
      'scheduled_at': start.toIso8601String(),
      'duration_minutes': _durationMinutes,
      'session_goals': _selectedTopic,
      if (_notesController.text.trim().isNotEmpty)
        'preparation_notes': _notesController.text.trim(),
      'status': 'scheduled',
    };

    try {
      await ref.read(sessionsRepositoryProvider).createSession(payload);
      ref.invalidate(mentorSessionsProvider);
      ref.invalidate(menteeSessionsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session scheduled for ${_formatDate(_selectedDate)} at ${slot.label}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.error.message), backgroundColor: Colors.red),
      );
      // Often a scheduling conflict: refresh which times are still free.
      _loadTimes(assignmentId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not schedule the session. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}