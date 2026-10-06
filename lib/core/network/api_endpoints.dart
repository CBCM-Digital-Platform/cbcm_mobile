/// Backend endpoint paths, relative to the base URL in .env
/// (which now ends in /api/v1).
///
/// Source: CBCM Backend Task Division & API Documentation Plan.
/// Auth module owned by Developer 1. Still: "draft contracts... must be
/// confirmed against actual implementation" per that doc, so re-check
/// against the real OpenAPI spec once it exists.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh-token';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/auth/change-password';
  static const session = '/auth/session';

  // Current user
  static const me = '/users/me';
  static const mePreferences = '/users/me/preferences';

  // Knowledge score (current score, shown inline in assessments)
  static const knowledgeTrend = '/progress/knowledge-trend';
}