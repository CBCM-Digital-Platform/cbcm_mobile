/// Backend endpoint paths, relative to the base URL in .env
/// (which already ends in /api, so don't repeat it here).
///
/// PROVISIONAL: the backend hasn't started. Confirm every path with the
/// backend team before Week 2 and update this file if they differ.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';

  // Current user
  static const me = '/users/me';

  // Knowledge score (current score, shown inline in assessments)
  static const knowledgeScores = '/knowledge-scores';
}