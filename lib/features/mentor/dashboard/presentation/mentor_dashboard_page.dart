import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../data/mentor_repository_provider.dart';
import '../domain/mentor_summary.dart';
import '../../../auth/presentation/profile_menu_button.dart';
import '../../../notifications/presentation/notification_bell.dart';
import '../../sessions/presentation/meeting_launcher.dart';
import '../../../../routing/app_routes.dart';
import 'package:go_router/go_router.dart';

final _userNameProvider = FutureProvider.autoDispose((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return (await storage.read(StorageKeys.userName)) ?? 'there';
});

final _summaryProvider = FutureProvider.autoDispose((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final userId = (await storage.read(StorageKeys.userId)) ?? 'unknown';
  return ref.watch(mentorRepositoryProvider).getDashboardSummary(userId);
});

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class MentorDashboardPage extends ConsumerWidget {
  const MentorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(_userNameProvider);
    final summary = ref.watch(_summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('MidwifeMentor',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.primary,
        actions: [
          const NotificationBell(),
          const ProfileMenuButton(),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load dashboard')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            name.when(
              data: (n) => Text('${_greeting()}, $n',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              loading: () => Text('${_greeting()}...'),
              error: (error, _) => Text(_greeting()),
            ),
            if (data.activeCycle != null || data.activeCycleName != null)
              _MentorshipCycleCard(
                cycle: data.activeCycle,
                fallbackName: data.activeCycleName,
              ),
            const SizedBox(height: 16),
            StatCard(
              label: 'Total Mentees',
              value: '${data.totalMentees}',
              icon: Icons.people_outline,
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: 12),
            StatCard(
              label: 'Active Sessions',
              value: '${data.activeSessions}',
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.pageIndicator,
              accentColor: AppColors.pageIndicator,
            ),

            const SizedBox(height: 24),
            Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (data.todaySchedule.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No sessions scheduled for today.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            for (final item in data.todaySchedule) _ScheduleCard(item: item),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Mentee Activity', style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 8),
            if (data.recentActivity.isEmpty)
              Text(
                'No recent activity yet.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final item in data.recentActivity) _ActivityRow(item: item),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.time, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                item.isGroup
                    ? CircleAvatar(
                        backgroundColor: AppColors.pageIndicator.withValues(alpha: 0.3),
                        child: Icon(Icons.groups, color: AppColors.primary))
                    : const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(item.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            item.action == SessionAction.start && item.sessionId != null
                ? SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Start Session (Video)',
                      onPressed: () {
                        final sId = item.sessionId!;
                        launchJitsiMeeting(
                          context: context,
                          ref: ref,
                          sessionId: sId,
                          sessionTitle: item.title,
                        );
                      },
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Details',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        context.go(AppRoutes.mentorSessions);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.icon) {
      ActivityIconType.logbookSubmitted => (Icons.description_outlined, Colors.green),
      ActivityIconType.clarificationRequested => (Icons.help_outline, Colors.amber),
      ActivityIconType.approved => (Icons.check_circle_outline, Colors.grey),
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                const SizedBox(height: 2),
                Text(item.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (item.tag != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.tag!, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorshipCycleCard extends StatelessWidget {
  const _MentorshipCycleCard({this.cycle, this.fallbackName});

  final MentorshipCycleInfo? cycle;
  final String? fallbackName;

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title = cycle?.name ?? fallbackName ?? 'Mentorship cycle';
    final code = cycle?.code;
    final thematic = cycle?.thematicArea;
    final dateRange = cycle?.dateRangeText ?? '';
    final students = cycle?.studentNames ?? const <String>[];
    final status = cycle?.status ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(code != null && code.isNotEmpty ? 'CYCLE: $code' : 'ACTIVE CYCLE'),
              if (status.isNotEmpty)
                _pill('${status[0].toUpperCase()}${status.substring(1)}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (thematic != null && thematic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Thematic area: $thematic',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.5,
              ),
            ),
          ],
          if (dateRange.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              dateRange,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
          if (students.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final s in students) _pill(s)],
            ),
          ],
        ],
      ),
    );
  }
}