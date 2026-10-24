import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../domain/session_model.dart';
import '../domain/sessions_repository.dart';

class DioSessionsRepository implements SessionsRepository {
  DioSessionsRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map) {
      final data = raw['data'];
      return Map<String, dynamic>.from(data is Map ? data : raw);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw;
      if (data is List) return data;
      if (data is Map) {
        for (final key in ['items', 'sessions']) {
          if (data[key] is List) return data[key] as List;
        }
      }
      for (final key in ['items', 'sessions']) {
        if (raw[key] is List) return raw[key] as List;
      }
    }
    return [];
  }

  @override
  Future<List<SessionModel>> getSessions({
    int? mentorId,
    int? menteeId,
    String? status,
    String? mode,
  }) async {
    final query = <String, dynamic>{'limit': 50};
    if (mentorId != null) query['mentor_id'] = mentorId;
    if (menteeId != null) query['mentee_id'] = menteeId;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (mode != null && mode.isNotEmpty) query['mode'] = mode;

    try {
      final response =
          await _dio.get(ApiEndpoints.sessions, queryParameters: query);
      return _list(response.data)
          .whereType<Map>()
          .map((m) => SessionModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<SessionModel> getSessionDetails(int sessionId) async {
    try {
      final response = await _dio.get(ApiEndpoints.sessionDetails(sessionId));
      return SessionModel.fromJson(_map(response.data));
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<SessionModel> createSession(Map<String, dynamic> sessionData) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.sessions, data: sessionData);
      return SessionModel.fromJson(_map(response.data));
    } on DioException catch (e) {
      debugPrint('[SESSION] create failed: status=${e.response?.statusCode} '
          'body=${e.response?.data}');
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<JitsiJoinToken> getJoinToken(int sessionId) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.sessionJoinToken(sessionId));
      return JitsiJoinToken.fromJson(_map(response.data));
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<AvailableTimes> getAvailableTimes({
    required int assignmentId,
    required DateTime date,
    int durationMinutes = 45,
  }) async {
    final day = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _dio.get(
        ApiEndpoints.sessionAvailableTimes,
        queryParameters: {
          'assignment_id': assignmentId,
          'date': day,
          'duration_minutes': durationMinutes,
        },
      );
      // Printed so the real response shape can be confirmed.
      debugPrint('[TIMES] ${response.data}');

      final slots = _parseSlots(response.data);
      if (slots != null) return AvailableTimes(slots: slots, checked: true);
    } on DioException catch (e) {
      debugPrint('[TIMES] failed: status=${e.response?.statusCode} '
          'body=${e.response?.data}');
    } catch (e) {
      debugPrint('[TIMES] could not read the response: $e');
    }
    return const AvailableTimes(slots: [], checked: false);
  }

  /// Reads the free start times from whatever shape the server uses: a list
  /// of "09:30" / "9:30 AM" / ISO timestamps, or a list of objects holding
  /// one. Returns null if no list can be found or none of it can be read.
  List<TimeSlot>? _parseSlots(dynamic raw) {
    dynamic list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final data = raw['data'] ?? raw;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        for (final key in const [
          'slots',
          'available_times',
          'availableTimes',
          'times',
          'items',
        ]) {
          if (data[key] is List) {
            list = data[key];
            break;
          }
        }
      }
    }
    if (list is! List) return null;
    if (list.isEmpty) return const [];

    final found = <TimeSlot>{};
    for (final entry in list) {
      String? text;
      if (entry is String) {
        text = entry;
      } else if (entry is Map) {
        if (entry['available'] == false) continue;
        for (final key in const [
          'start',
          'start_time',
          'startTime',
          'starts_at',
          'time',
          'slot',
          'scheduled_at',
        ]) {
          if (entry[key] != null) {
            text = entry[key].toString();
            break;
          }
        }
      }
      final slot = text == null ? null : _slotFrom(text);
      if (slot != null) found.add(slot);
    }

    if (found.isEmpty) return null; // a list we could not understand
    final sorted = found.toList()
      ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return sorted;
  }

  TimeSlot? _slotFrom(String input) {
    final text = input.trim();

    // A full timestamp: use the phone's local time.
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      final local = parsed.toLocal();
      return TimeSlot(hour: local.hour, minute: local.minute);
    }

    // "09:30", "9:30", "09:30:00", "9:30 AM"
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?$')
        .firstMatch(text);
    if (m == null) return null;

    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final suffix = m.group(3)?.toUpperCase();
    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return TimeSlot(hour: hour, minute: minute);
  }

  @override
  Future<void> updateSessionStatus(int sessionId, String status) async {
    try {
      await _dio.patch(
        ApiEndpoints.sessionStatus(sessionId),
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}