import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../data/mentor_repository_provider.dart';
import '../domain/mentor_summary.dart';
import '../../sessions/presentation/meeting_launcher.dart';
import '../../../../core/widgets/app_drawer.dart';
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

class MentorDashboardPage extends ConsumerStatefulWidget {
  const MentorDashboardPage({super.key});

  @override
  ConsumerState<MentorDashboardPage> createState() => _MentorDashboardPageState();
}

class _MentorDashboardPageState extends ConsumerState<MentorDashboardPage> {
  int _activityDaysFilter = 0; // 0 = All time, 1 = Today, 3 = Last 3 days, 7 = Last 7 days, 30 = Last 30 days

  PopupMenuItem<int> _filterMenuItem(int days, String label) {
    final isSelected = _activityDaysFilter == days;
    return PopupMenuItem<int>(
      value: days,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(_userNameProvider);
    final summary = ref.watch(_summaryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const MainAppBar(
        title: 'CBCM',
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load dashboard'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_summaryProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(_summaryProvider.future),
          child: ListView(
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _DashboardMetricCard(
                      label: 'Total Mentees',
                      value: '${data.totalMentees}',
                      icon: Icons.people_outline,
                      iconColor: AppColors.primary,
                      badgeBg: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DashboardMetricCard(
                      label: 'Active Sessions',
                      value: '${data.activeSessions}',
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFFD97706),
                      badgeBg: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DashboardMetricCard(
                      label: 'Pending Logbooks',
                      value: '${data.logbooksPending}',
                      icon: Icons.menu_book_outlined,
                      iconColor: const Color(0xFFEA580C),
                      badgeBg: const Color(0xFFEA580C).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (data.todaySchedule.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No sessions scheduled for today.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
            for (final item in data.todaySchedule) _ScheduleCard(item: item),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Mentee Activity', style: Theme.of(context).textTheme.titleLarge),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Filter by days',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  initialValue: _activityDaysFilter,
                  onSelected: (days) {
                    setState(() => _activityDaysFilter = days);
                  },
                  itemBuilder: (context) => [
                    _filterMenuItem(0, 'All Recent'),
                    _filterMenuItem(1, 'Today'),
                    _filterMenuItem(3, 'Last 3 Days'),
                    _filterMenuItem(7, 'Last 7 Days'),
                    _filterMenuItem(30, 'Last 30 Days'),
                  ],
                ),
              ],
            ),
            if (_activityDaysFilter > 0) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filtered: ${_activityDaysFilter == 1 ? "Today" : "Last $_activityDaysFilter days"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _activityDaysFilter = 0),
                        child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            () {
              final now = DateTime.now();
              final filteredActivity = _activityDaysFilter == 0
                  ? data.recentActivity
                  : data.recentActivity.where((item) {
                      final itemDate = item.timestamp;
                      if (itemDate == null) return false;
                      if (_activityDaysFilter == 1) {
                        return itemDate.year == now.year &&
                            itemDate.month == now.month &&
                            itemDate.day == now.day;
                      }
                      final diff = now.difference(itemDate).inDays;
                      return diff <= _activityDaysFilter;
                    }).toList();

              if (filteredActivity.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _activityDaysFilter > 0
                        ? 'No activity recorded in ${_activityDaysFilter == 1 ? "the last 24 hours" : "the last $_activityDaysFilter days"}.'
                        : 'No recent activity yet.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final item in filteredActivity) _ActivityRow(item: item),
                  ],
                ),
              );
            }(),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.time,
              style: TextStyle(
                color: isDark ? AppColors.pageIndicator : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                item.isGroup
                    ? CircleAvatar(
                        backgroundColor: AppColors.pageIndicator.withValues(alpha: 0.3),
                        child: Icon(Icons.groups, color: isDark ? AppColors.pageIndicator : AppColors.primary))
                    : CircleAvatar(
                        backgroundColor: isDark ? AppColors.darkElevatedSurface : null,
                        child: Icon(Icons.person, color: isDark ? AppColors.darkTextPrimary : null)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
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

  void _onTap(BuildContext context) {
    final t = '${item.type ?? ''} ${item.tag ?? ''} ${item.description}'.toLowerCase();
    final entryId = item.entryId;

    if (t.contains('logbook') || t.contains('procedure')) {
      if (entryId != null && entryId > 0) {
        context.push(AppRoutes.mentorLogbookDetail, extra: entryId);
      } else {
        context.push(AppRoutes.mentorLogbookReview);
      }
      return;
    }

    if (t.contains('session')) {
      context.go(AppRoutes.mentorSessions);
      return;
    }

    if (t.contains('assess') || t.contains('quiz') || t.contains('module')) {
      context.go(AppRoutes.mentorMentees);
      return;
    }

    context.push(AppRoutes.mentorLogbookReview);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (item.icon) {
      ActivityIconType.logbookSubmitted => (Icons.description_outlined, Colors.green),
      ActivityIconType.clarificationRequested => (Icons.help_outline, Colors.amber),
      ActivityIconType.approved => (Icons.check_circle_outline, Colors.grey),
    };

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
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
                  Text(
                    item.description,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.timeAgo,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (item.tag != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                      ),
                      child: Text(
                        item.tag!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
            ),
          ],
        ),
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
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.badgeBg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.0),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3.5,
              child: Container(color: iconColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 17, color: iconColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF4B5563),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}