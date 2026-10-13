import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../env/env_config.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';
import 'api_endpoints.dart';

enum _RefreshResult { refreshed, sessionDead, unreachable }

class DioClient {
  DioClient({this.onSessionExpired}) {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        // Render's free tier sleeps when idle; the first request can be slow.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(StorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: _onError,
      ),
    );
  }

  /// Called when the session can no longer be refreshed. The app clears
  /// the stored session and sends the user back to login.
  final Future<void> Function()? onSessionExpired;

  late final Dio dio;
  final SecureStorage _storage = SecureStorage();

  // One refresh at a time: the backend rotates refresh tokens, so two
  // simultaneous refreshes would invalidate each other.
  Future<_RefreshResult>? _refreshing;

  bool _isAuthPath(String path) =>
      path.contains(ApiEndpoints.login) ||
      path.contains(ApiEndpoints.refreshToken) ||
      path.contains(ApiEndpoints.forgotPassword) ||
      path.contains(ApiEndpoints.resetPassword);

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;

    final shouldTryRefresh = error.response?.statusCode == 401 &&
        !_isAuthPath(options.path) &&
        options.extra['retried'] != true;

    if (!shouldTryRefresh) {
      handler.next(error);
      return;
    }

    debugPrint('[AUTH] ${options.path} returned 401, refreshing token');

    final result = await (_refreshing ??=
        _refreshTokens().whenComplete(() => _refreshing = null));

    switch (result) {
      case _RefreshResult.refreshed:
        try {
          final token = await _storage.read(StorageKeys.accessToken);
          options.headers['Authorization'] = 'Bearer $token';
          options.extra['retried'] = true;

          // Logout sends the refresh token in its body. The old one was
          // just rotated away, so send the new one.
          if (options.path.contains(ApiEndpoints.logout)) {
            final newRefresh = await _storage.read(StorageKeys.refreshToken);
            options.data =
                newRefresh == null ? null : {'refreshToken': newRefresh};
          }

          debugPrint('[AUTH] token refreshed, retrying ${options.path}');
          handler.resolve(await dio.fetch(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      case _RefreshResult.sessionDead:
        debugPrint('[AUTH] refresh rejected, session expired');
        await onSessionExpired?.call();
        handler.next(error);
      case _RefreshResult.unreachable:
        handler.next(error);
    }
  }

  Future<_RefreshResult> _refreshTokens() async {
    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    if (refreshToken == null) return _RefreshResult.sessionDead;

    // A separate Dio without interceptors, so a failed refresh can never
    // trigger another refresh.
    final plain = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await plain.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map || data['accessToken'] == null) {
        return _RefreshResult.sessionDead;
      }

      await _storage.write(
        StorageKeys.accessToken,
        data['accessToken'].toString(),
      );
      if (data['refreshToken'] != null) {
        await _storage.write(
          StorageKeys.refreshToken,
          data['refreshToken'].toString(),
        );
      }
      return _RefreshResult.refreshed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 4xx: the server rejected this refresh token, so the session is over.
      // No answer or 5xx: keep the session and let the user retry later.
      if (status != null && status >= 400 && status < 500) {
        return _RefreshResult.sessionDead;
      }
      return _RefreshResult.unreachable;
    }
  }
}