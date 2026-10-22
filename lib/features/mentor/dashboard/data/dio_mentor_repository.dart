import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/mentor_repository.dart';
import '../domain/mentor_summary.dart';
import 'mock_mentor_repository.dart';

/// Real backend implementation of [MentorRepository].
/// Concurrently fetches assigned mentees, active sessions, and cycle details.
/// Gracefully falls back to mock data if offline or if backend endpoints return an error.
class DioMentorRepository implements MentorRepository {
  DioMentorRepository(this._dio, {MentorRepository? fallback})
      : _fallback = fallback ?? MockMentorRepository();

  final Dio _dio;
  final MentorRepository _fallback;

  @override
  Future<MentorSummary> getDashboardSummary(String mentorId) async {
    final parsedId = int.tryParse(mentorId);
    if (parsedId == null) {
      debugPrint('[DioMentorRepository] Invalid mentorId: $mentorId. Using fallback.');
      return _fallback.getDashboardSummary(mentorId);
    }

    try {
      // Concurrently fetch assignments, active sessions, and cycle details
      final results = await Future.wait([
        _fetchAssignments(parsedId),
        _dio.get(ApiEndpoints.sessions, queryParameters: {
          'mentor_id': parsedId,
          'status': 'scheduled',
          'limit': 20,
        }).then((r) => r.data).catchError((e) {
          debugPrint('[DioMentorRepository] Failed to fetch scheduled sessions: $e');
          return null;
        }),
        _dio.get(ApiEndpoints.sessions, queryParameters: {
          'mentor_id': parsedId,
          'status': 'in_progress',
          'limit': 10,
        }).then((r) => r.data).catchError((e) {
          debugPrint('[DioMentorRepository] Failed to fetch in-progress sessions: $e');
          return null;
        }),
        _dio.get(ApiEndpoints.mentorshipCycles).then((r) => r.data).catchError((e) {
          debugPrint('[DioMentorRepository] Failed to fetch cycles: $e');
          return null;
        }),
      ]);

      final assignmentsData = results[0];
      final scheduledData = results[1];
      final inProgressData = results[2];
      final cyclesData = results[3];

      // If all network calls returned null (e.g. offline), use fallback
      if (assignmentsData == null && scheduledData == null && inProgressData == null && cyclesData == null) {
        return await _fallback.getDashboardSummary(mentorId);
      }

      // 1. Total Mentees
      int totalMentees = 0;
      bool assignmentsLoaded = false;
      if (assignmentsData != null) {
        assignmentsLoaded = true;
        final list = _extractList(assignmentsData);
        totalMentees = list.length;
        if (assignmentsData is Map) {
          final inner = assignmentsData['data'];
          if (inner is Map && inner['total'] is num) {
            totalMentees = (inner['total'] as num).toInt();
          } else if (assignmentsData['total'] is num) {
            totalMentees = (assignmentsData['total'] as num).toInt();
          }
        }
      }

      // 2. Active Sessions count
      final scheduledList = _extractList(scheduledData);
      final inProgressList = _extractList(inProgressData);
      final activeSessions = scheduledList.length + inProgressList.length;

      // 3. Mentorship Cycle
      String? cycleName;
      final cycles = _extractList(cyclesData);
      if (cycles.isNotEmpty) {
        final activeCycle = cycles.firstWhere(
          (c) => c is Map && (c['status'] == 'active' || c['is_active'] == true),
          orElse: () => cycles.first,
        );
        if (activeCycle is Map) {
          cycleName = (activeCycle['name'] ?? activeCycle['title'] ?? activeCycle['cycle_name'])?.toString();
        }
      }

      // 4. Today's Schedule items
      final allSessions = [...inProgressList, ...scheduledList];
      final List<ScheduleItem> todaySchedule = [];

      for (final raw in allSessions) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final id = map['id'] as int?;
        final mode = (map['mode'] ?? 'virtual').toString();
        final isVirtual = mode.toLowerCase() == 'virtual';
        final rawStartTime = map['scheduled_start_time']?.toString() ??
                             map['scheduled_at']?.toString() ??
                             map['scheduledAt']?.toString();
        DateTime? startTime;
        if (rawStartTime != null) {
          startTime = DateTime.tryParse(rawStartTime);
        }

        final timeStr = startTime != null ? _formatTime(startTime) : 'Scheduled';

        final menteeMap = map['mentee'] is Map ? map['mentee'] as Map : null;
        final menteeName = menteeMap != null
            ? (menteeMap['full_name'] ?? menteeMap['fullName'] ?? menteeMap['name'] ?? 'Mentee').toString()
            : (map['session_goals'] ?? 'Mentorship Session').toString();

        final subtitle = isVirtual
            ? 'Virtual Session • Jitsi Meeting'
            : (map['location'] ?? 'In-Person Clinical Visit').toString();

        todaySchedule.add(
          ScheduleItem(
            sessionId: id,
            mode: mode,
            time: timeStr,
            title: menteeName,
            subtitle: subtitle,
            scheduledStartTime: startTime,
            action: isVirtual ? SessionAction.start : SessionAction.details,
          ),
        );
      }

      final fallbackSummary = await _fallback.getDashboardSummary(mentorId);

      return MentorSummary(
        totalMentees: assignmentsLoaded ? totalMentees : fallbackSummary.totalMentees,
        activeSessions: (scheduledData != null || inProgressData != null) ? activeSessions : fallbackSummary.activeSessions,
        logbooksPending: fallbackSummary.logbooksPending,
        todaySchedule: (scheduledData != null || inProgressData != null) ? todaySchedule : fallbackSummary.todaySchedule,
        recentActivity: fallbackSummary.recentActivity,
        activeCycleName: cycleName ?? fallbackSummary.activeCycleName,
      );
    } catch (e, st) {
      debugPrint('[DioMentorRepository] Error fetching dashboard summary: $e\n$st');
      return await _fallback.getDashboardSummary(mentorId);
    }
  }

  Future<dynamic> _fetchAssignments(int mentorId) async {
    try {
      final r = await _dio.get(ApiEndpoints.mentorAssignments(mentorId));
      final list = _extractList(r.data);
      if (list.isNotEmpty) return r.data;
    } catch (_) {}

    try {
      final r = await _dio.get(ApiEndpoints.assignments, queryParameters: {'mentor_id': mentorId});
      return r.data;
    } catch (e) {
      debugPrint('[DioMentorRepository] Failed to fetch mentor assignments: $e');
      return null;
    }
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw;
      if (data is List) return data;
      if (data is Map) {
        for (final key in ['items', 'assignments', 'cycles', 'sessions', 'contacts', 'conversations']) {
          if (data[key] is List) return data[key] as List;
        }
      }
      for (final key in ['items', 'assignments', 'cycles', 'sessions', 'contacts', 'conversations']) {
        if (raw[key] is List) return raw[key] as List;
      }
    }
    return [];
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final standardHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${standardHour.toString().padLeft(2, '0')}:$minute $period';
  }
}
