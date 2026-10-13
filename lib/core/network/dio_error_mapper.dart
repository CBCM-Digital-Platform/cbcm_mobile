import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_response.dart';

/// Converts a failed Dio request into the app's ApiException, so screens
/// show the backend's real message (e.g. "Invalid email or password.")
/// and never need to know about Dio.
ApiException apiExceptionFromDio(DioException e) {
  debugPrint('[NETWORK] type=${e.type} status=${e.response?.statusCode} '
      'url=${e.requestOptions.uri} error=${e.error} message=${e.message}');

  final data = e.response?.data;

  // The backend answered with its standard error envelope.
  if (data is Map && data['error'] is Map) {
    return ApiException(
      ApiError.fromJson(Map<String, dynamic>.from(data['error'] as Map)),
    );
  }

  // No answer at all (no internet, server asleep, timeout, TLS problem).
  if (e.response == null) {
    return ApiException(
      const ApiError(
        code: 'NETWORK_ERROR',
        message: 'Cannot reach the server. Check your connection and try again.',
      ),
    );
  }

  return ApiException(
    const ApiError(
      code: 'UNKNOWN_ERROR',
      message: 'Something went wrong. Please try again.',
    ),
  );
}