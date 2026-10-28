class AppRoutes {
  AppRoutes._();

  // Public / Shared
  static const home = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const settings = '/settings';
  static const profile = '/profile';
  static const help = '/help';

  // Mentee (inside the bottom navigation bar)
  static const menteeDashboard = '/mentee/dashboard';
  static const menteeLearn = '/mentee/learn';
  static const menteeMessages = '/mentee/messages';
  static const menteeAiAssist = '/mentee/ai-assist';
  static const menteeMentorChat = '/mentee/mentor-chat';

  // Mentee (full-screen pages, outside the bottom bar)
  static const moduleDetail = '/mentee/module-detail';
  static const lessonReader = '/mentee/lesson-reader';
  static const menteeResources = '/mentee/resources';
  static const menteeQuiz = '/mentee/quiz';
  static const menteeLogbook = '/mentee/logbook';
  static const menteeAssessments = '/mentee/assessments';
  static const menteeCertificates = '/mentee/certificates';

  // Mentor (inside the bottom navigation bar)
  static const mentorDashboard = '/mentor/dashboard';
  static const mentorMentees = '/mentor/mentees';
  static const mentorSessions = '/mentor/sessions';
  static const mentorMessages = '/mentor/messages';
  static const mentorAskAi = '/mentor/ask-ai';
}