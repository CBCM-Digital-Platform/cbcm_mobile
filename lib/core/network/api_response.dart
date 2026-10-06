/// Matches the backend's shared response envelope:
/// success: {"success": true, "data": {...}, "meta": {...}}
/// error:   {"success": false, "error": {"code", "message", "details"}}
class ApiError {
  const ApiError({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final List<dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'Something went wrong',
      details: json['details'] as List<dynamic>?,
    );
  }
}

/// Thrown by repositories when the backend returns success: false.
class ApiException implements Exception {
  ApiException(this.error);
  final ApiError error;

  @override
  String toString() => error.message;
}