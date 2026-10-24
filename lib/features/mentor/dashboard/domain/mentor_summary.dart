enum SessionAction { start, details }

class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.action,
    this.isGroup = false,
    this.sessionId,
    this.mode,
    this.scheduledStartTime,
  });

  final String time;
  final String title;
  final String subtitle;
  final SessionAction action;
  final bool isGroup;
  final int? sessionId;
  final String? mode;
  final DateTime? scheduledStartTime;
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

class MentorshipCycleInfo {
  const MentorshipCycleInfo({
    required this.id,
    required this.name,
    this.code,
    this.thematicArea,
    this.startDate,
    this.endDate,
    this.status,
    this.studentNames = const [],
  });

  final int id;
  final String name;
  final String? code;
  final String? thematicArea;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final List<String> studentNames;

  String get dateRangeText {
    if (startDate == null && endDate == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String fmt(DateTime d) => '${months[d.month - 1]} ${d.day}, ${d.year}';
    if (startDate != null && endDate != null) {
      return '${fmt(startDate!)} – ${fmt(endDate!)}';
    }
    return startDate != null ? 'Started ${fmt(startDate!)}' : 'Ends ${fmt(endDate!)}';
  }
}

class MentorSummary {
  const MentorSummary({
    required this.totalMentees,
    required this.activeSessions,
    required this.logbooksPending,
    required this.todaySchedule,
    required this.recentActivity,
    this.activeCycleName,
    this.activeCycle,
  });

  final int totalMentees;
  final int activeSessions;
  final int logbooksPending;
  final List<ScheduleItem> todaySchedule;
  final List<ActivityItem> recentActivity;
  final String? activeCycleName;
  final MentorshipCycleInfo? activeCycle;
}