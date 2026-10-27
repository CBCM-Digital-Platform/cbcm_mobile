import '../../../logbook/presentation/record_logbook_sheet.dart';
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
import 'learning_access_page.dart';

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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                        fontSize: 14,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search mentees by name or ID...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      context: context,
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
                      context: context,
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
    required BuildContext context,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                      ),
                    ),
                  ))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          style: const TextStyle(
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
                            border: Border.all(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              width: 2,
                            ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppColors.darkTextPrimary : null,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                  ),
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
                          ? (isDark
                              ? Colors.red.shade900.withValues(alpha: 0.35)
                              : Colors.red.shade50)
                          : (isDark
                              ? Colors.green.shade900.withValues(alpha: 0.35)
                              : Colors.green.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: mentee.needsReview
                            ? (isDark ? Colors.red.shade700 : Colors.red.shade200)
                            : (isDark ? Colors.green.shade700 : Colors.green.shade200),
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
                              ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                              : (isDark ? Colors.green.shade300 : Colors.green.shade700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mentee.needsReview ? 'Needs Review' : 'Up to date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mentee.needsReview
                                ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                                : (isDark ? Colors.green.shade300 : Colors.green.shade700),
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
                      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      'Clinical Practicum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons: Schedule full width on top, Message full width below
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Schedule Session',
                  onPressed: onSchedule,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Record Logbook Entry',
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.edit_note),
                  onPressed: () {
                    showRecordLogbookSheet(
                      context,
                      initialMenteeId: mentee.id,
                      menteeName: mentee.fullName,
                    );
                  },
                ),
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
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
          ),
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
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
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
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                    ),
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
                      style: const TextStyle(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : null,
                          ),
                        ),
                        if (mentee.email.isNotEmpty)
                          Text(
                            mentee.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                            ),
                          ),
                        Text(
                          '${mentee.facility} • ${mentee.level}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.shade900.withValues(alpha: 0.35)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.green.shade700 : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      'Enrolled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.green.shade300 : Colors.green.shade700,
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
                  color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade800,
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
                      color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  'No data yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Learning access',
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => LearningAccessPage(
                          mentee.id,
                          mentee.fullName,
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
                  const SizedBox(width: 8),
                  Expanded(
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
            ],
          ),
        ),
      );
    },
  );
}
}