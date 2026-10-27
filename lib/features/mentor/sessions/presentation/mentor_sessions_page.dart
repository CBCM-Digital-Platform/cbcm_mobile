import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/profile_menu_button.dart';
import '../../../notifications/presentation/notification_bell.dart';
import '../data/sessions_repository_provider.dart';
import '../domain/session_model.dart';
import 'meeting_launcher.dart';
import 'schedule_session_sheet.dart';

final mentorSessionsProvider =
    FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final mentorIdStr = await storage.read(StorageKeys.userId);
  final mentorId = int.tryParse(mentorIdStr ?? '');
  final repo = ref.watch(sessionsRepositoryProvider);
  return repo.getSessions(mentorId: mentorId);
});

final menteeSessionsProvider =
    FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final menteeIdStr = await storage.read(StorageKeys.userId);
  final menteeId = int.tryParse(menteeIdStr ?? '');
  final repo = ref.watch(sessionsRepositoryProvider);
  return repo.getSessions(menteeId: menteeId);
});

class MentorSessionsPage extends ConsumerStatefulWidget {
  const MentorSessionsPage({super.key});

  @override
  ConsumerState<MentorSessionsPage> createState() => _MentorSessionsPageState();
}

class _MentorSessionsPageState extends ConsumerState<MentorSessionsPage> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = Past

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(mentorSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Clinical Sessions',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: const [
          NotificationBell(),
          ProfileMenuButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'mentor_sessions_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Session'),
        onPressed: () async {
          await ScheduleSessionSheet.show(context);
          ref.invalidate(mentorSessionsProvider);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(mentorSessionsProvider),
          child: Column(
            children: [
              // Segmented Tab Filter
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('Upcoming', 0, isDark),
                    ),
                    Expanded(
                      child: _buildTabButton('Past & Completed', 1, isDark),
                    ),
                  ],
                ),
              ),

              // Sessions list
              Expanded(
                child: sessionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Could not load sessions'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(mentorSessionsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (sessions) {
                    final now = DateTime.now();
                    final filtered = sessions.where((s) {
                      if (_selectedTab == 0) {
                        return s.scheduledStartTime.isAfter(now.subtract(const Duration(hours: 1))) ||
                            s.isInProgress;
                      } else {
                        return s.scheduledStartTime.isBefore(now.subtract(const Duration(hours: 1))) ||
                            s.isCompleted;
                      }
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0
                                    ? Icons.event_available_outlined
                                    : Icons.history_outlined,
                                size: 54,
                                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? 'No upcoming sessions'
                                    : 'No past sessions found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedTab == 0
                                    ? 'Tap "Schedule Session" below to set up supervision.'
                                    : 'Completed sessions will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = filtered[index];
                        return SessionCard(
                          session: session,
                          onReschedule: () async {
                            await ScheduleSessionSheet.show(
                              context,
                              menteeName: session.menteeName,
                              menteeId: session.menteeId,
                              assignmentId: session.assignmentId,
                            );
                            ref.invalidate(mentorSessionsProvider);
                          },
                        );
                      },
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

  Widget _buildTabButton(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionCard extends ConsumerWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.onReschedule,
    this.isMenteeView = false,
  });

  final SessionModel session;
  final VoidCallback? onReschedule;
  final bool isMenteeView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVirtual = session.isVirtual;
    final partnerName = isMenteeView
        ? (session.mentorName ?? 'Mentor')
        : (session.menteeName ?? 'Mentee');
    final roleSubtitle = isMenteeView ? 'Assigned Mentor' : 'Assigned Mentee';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Date/Time + Mode chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateTime(session.scheduledStartTime),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVirtual
                      ? (isDark ? Colors.teal.withValues(alpha: 0.25) : Colors.teal.withValues(alpha: 0.12))
                      : (isDark ? Colors.orange.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVirtual
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      size: 14,
                      color: isVirtual ? (isDark ? Colors.tealAccent : Colors.teal) : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVirtual ? 'Virtual (Jitsi)' : 'In-Person',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isVirtual ? (isDark ? Colors.tealAccent : Colors.teal) : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Avatar and title
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: isDark ? AppColors.primaryLight : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      session.sessionGoals != null && session.sessionGoals!.isNotEmpty
                          ? session.sessionGoals!
                          : '$roleSubtitle • ${session.sessionType}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (session.location != null && session.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pin_drop_outlined,
                    size: 14, color: isDark ? AppColors.darkTextSecondary : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  session.location!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (isVirtual)
                Expanded(
                  child: AppButton(
                    label: 'Join Meeting',
                    onPressed: () {
                      launchJitsiMeeting(
                        context: context,
                        ref: ref,
                        sessionId: session.id,
                        sessionTitle: partnerName,
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: AppButton(
                    label: 'Clinical Visit',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ),
              if (onReschedule != null) ...[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Reschedule',
                  variant: AppButtonVariant.secondary,
                  onPressed: onReschedule,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} • ${hour.toString().padLeft(2, '0')}:$minute $period (${session.durationMinutes}m)';
  }
}
