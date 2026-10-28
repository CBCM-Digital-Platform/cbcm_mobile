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

  /// Creates a new logbook entry recorded by a mentor.
  Future<LogbookEntry> createEntry(CreateLogbookRequest request) async {
    try {
      final res = await _dio.post('/logbook', data: request.toJson());
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] as Map : (raw is Map ? raw : null);
      if (data == null) throw StateError('Failed to record logbook entry.');

      final entry = LogbookEntry.fromJson(Map<String, dynamic>.from(data));

      // As the mentor is recording the observed/conducted event directly,
      // transition entry to submitted and approved if possible
      try {
        await _dio.post('/logbook/${entry.id}/submit');
        if (request.mentorFeedback != null && request.mentorFeedback!.isNotEmpty) {
          await _dio.post(
            '/logbook/${entry.id}/approve',
            data: {'mentor_feedback': request.mentorFeedback},
          );
        }
      } catch (e) {
        debugPrint('[LogbookRepository] Note: transition failed (continuing): $e');
      }

      return entry;
    } on DioException catch (e) {
      debugPrint('[LogbookRepository] createEntry failed: ${e.message}');
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

  /// Fetches available thematic areas from the backend with safe fallback.
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
      debugPrint('[LogbookRepository] getThematicAreas fallback: $e');
    }

    return const [
      {'id': 1, 'name': 'Maternal Health & Intrapartum Care'},
      {'id': 2, 'name': 'Newborn Care & Resuscitation'},
      {'id': 3, 'name': 'Emergency Obstetric Care (EmONC)'},
      {'id': 4, 'name': 'Postpartum & Family Planning'},
    ];
  }

  /// Gets the currently active mentorship cycle ID.
  Future<int> getActiveCycleId() async {
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
      debugPrint('[LogbookRepository] getActiveCycleId fallback: $e');
    }
    return 7; // Fallback to live active cycle on server
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
