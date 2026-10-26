import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';

class LearningModuleRef {
  const LearningModuleRef({required this.id, required this.title, required this.order});
  final int id;
  final String title;
  final int order;
}

List<Map<String, dynamic>> _items(dynamic raw) {
  final d = raw is Map && raw['data'] != null ? raw['data'] : raw;
  final l = d is List ? d : (d is Map ? (d['items'] ?? d['modules'] ?? d['rows']) : null);
  return l is List
      ? [for (final e in l) if (e is Map) Map<String, dynamic>.from(e)]
      : const [];
}

int? _moduleId(Map<String, dynamic> m) {
  final nested = m['module'] is Map ? m['module'] as Map : null;
  final v = m['module_id'] ?? m['moduleId'] ?? nested?['id'] ?? m['id'];
  return v is num ? v.toInt() : int.tryParse('$v');
}

class ModuleAccessRepository {
  ModuleAccessRepository(this._dio);
  final Dio _dio;

  /// Modules the signed-in mentor may open for mentees.
  Future<List<LearningModuleRef>> modules() async {
    try {
      final items = _items((await _dio.get('/learning/modules')).data);
      debugPrint('[LEARN] modules sample: ${items.isEmpty ? '-' : items.first}');
      final list = <LearningModuleRef>[];
      for (final m in items) {
        final id = _moduleId(m);
        if (id == null) continue;
        final nested = m['module'] is Map ? m['module'] as Map : null;
        final order = m['orderNumber'] ?? m['order_number'] ?? nested?['orderNumber'];
        list.add(LearningModuleRef(
          id: id,
          title: (m['title'] ?? m['name'] ?? nested?['title'] ?? 'Module #$id').toString(),
          order: order is num ? order.toInt() : id,
        ));
      }
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Ids of the modules already open for [menteeId].
  Future<Set<int>> grantedTo(int menteeId) async {
    try {
      final items = _items((await _dio.get('/learning/mentees/$menteeId/modules')).data);
      return {for (final m in items) if (_moduleId(m) != null) _moduleId(m)!};
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> grant(int moduleId, int menteeId) async {
    try {
      await _dio.post('/learning/modules/$moduleId/access', data: {'menteeId': menteeId});
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> revoke(int moduleId, int menteeId) async {
    try {
      await _dio.delete('/learning/modules/$moduleId/access/$menteeId');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}

final moduleAccessRepositoryProvider = Provider<ModuleAccessRepository>(
  (ref) => ModuleAccessRepository(ref.watch(dioProvider)),
);