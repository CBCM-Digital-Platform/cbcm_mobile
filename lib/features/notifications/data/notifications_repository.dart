import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final res = await request();
      final body = res.data;
      return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// GET /notifications
  Future<List<AppNotification>> list() async {
    final body = await _call(() => _dio.get('/notifications'));
    final data = body['data'];
    final list = data is List
        ? data
        : (data is Map
            ? (data['notifications'] ?? data['items'] ?? data['rows'])
            : null);
    return (list is List ? list : const [])
        .whereType<Map>()
        .map((m) => AppNotification.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// GET /notifications/unread-count
  Future<int> unreadCount() async {
    final body = await _call(() => _dio.get('/notifications/unread-count'));
    final data = body['data'];
    if (data is num) return data.toInt();
    if (data is Map) {
      for (final key in const ['count', 'unreadCount', 'unread_count', 'unread', 'total']) {
        final v = data[key];
        if (v is num) return v.toInt();
      }
    }
    return 0;
  }

  /// PATCH /notifications/{id}/read
  Future<void> markRead(int id) async {
    await _call(() => _dio.patch('/notifications/$id/read'));
  }

  /// PATCH /notifications/read-all
  Future<void> markAllRead() async {
    await _call(() => _dio.patch('/notifications/read-all'));
  }

  /// DELETE /notifications/{id}
  Future<void> delete(int id) async {
    await _call(() => _dio.delete('/notifications/$id'));
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

/// The number on the bell. Refreshes itself every minute while visible.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final timer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});
