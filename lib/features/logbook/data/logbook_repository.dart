import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/logbook_entry.dart';

class LogbookRepository {
  LogbookRepository(this._dio);

  final Dio _dio;

  /// Retrieves logbook entries filtered by menteeId and/or status.
  Future<List<LogbookEntry>> getEntries({int? menteeId, String? status}) async {
    try {
      final query = <String, dynamic>{'limit': 100};
      if (menteeId != null) query['mentee_id'] = menteeId;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final res = await _dio.get('/logbook', queryParameters: query);
      final raw = res.data;
      final list = _extractList(raw);

      return list
          .whereType<Map>()
          .map((m) => LogbookEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] getEntries failed: ${e.message}');
      throw apiExceptionFromDio(e);
    } catch (e) {
      debugPrint('[LogbookRepository] getEntries error: $e');
      return [];
    }
  }

  /// Retrieves a specific logbook entry by ID with related data.
  Future<LogbookEntry> getEntry(int id) async {
    try {
      final res = await _dio.get('/logbook/$id');
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map
          ? raw['data'] as Map
          : (raw is Map ? raw : null);
      if (data == null) throw StateError('Logbook entry not found.');
      return LogbookEntry.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] getEntry failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Creates a new logbook entry recorded by a mentee.
  Future<LogbookEntry> createEntry(CreateLogbookRequest request) async {
    try {
      final res = await _dio.post('/logbook', data: request.toJson());
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map
          ? raw['data'] as Map
          : (raw is Map ? raw : null);
      if (data == null) throw StateError('Failed to record logbook entry.');

      final entry = LogbookEntry.fromJson(Map<String, dynamic>.from(data));

      if (request.submitImmediately && entry.id > 0) {
        try {
          await submitEntry(entry.id);
        } catch (e) {
          debugPrint('[LogbookRepository] Immediate submit failed: $e');
        }
      }

      return entry;
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] createEntry failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Submits a draft logbook entry for mentor review.
  Future<void> submitEntry(int id) async {
    try {
      await _dio.post('/logbook/$id/submit');
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] submitEntry failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Updates only changed fields on a draft or revision_requested logbook entry.
  Future<LogbookEntry> patchEntry(int id, Map<String, dynamic> delta) async {
    try {
      final res = await _dio.patch('/logbook/$id', data: delta);
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map
          ? raw['data'] as Map
          : (raw is Map ? raw : null);
      if (data == null) throw StateError('Failed to update logbook entry.');

      return LogbookEntry.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] patchEntry failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Approves a submitted logbook entry (mentor only).
  Future<void> approveEntry(int id, {String? mentorFeedback}) async {
    try {
      final data = <String, dynamic>{};
      if (mentorFeedback != null && mentorFeedback.isNotEmpty) {
        data['mentor_feedback'] = mentorFeedback;
      }
      await _dio.post('/logbook/$id/approve', data: data.isEmpty ? null : data);
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] approveEntry failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Requests revision for a submitted logbook entry with a comment (mentor only).
  Future<void> requestRevision(int id, {String? comment, String? revisionReason}) async {
    final text = comment ?? revisionReason ?? '';
    try {
      await _dio.post(
        '/logbook/$id/request-revision',
        data: {
          'revision_reason': text,
          'mentor_feedback': text,
        },
      );
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] requestRevision failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Gets logbook progress summary (status counts and approved hours) for a mentee.
  Future<Map<String, dynamic>> getProgress(int menteeId) async {
    try {
      final res = await _dio.get('/logbook/progress/$menteeId');
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] getProgress failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Fetches thematic areas assigned to a specific mentorship cycle.
  Future<List<Map<String, dynamic>>> getThematicAreasForCycle(int cycleId) async {
    try {
      final res = await _dio.get('/mentorship-cycles/$cycleId/thematic-areas');
      final list = _extractList(res.data);
      if (list.isNotEmpty) {
        return list.whereType<Map>().map((m) {
          final id = (m['thematic_area_id'] ?? m['thematicAreaId'] ?? m['id']) as num?;
          final name = (m['name'] ?? m['title'] ?? m['thematic_area_name'] ?? 'Thematic Area').toString();
          return {
            'id': id?.toInt() ?? 1,
            'name': name,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('[LogbookRepository] getThematicAreasForCycle failed: $e');
    }
    return getThematicAreas();
  }

  /// Fetches available thematic areas from the backend with no seed fallback.
  Future<List<Map<String, dynamic>>> getThematicAreas() async {
    try {
      final res = await _dio.get('/thematic-areas');
      final list = _extractList(res.data);
      if (list.isNotEmpty) {
        return list
            .whereType<Map>()
            .map((m) => {
                  'id': (m['id'] as num?)?.toInt() ?? 1,
                  'name': (m['name'] ?? m['title'] ?? 'Thematic Area').toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint('[LogbookRepository] getThematicAreas failed: $e');
    }

    return const [];
  }

  /// Gets the currently active mentorship cycle ID.
  Future<int?> getActiveCycleId() async {
    try {
      final res = await _dio.get('/mentorship-cycles');
      final list = _extractList(res.data);
      for (final item in list) {
        if (item is Map && (item['status'] == 'active' || item['is_active'] == true)) {
          final id = (item['id'] as num?)?.toInt();
          if (id != null) return id;
        }
      }
      if (list.isNotEmpty && list.first is Map) {
        final id = (list.first['id'] as num?)?.toInt();
        if (id != null) return id;
      }
    } catch (e) {
      debugPrint('[LogbookRepository] getActiveCycleId error: $e');
    }
    return null;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw;
      if (data is List) return data;
      const keys = ['items', 'entries', 'logbooks', 'thematic_areas'];
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
}
