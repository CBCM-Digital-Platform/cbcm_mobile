import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/presentation/contact_picker.dart';
import '../../sessions/presentation/schedule_session_sheet.dart';
import '../data/assigned_mentees_provider.dart';
import '../../../assessments/assessments_page.dart';
import '../../../progress/presentation/mentee_progress_card.dart';
import 'assign_resources_page.dart';
import 'open_modules_page.dart';
import 'share_material_page.dart';

class MenteesPage extends ConsumerStatefulWidget {
  const MenteesPage({super.key});

  @override
  ConsumerState<MenteesPage> createState() => _MenteesPageState();
}

class _MenteesPageState extends ConsumerState<MenteesPage> {
  final _searchController = TextEditingController();
  String _selectedFacility = 'All Facilities';
  String _selectedLevel = 'All Levels';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menteesAsync = ref.watch(assignedMenteesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(assignedMenteesProvider);
            ref.invalidate(contactsApiProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Text(
                'My Mentees',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track your assigned nursing students.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search mentees by name or ID...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      value: _selectedFacility,
                      items: const [
                        'All Facilities',
                        'Unit A',
                        'Clinic North',
                        'Labor Ward',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFacility = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      value: _selectedLevel,
                      items: const [
                        'All Levels',
                        'Novice',
                        'Intermediate',
                        'Advanced',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLevel = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mentees list
              menteesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text('Could not load assigned mentees'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(assignedMenteesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (mentees) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = mentees.where((m) {
                    final matchesQuery = query.isEmpty ||
                        m.fullName.toLowerCase().contains(query) ||
                        m.id.toString().contains(query);
                    final matchesFacility = _selectedFacility == 'All Facilities' ||
                        m.facility.toLowerCase() == _selectedFacility.toLowerCase();
                    final matchesLevel = _selectedLevel == 'All Levels' ||
                        m.level.toLowerCase() == _selectedLevel.toLowerCase();
                    return matchesQuery && matchesFacility && matchesLevel;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          query.isNotEmpty
                              ? 'No mentees match "$query".'
                              : 'No mentees assigned yet.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filtered
                        .map((m) => _MenteeCard(
                              mentee: m,
                              onSchedule: () => ScheduleSessionSheet.show(
                                context,
                                menteeName: m.fullName,
                                menteeId: m.id,
                                assignmentId: m.assignmentId,
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 20, color: Colors.grey.shade600),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MenteeCard extends ConsumerWidget {
  const _MenteeCard({
    required this.mentee,
    required this.onSchedule,
  });

  final AssignedMentee mentee;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      if (mentee.facility.isNotEmpty) mentee.facility,
      if (mentee.level.isNotEmpty) mentee.level,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMenteeDetailsSheet(context, ref, mentee, onSchedule),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Subtitle + Chevron
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          mentee.fullName.isNotEmpty
                              ? mentee.fullName[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mentee.isOnline ? Colors.green : Colors.grey,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentee.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),

              // Badges Row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mentee.needsReview
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: mentee.needsReview
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mentee.needsReview
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          size: 13,
                          color: mentee.needsReview
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mentee.needsReview ? 'Needs Review' : 'Up to date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mentee.needsReview
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text(
                      'Clinical Practicum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Clean 2-Row Action Buttons: Schedule full width on top, Message & Share side-by-side
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Schedule Session',
                  onPressed: onSchedule,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Message',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        if (mentee.messageUser != null) {
                          openChatWith(context, ref, mentee.messageUser!);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Share Resource',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        if (mentee.messageUser != null) {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => ShareMaterialPage(
                                initialMentee: mentee.messageUser!,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenteeDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    AssignedMentee mentee,
    VoidCallback onSchedule,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text(
                      'Back to Mentees',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      mentee.fullName.isNotEmpty ? mentee.fullName[0].toUpperCase() : 'M',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentee.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (mentee.email.isNotEmpty)
                          Text(
                            mentee.email,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        Text(
                          '${mentee.facility} • ${mentee.level}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Enrolled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Clinical Progress Section
              Text(
                'Clinical & Curriculum Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              MenteeProgressCard(menteeId: mentee.id),
              const SizedBox(height: 16),

              // Assignments & Quizzes Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Assignments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'No data yet',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 16),

              // Assignment & Quiz Actions (Disabled with Coming soon)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.add_task, size: 18, color: Colors.grey.shade400),
                      label: Text(
                        'Assign Task (Coming soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onPressed: null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.quiz_outlined, size: 18, color: Colors.grey.shade400),
                      label: Text(
                        'Assign Quiz (Coming soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onPressed: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Open modules',
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => OpenModulesPage(
                          menteeId: mentee.id,
                          menteeName: mentee.fullName,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Schedule Clinical Session',
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSchedule();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Assign resources',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => AssignResourcesPage(
                              menteeId: mentee.id,
                              menteeName: mentee.fullName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Assessments',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => AssessmentsPage(
                              menteeId: mentee.id,
                              menteeName: mentee.fullName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Message',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mentee.messageUser != null) {
                      openChatWith(context, ref, mentee.messageUser!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignTaskDialog(BuildContext context, WidgetRef ref, AssignedMentee mentee) {
    final titleController = TextEditingController(text: 'Clinical Case Study: Maternal Hemorrhage Protocol');
    final descController = TextEditingController(text: 'Review patient assessment checklist, triage decision matrix, and emergency response procedures.');
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.add_task, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assign Task to ${mentee.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assignment Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Instructions / Objectives', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Change'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDlgState(() => dueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dlgContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Assignment assigned to ${mentee.fullName} successfully!'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              },
              child: const Text('Issue Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignQuizDialog(BuildContext context, WidgetRef ref, AssignedMentee mentee) {
    String selectedQuiz = 'Emergency Obstetric Care (EmOC)';
    String passingScore = '80%';

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assign Quiz to ${mentee.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Clinical Quiz / Assessment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedQuiz,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Emergency Obstetric Care (EmOC)',
                      child: Text('Emergency Obstetric Care (EmOC)', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'Partograph & Labor Monitoring',
                      child: Text('Partograph & Labor Monitoring', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'Neonatal Resuscitation Protocol',
                      child: Text('Neonatal Resuscitation Protocol', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'Infection Prevention & Sterile Field',
                      child: Text('Infection Prevention & Sterile Field', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedQuiz = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Passing Threshold', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: passingScore,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: '70%', child: Text('70% (Standard)')),
                    DropdownMenuItem(value: '80%', child: Text('80% (Clinical Mastery)')),
                    DropdownMenuItem(value: '90%', child: Text('90% (Distinction)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => passingScore = val);
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${mentee.fullName} will be notified immediately to take this quiz before their next scheduled clinical review.',
                          style: TextStyle(fontSize: 11.5, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dlgContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quiz "$selectedQuiz" assigned to ${mentee.fullName}!'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              },
              child: const Text('Assign Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}