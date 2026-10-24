import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/mentor_repository.dart';
import '../domain/mentor_summary.dart';

/// Real backend implementation of [MentorRepository]. Shows only what the
/// server returns: no sample data is mixed in.
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
    ]);
    final assignmentsData = results[0];
    final sessionsData = results[1];
    final cyclesData = results[2];

    if (assignmentsData == null && sessionsData == null && cyclesData == null) {
      throw StateError('Could not reach the server.');
    }

    // Mentees: active assignments only.
    final assignments = _list(assignmentsData).whereType<Map>().where((a) {
      final status = a['status']?.toString();
      return status == null || status == 'assigned';
    }).toList();

    final studentNames = <String>[];
    for (final a in assignments) {
      final m = a['mentee'] is Map ? a['mentee'] as Map : null;
      final name =
          (m?['full_name'] ?? m?['fullName'] ?? m?['name'] ?? a['mentee_name'])
              ?.toString();
      if (name != null && name.isNotEmpty) studentNames.add(name);
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

    return MentorSummary(
      totalMentees: assignments.length,
      activeSessions: live.length,
      logbooksPending: 0,
      todaySchedule: todaySchedule,
      recentActivity: const [],
      activeCycleName: cycleInfo?.name,
      activeCycle: cycleInfo,
    );
  }

  /// Returns the response body, or null if the request failed.
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
      const keys = ['items', 'assignments', 'cycles', 'sessions'];
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
}