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
  static const forgotOtp = '/auth/forgot-otp';
  static const resetOtp = '/auth/reset-otp';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/auth/change-password';
  static const session = '/auth/session';

  // Current user
  static const me = '/users/me';
  static const mePreferences = '/users/me/preferences';

  // Knowledge score (current score, shown inline in assessments)
  static const knowledgeTrend = '/progress/knowledge-trend';
  static const progressSummary = '/progress/summary';

  // Assignments
  static const assignments = '/assignments';
  static String mentorAssignments(int mentorId) => '/assignments/mentors/$mentorId/assignments';
  static String menteeAssignments(int menteeId) => '/assignments/mentees/$menteeId/assignments';

  // Mentorship Cycles
  static const mentorshipCycles = '/mentorship-cycles';
  static String cycleDetails(int cycleId) => '/mentorship-cycles/$cycleId';

  // Clinical Sessions
  static const sessions = '/sessions';
  static const sessionAvailableTimes = '/sessions/available-times';
  static String sessionDetails(int id) => '/sessions/$id';
  static String sessionStatus(int id) => '/sessions/$id/status';
  static String sessionNotes(int id) => '/sessions/$id/notes';
  static String sessionJoinToken(int id) => '/sessions/$id/join-token';
  static String sessionParticipantJoin(int id) => '/sessions/$id/participant-join';

  // Notifications
  static const notifications = '/notifications';
  static const notificationsUnreadCount = '/notifications/unread-count';
}