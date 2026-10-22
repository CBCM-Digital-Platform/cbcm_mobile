import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/presentation/contact_picker.dart';
import '../../sessions/presentation/schedule_session_sheet.dart';
import '../data/assigned_mentees_provider.dart';
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
      backgroundColor: AppColors.background,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        '${mentee.facility} • ${mentee.level}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
                if (mentee.pendingLogbooks > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      '${mentee.pendingLogbooks} Logbooks',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Core Competency Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Core Competency',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${mentee.competencyPercentage}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mentee.competencyPercentage / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Schedule',
                    onPressed: onSchedule,
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Message',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    if (mentee.messageUser != null) {
                      openChatWith(context, ref, mentee.messageUser!);
                    }
                  },
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Share',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}