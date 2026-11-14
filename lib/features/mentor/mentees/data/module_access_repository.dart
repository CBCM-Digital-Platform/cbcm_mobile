import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';

class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    this.description,
    this.protocolSummary,
    this.thematicAreaId,
    this.thematicAreaName,
    this.orderNumber = 0,
    this.status = 'published',
    this.estimatedDurationMinutes,
    this.isPublished = true,
    this.isAuthorized = true,
  });

  final int id;
  final String title;
  final String? description;
  final String? protocolSummary;
  final int? thematicAreaId;
  final String? thematicAreaName;
  final int orderNumber;
  final String status;
  final int? estimatedDurationMinutes;
  final bool isPublished;
  final bool isAuthorized;

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    final thematic = json['thematicArea'] is Map
        ? json['thematicArea'] as Map
        : (json['thematic_area'] is Map ? json['thematic_area'] as Map : null);

    return ModuleItem(
      id: _asInt(json['id'] ?? json['moduleId'] ?? json['module_id']) ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Module',
      description: json['description']?.toString(),
      protocolSummary:
          json['protocolSummary']?.toString() ?? json['protocol_summary']?.toString(),
      thematicAreaId:
          _asInt(json['thematicAreaId'] ?? json['thematic_area_id'] ?? thematic?['id']),
      thematicAreaName:
          thematic?['name']?.toString() ?? thematic?['title']?.toString(),
      orderNumber: _asInt(json['orderNumber'] ?? json['order_number']) ?? 0,
      status: json['status']?.toString() ?? 'published',
      estimatedDurationMinutes: _asInt(
        json['estimatedDurationMinutes'] ?? json['estimated_duration_minutes'],
      ),
      isPublished: json['isPublished'] == true || json['is_published'] == true,
      isAuthorized: json['isAuthorized'] == true || json['is_authorized'] == true,
    );
  }
}

class ModuleResourceItem {
  const ModuleResourceItem({
    required this.id,
    required this.title,
    required this.type,
    this.moduleId,
    this.thematicAreaId,
    this.thematicAreaName,
    this.fileSize,
    this.mimeType,
    this.fileName,
    this.url,
    this.isContent = false,
  });

  final int id;
  final String title;
  final String type; // 'pdf', 'audio', 'video', 'article', 'quiz'
  final int? moduleId;
  final int? thematicAreaId;
  final String? thematicAreaName;
  final int? fileSize;
  final String? mimeType;
  final String? fileName;
  final String? url;
  final bool isContent;

  factory ModuleResourceItem.fromContentJson(Map<String, dynamic> json) {
    final file = json['file'] is Map ? json['file'] as Map : null;
    final rawSize = file?['size_bytes'] ?? file?['sizeBytes'] ?? json['size_bytes'];
    final size = rawSize is int ? rawSize : int.tryParse('$rawSize');

    return ModuleResourceItem(
      id: _asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? file?['original_name']?.toString() ?? 'Resource',
      type: json['type']?.toString().toLowerCase() ?? 'pdf',
      moduleId: _asInt(json['moduleId'] ?? json['module_id']),
      fileSize: size,
      mimeType: file?['mime_type']?.toString() ?? file?['mimeType']?.toString(),
      fileName: file?['original_name']?.toString() ?? file?['name']?.toString(),
      url: json['content_url']?.toString() ?? json['contentUrl']?.toString(),
      isContent: true,
    );
  }

  factory ModuleResourceItem.fromResourceJson(Map<String, dynamic> json) {
    final file = json['file'] is Map ? json['file'] as Map : null;
    final thematic = json['thematicArea'] is Map
        ? json['thematicArea'] as Map
        : (json['thematic_area'] is Map ? json['thematic_area'] as Map : null);
    final rawSize = file?['size_bytes'] ??
        file?['sizeBytes'] ??
        json['file_size_bytes'] ??
        json['sizeBytes'];
    final size = rawSize is int ? rawSize : int.tryParse('$rawSize');

    return ModuleResourceItem(
      id: _asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Resource',
      type: json['type']?.toString().toLowerCase() ?? 'pdf',
      moduleId: _asInt(json['moduleId'] ?? json['module_id']),
      thematicAreaId: _asInt(
          json['thematicAreaId'] ?? json['thematic_area_id'] ?? thematic?['id']),
      thematicAreaName:
          thematic?['name']?.toString() ?? thematic?['title']?.toString(),
      fileSize: size,
      mimeType: json['mimeType']?.toString() ??
          json['mime_type']?.toString() ??
          file?['mimeType']?.toString(),
      fileName: file?['original_name']?.toString() ?? file?['name']?.toString(),
      url: json['url']?.toString(),
      isContent: false,
    );
  }
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class ModuleAccessRepository {
  ModuleAccessRepository(this._dio);
  final Dio _dio;

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final d = raw['data'];
      if (d is List) {
        return [
          for (final e in d)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    }
    if (raw is List) {
      return [
        for (final e in raw)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    return const [];
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  /// List available modules for mentor.
  /// GET /learning/modules
  Future<List<ModuleItem>> getModules() async {
    try {
      final res = await _dio.get('/learning/modules');
      final list = _extractList(res.data);
      final modules = list.map((m) => ModuleItem.fromJson(m)).toList();
      modules.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
      return modules;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Get module details.
  /// GET /learning/modules/{id}
  Future<ModuleItem> getModuleDetails(int moduleId) async {
    try {
      final res = await _dio.get('/learning/modules/$moduleId');
      final data = _extractData(res.data);
      return ModuleItem.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// List modules assigned to a mentee.
  /// GET /learning/mentees/{menteeId}/modules
  Future<Set<int>> getMenteeAssignedModules(int menteeId) async {
    try {
      final res = await _dio.get('/learning/mentees/$menteeId/modules');
      final list = _extractList(res.data);
      return {
        for (final m in list)
          if (_asInt(m['moduleId'] ?? m['module_id'] ?? m['id']) != null)
            _asInt(m['moduleId'] ?? m['module_id'] ?? m['id'])!,
      };
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Assign a complete module to a mentee.
  /// POST /learning/modules/{moduleId}/assignments
  Future<void> assignFullModule(int moduleId, int menteeId) async {
    try {
      await _dio.post(
        '/learning/modules/$moduleId/assignments',
        data: {'menteeId': menteeId},
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Revoke a mentee's complete module assignment.
  /// DELETE /learning/modules/{moduleId}/mentees/{menteeId}/assignment
  Future<void> revokeFullModule(int moduleId, int menteeId) async {
    try {
      await _dio.delete(
        '/learning/modules/$moduleId/mentees/$menteeId/assignment',
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// List all resources belonging to a module.
  /// Combines module curriculum contents (PDFs, videos, articles, guides)
  /// and standalone resources.
  Future<List<ModuleResourceItem>> getModuleResources(int moduleId) async {
    final List<ModuleResourceItem> items = [];
    final Set<int> seenIds = {};

    // 1. Fetch authored module contents / materials
    try {
      final cRes = await _dio.get('/learning/modules/$moduleId/contents');
      final cList = _extractList(cRes.data);
      for (final c in cList) {
        final item = ModuleResourceItem.fromContentJson(c);
        if (item.id != 0 && seenIds.add(item.id)) {
          items.add(item);
        }
      }
    } on DioException catch (e) {
      debugPrint('[MODULE_RESOURCES] contents error: ${e.message}');
    }

    // 2. Fetch standalone module resources
    try {
      final rRes = await _dio.get(
        '/resources',
        queryParameters: {'module_id': moduleId, 'limit': 100},
      );
      final rList = _extractList(rRes.data);
      for (final r in rList) {
        final item = ModuleResourceItem.fromResourceJson(r);
        if (item.id != 0 && seenIds.add(item.id)) {
          items.add(item);
        }
      }
    } on DioException catch (e) {
      debugPrint('[MODULE_RESOURCES] resources error: ${e.message}');
    }

    return items;
  }

  /// List active resource assignments for a mentee.
  /// GET /learning/mentees/{menteeId}/resources
  Future<Set<int>> getMenteeAssignedResourceIds(int menteeId) async {
    try {
      final res = await _dio.get('/learning/mentees/$menteeId/resources');
      final list = _extractList(res.data);
      final assigned = <int>{};
      for (final item in list) {
        final status = item['status']?.toString().toLowerCase();
        if (status != 'revoked' && item['revoked'] != true) {
          final rId = _asInt(
            item['resourceId'] ??
                item['resource_id'] ??
                item['id'] ??
                (item['resource'] is Map ? item['resource']['id'] : null),
          );
          if (rId != null) assigned.add(rId);
        }
      }
      return assigned;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Assign a single resource to a mentee.
  /// POST /resources/{id}/mentees/{menteeId} or module endpoint
  Future<void> assignResourceToMentee(int resourceId, int menteeId,
      {int? moduleId}) async {
    try {
      if (moduleId != null) {
        try {
          await _dio.post(
            '/learning/modules/$moduleId/resources/$resourceId/assignments',
            data: {'mentee_id': menteeId},
          );
          return;
        } catch (_) {}

        try {
          await _dio.post(
            '/learning/modules/$moduleId/assignments',
            data: {'menteeId': menteeId},
          );
          return;
        } catch (_) {}
      }

      await _dio.post('/resources/$resourceId/mentees/$menteeId');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Revoke a single resource assignment from a mentee.
  /// DELETE /resources/{id}/mentees/{menteeId}
  Future<void> revokeResourceFromMentee(int resourceId, int menteeId,
      {int? moduleId}) async {
    try {
      try {
        await _dio.delete('/resources/$resourceId/mentees/$menteeId');
      } catch (_) {}

      if (moduleId != null) {
        try {
          await _dio.delete(
              '/learning/modules/$moduleId/mentees/$menteeId/assignment');
        } catch (_) {}
      }
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}

final moduleAccessRepositoryProvider = Provider<ModuleAccessRepository>(
  (ref) => ModuleAccessRepository(ref.watch(dioProvider)),
);

/// Auto-dispose providers for reactive UI
final mentorAvailableModulesProvider =
    FutureProvider.autoDispose<List<ModuleItem>>((ref) async {
  final repo = ref.watch(moduleAccessRepositoryProvider);
  return repo.getModules();
});

final menteeAssignedModulesProvider =
    FutureProvider.autoDispose.family<Set<int>, int>((ref, menteeId) async {
  final repo = ref.watch(moduleAccessRepositoryProvider);
  return repo.getMenteeAssignedModules(menteeId);
});

final moduleResourcesProvider =
    FutureProvider.autoDispose.family<List<ModuleResourceItem>, int>(
        (ref, moduleId) async {
  final repo = ref.watch(moduleAccessRepositoryProvider);
  return repo.getModuleResources(moduleId);
});

final menteeAssignedResourceIdsProvider =
    FutureProvider.autoDispose.family<Set<int>, int>((ref, menteeId) async {
  final repo = ref.watch(moduleAccessRepositoryProvider);
  return repo.getMenteeAssignedResourceIds(menteeId);
});

final moduleDetailsProvider =
    FutureProvider.autoDispose.family<ModuleItem, int>((ref, moduleId) async {
  final repo = ref.watch(moduleAccessRepositoryProvider);
  return repo.getModuleDetails(moduleId);
});
