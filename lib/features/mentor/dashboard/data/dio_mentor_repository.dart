import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/mentor_repository.dart';
import '../domain/mentor_summary.dart';

/// Real backend implementation of [MentorRepository].
class DioMentorRepository implements MentorRepository {
  DioMentorRepository(this._dio, {MentorRepository? fallback});

  final Dio _dio;

  @override
  Future<MentorSummary> getDashboardSummary(String mentorId) async {
    final id = int.tryParse(mentorId);
    if (id == null) throw StateError('Not signed in as a mentor.');

    final results = await Future.wait<dynamic>([
      _get(ApiEndpoints.mentorAssignments(id)),
      _get(ApiEndpoints.sessions, query: {'mentor_id': id, 'limit': 50}),
      _get(ApiEndpoints.mentorshipCycles),
      _get('/logbook', query: {'status': 'submitted'}),
      _get('/activity-logs', query: {'limit': 5}),
    ]);
    final assignmentsData = results[0];
    final sessionsData = results[1];
    final cyclesData = results[2];
    final logbooksData = results[3];
    final activityLogsData = results[4];

    if (assignmentsData == null && sessionsData == null && cyclesData == null) {
      throw StateError('Could not reach the server.');
    }

    // Mentees: active assignments only.
    final assignments = _list(assignmentsData).whereType<Map>().where((a) {
      final status = a['status']?.toString();
      return status == null || status == 'assigned';
    }).toList();

    final studentNames = <String>[];
    final menteeNamesById = <int, String>{};
    for (final a in assignments) {
      final m = a['mentee'] is Map ? a['mentee'] as Map : null;
      final mId = (m?['id'] ?? a['mentee_id'] ?? a['menteeId']) as num?;
      final name =
          (m?['full_name'] ?? m?['fullName'] ?? m?['name'] ?? a['mentee_name'])
              ?.toString();
      if (name != null && name.isNotEmpty) {
        studentNames.add(name);
        if (mId != null) menteeNamesById[mId.toInt()] = name;
      }
    }

    // Sessions: active ones, and today's for the schedule.
    final live = _list(sessionsData).whereType<Map>().where((s) {
      final st = s['status']?.toString();
      return st == 'scheduled' || st == 'in_progress';
    }).toList();

    final now = DateTime.now();
    final todaySchedule = <ScheduleItem>[];
    for (final s in live) {
      final rawStart =
          s['scheduled_start_time'] ?? s['scheduled_at'] ?? s['scheduledAt'];
      final start = DateTime.tryParse('${rawStart ?? ''}')?.toLocal();
      if (start == null || !_sameDay(start, now)) continue;

      final mode = (s['mode'] ?? 'virtual').toString();
      final isVirtual = mode.toLowerCase() == 'virtual';
      final mentee = s['mentee'] is Map ? s['mentee'] as Map : null;
      final title = (mentee?['full_name'] ??
              mentee?['fullName'] ??
              mentee?['name'] ??
              s['mentee_name'] ??
              'Session')
          .toString();

      todaySchedule.add(
        ScheduleItem(
          sessionId: (s['id'] as num?)?.toInt(),
          mode: mode,
          time: _formatTime(start),
          title: title,
          subtitle: isVirtual
              ? 'Virtual session'
              : (s['location'] ?? 'In-person visit').toString(),
          scheduledStartTime: start,
          action: isVirtual ? SessionAction.start : SessionAction.details,
        ),
      );
    }
    todaySchedule.sort((a, b) => (a.scheduledStartTime ?? now)
        .compareTo(b.scheduledStartTime ?? now));

    // Cycle: only a cycle the server marks active.
    Map? active;
    for (final c in _list(cyclesData).whereType<Map>()) {
      if (c['status']?.toString() == 'active' || c['is_active'] == true) {
        active = c;
        break;
      }
    }

    MentorshipCycleInfo? cycleInfo;
    if (active != null) {
      DateTime? date(Object? v) => v == null ? null : DateTime.tryParse('$v');
      cycleInfo = MentorshipCycleInfo(
        id: (active['id'] as num?)?.toInt() ?? 0,
        name: (active['name'] ?? active['title'] ?? active['cycle_name'])
                ?.toString() ??
            'Mentorship cycle',
        code: (active['code'] ?? active['cycle_code'])?.toString(),
        thematicArea:
            (active['thematic_area'] ?? active['thematicArea'] ?? active['topic'])
                ?.toString(),
        startDate: date(active['start_date'] ?? active['startDate']),
        endDate: date(active['end_date'] ?? active['endDate']),
        status: (active['status'] ?? 'active').toString(),
        studentNames: studentNames,
      );
    }

    // Pending logbooks count from real backend
    final pendingLogbooksList = _list(logbooksData).whereType<Map>().toList();
    final logbooksPending = pendingLogbooksList.length;

    // Recent mentee activity items
    final recentActivity = <ActivityItem>[];

    // 1. Pending logbook submissions
    for (final lb in pendingLogbooksList) {
      final mentee = lb['mentee'] is Map ? lb['mentee'] as Map : null;
      final mId = (mentee?['id'] ?? lb['mentee_id'] ?? lb['menteeId']) as num?;
      final menteeName = (mentee?['full_name'] ??
              mentee?['name'] ??
              (mId != null ? menteeNamesById[mId.toInt()] : null) ??
              lb['mentee_name'] ??
              'Mentee')
          .toString();
      final title = (lb['procedure_name'] ??
              lb['title'] ??
              lb['topic'] ??
              'Clinical Logbook entry')
          .toString();
      final createdAt = DateTime.tryParse(
              '${lb['created_at'] ?? lb['createdAt'] ?? lb['entry_date'] ?? ''}')
          ?.toLocal();

      recentActivity.add(ActivityItem(
        icon: ActivityIconType.logbookSubmitted,
        description: '$menteeName submitted $title.',
        timeAgo: createdAt != null ? _timeAgo(createdAt, now) : 'Recently',
        tag: 'Logbook',
      ));
    }

    // 2. Filtered & humanized activity logs
    for (final log in _list(activityLogsData).whereType<Map>()) {
      final rawAction = (log['action'] ?? '').toString();
      final action = rawAction.toUpperCase();
      final entityType = (log['entity_type'] ?? log['entityType'] ?? '').toString().toUpperCase();

      // Filter out low-level auth & token audit logs (not mentee clinical activity)
      if (action.contains('LOGIN') ||
          action.contains('LOGOUT') ||
          action.contains('AUTH') ||
          (entityType == 'USER' && (action.contains('LOG') || action.contains('TOKEN')))) {
        continue;
      }

      final actor = log['actor'] is Map ? log['actor'] as Map : null;
      final actorId = (log['actor_id'] ?? log['actorId'] ?? actor?['id']) as num?;
      final actorName = (actor?['full_name'] ??
              actor?['name'] ??
              (actorId != null ? menteeNamesById[actorId.toInt()] : null) ??
              'Mentee')
          .toString();
      final createdAt = DateTime.tryParse('${log['created_at'] ?? log['createdAt'] ?? ''}')?.toLocal();

      ActivityIconType iconType = ActivityIconType.clarificationRequested;
      String desc;

      if (action.contains('APPROVE')) {
        iconType = ActivityIconType.approved;
        desc = 'You approved an entry for $actorName.';
      } else if (entityType.contains('LOGBOOK') || action.contains('LOGBOOK')) {
        iconType = ActivityIconType.logbookSubmitted;
        desc = '$actorName submitted a clinical logbook.';
      } else if (entityType.contains('ASSESS') || action.contains('ASSESS')) {
        iconType = ActivityIconType.approved;
        desc = '$actorName completed an assessment.';
      } else if (entityType.contains('QUIZ') || action.contains('QUIZ')) {
        iconType = ActivityIconType.approved;
        desc = '$actorName completed a module quiz.';
      } else if (entityType.contains('SESSION') || action.contains('SESSION')) {
        iconType = ActivityIconType.clarificationRequested;
        desc = '$actorName updated a mentoring session.';
      } else {
        final cleanAction = rawAction.replaceAll('.', ' ').replaceAll('_', ' ');
        final cleanEntity = entityType.toLowerCase().replaceAll('_', ' ');
        desc = '$actorName $cleanAction ($cleanEntity).';
      }

      final timeAgoStr = createdAt != null ? _timeAgo(createdAt, now) : 'recently';

      recentActivity.add(ActivityItem(
        icon: iconType,
        description: desc,
        timeAgo: timeAgoStr,
        tag: entityType.isNotEmpty ? entityType.toLowerCase() : null,
      ));
    }

    return MentorSummary(
      totalMentees: assignments.length,
      activeSessions: live.length,
      logbooksPending: logbooksPending,
      todaySchedule: todaySchedule,
      recentActivity: recentActivity,
      activeCycleName: cycleInfo?.name,
      activeCycle: cycleInfo,
    );
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get(path, queryParameters: query);
      return r.data;
    } catch (e) {
      debugPrint('[MentorDashboard] $path failed: $e');
      return null;
    }
  }

  List<dynamic> _list(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw;
      if (data is List) return data;
      const keys = ['items', 'assignments', 'cycles', 'sessions', 'entries', 'logs'];
      if (data is Map) {
        for (final k in keys) {
          if (data[k] is List) return data[k] as List;
        }
      }
      for (final k in keys) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return [];
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _timeAgo(DateTime from, DateTime to) {
    final diff = to.difference(from);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
