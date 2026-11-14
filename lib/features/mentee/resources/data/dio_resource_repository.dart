import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/learning_resource.dart';
import '../domain/resource_repository.dart';

class DioResourceRepository implements ResourceRepository {
  const DioResourceRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<LearningResource>> getResources() async {
    // 1. Try mentee personal resource assignments first (/learning/my/resources)
    try {
      final myRes = await _dio.get('/learning/my/resources');
      final myRaw = myRes.data;
      final myList = myRaw is Map && myRaw['data'] is List
          ? myRaw['data'] as List
          : (myRaw is List ? myRaw : const []);
      if (myList.isNotEmpty) {
        return myList
            .whereType<Map>()
            .map((item) => _fromResourceJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('[RESOURCES] /learning/my/resources: ${e.message}');
    }

    try {
      // 2. Try standard /resources endpoint (catalog or mentor access)
      final res = await _dio.get(
        '/resources',
        queryParameters: {'limit': 100},
      );
      final raw = res.data;
      final list = raw is Map && raw['data'] is List
          ? raw['data'] as List
          : (raw is List ? raw : const []);

      if (list.isNotEmpty) {
        return list
            .whereType<Map>()
            .map((item) => _fromResourceJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      // 3. If empty, check /hierarchical-resources
      final hRes = await _dio.get(
        '/hierarchical-resources',
        queryParameters: {'limit': 100},
      );
      final hRaw = hRes.data;
      final hList = hRaw is Map && hRaw['data'] is List
          ? hRaw['data'] as List
          : (hRaw is List ? hRaw : const []);

      if (hList.isNotEmpty) {
        return hList
            .whereType<Map>()
            .map((item) => _fromHierarchicalJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      // Return empty list if no resources from backend
      return const <LearningResource>[];
    } on DioException catch (e) {
      debugPrint('[RESOURCES] Backend error: ${e.message}.');
      return const <LearningResource>[];
    }
  }

  @override
  Future<LearningResource?> getResource(String id) async {
    try {
      final res = await _dio.get('/resources/$id');
      final raw = res.data;
      final map = raw is Map && raw['data'] is Map
          ? raw['data'] as Map
          : (raw is Map ? raw : null);
      if (map != null) {
        return _fromResourceJson(Map<String, dynamic>.from(map));
      }
    } on DioException catch (_) {
      try {
        final hRes = await _dio.get('/hierarchical-resources/$id');
        final hRaw = hRes.data;
        final hMap = hRaw is Map && hRaw['data'] is Map
            ? hRaw['data'] as Map
            : (hRaw is Map ? hRaw : null);
        if (hMap != null) {
          return _fromHierarchicalJson(Map<String, dynamic>.from(hMap));
        }
      } catch (_) {}
    }

    final all = await getResources();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> assignToMentee(int menteeId, Set<String> resourceIds) async {
    for (final rId in resourceIds) {
      final intId = int.tryParse(rId);
      if (intId == null) continue;
      try {
        await _dio.post('/resources/$intId/mentees/$menteeId');
      } on DioException catch (e) {
        debugPrint('[ASSIGN] assign resource $intId to mentee $menteeId: ${e.message}');
      }
    }
  }

  @override
  Future<void> setStarred(String resourceId, bool starred) async {
    // Starred state is maintained per-user in secure storage on the phone.
  }

  LearningResource _fromResourceJson(Map<String, dynamic> raw) {
    final res = raw['resource'] is Map ? raw['resource'] as Map : null;
    final j = res != null ? Map<String, dynamic>.from(res) : raw;

    final id = (j['id'] ?? raw['resourceId'] ?? raw['resource_id'] ?? '').toString();
    final title = (j['title'] ?? 'Learning Resource').toString();
    final type = _parseType(j['type']);

    final category = j['thematicArea'] is Map
        ? (j['thematicArea']['name'] ?? 'General').toString()
        : (j['thematic_area'] is Map
            ? (j['thematic_area']['name'] ?? 'General').toString()
            : (j['module'] is Map
                ? (j['module']['title'] ?? 'General').toString()
                : (j['category'] ?? 'General').toString()));

    final fileMap = j['file'] is Map ? j['file'] as Map : null;
    final sizeBytes = (fileMap?['sizeBytes'] ??
            fileMap?['size_bytes'] ??
            j['file_size_bytes'] ??
            j['sizeBytes'] ??
            0) as num;

    final desc = (j['description'] ??
            (j['module'] is Map ? j['module']['title'] : ''))
        .toString();

    final directUrl = j['url']?.toString();
    final downloadUrl = (directUrl != null && directUrl.trim().isNotEmpty)
        ? directUrl
        : '/resources/$id/content';

    return LearningResource(
      id: id,
      title: title,
      type: type,
      category: category,
      sizeBytes: sizeBytes.toInt(),
      description: desc,
      downloadUrl: downloadUrl,
    );
  }

  LearningResource _fromHierarchicalJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    final title = (j['title'] ?? '').toString();
    final type = _parseType(j['type']);
    final desc = (j['description'] ?? '').toString();

    final uploadedFile = j['uploadedFile'] is Map ? j['uploadedFile'] as Map : null;
    final sizeBytes = (uploadedFile?['size_bytes'] ??
            j['file_size_bytes'] ??
            0) as num;

    final downloadUrl = '/hierarchical-resources/$id/content';

    return LearningResource(
      id: id,
      title: title,
      type: type,
      category: 'Clinical Protocols',
      sizeBytes: sizeBytes.toInt(),
      description: desc,
      downloadUrl: downloadUrl,
    );
  }

  ResourceType _parseType(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    if (s == 'pdf') return ResourceType.pdf;
    if (s == 'video' || s == 'mp4') return ResourceType.video;
    if (s == 'audio' || s == 'mp3') return ResourceType.audio;
    return ResourceType.other;
  }
}
