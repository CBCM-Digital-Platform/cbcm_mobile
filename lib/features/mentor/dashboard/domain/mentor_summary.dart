enum SessionAction { start, details }

class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.action,
    this.isGroup = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final SessionAction action;
  final bool isGroup;
}

class ActivityItem {
  const ActivityItem({
    required this.icon,
    required this.description,
    required this.timeAgo,
    this.tag,
  });

  final ActivityIconType icon;
  final String description;
  final String timeAgo;
  final String? tag;
}

enum ActivityIconType { logbookSubmitted, clarificationRequested, approved }

class MentorSummary {
  const MentorSummary({
    required this.totalMentees,
    required this.activeSessions,
    required this.logbooksPending,
    required this.todaySchedule,
    required this.recentActivity,
  });

  final int totalMentees;
  final int activeSessions;
  final int logbooksPending;
  final List<ScheduleItem> todaySchedule;
  final List<ActivityItem> recentActivity;
}