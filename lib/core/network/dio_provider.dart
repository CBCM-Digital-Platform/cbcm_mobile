import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/current_role_provider.dart';
import 'dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient(
    // Clears the stored session and the role; the router then sends the
    // user to the login screen.
    onSessionExpired: () => ref.read(currentRoleProvider.notifier).logout(),
  ).dio;

  if (!kReleaseMode) dio.interceptors.add(_TimingInterceptor());
  return dio;
});

/// Prints how long every request took, so slow ones are easy to spot.
class _TimingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['t0'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode ?? err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions o, Object? status) {
    final t0 = o.extra['t0'];
    final ms = t0 is int ? DateTime.now().millisecondsSinceEpoch - t0 : -1;
    debugPrint('[HTTP] ${o.method} ${o.path} -> $status in ${ms}ms');
  }
}