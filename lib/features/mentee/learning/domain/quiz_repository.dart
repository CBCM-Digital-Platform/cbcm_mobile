import 'quiz.dart';

abstract class QuizRepository {
  /// Calls GET /quizzes?module_id= once the backend confirms it.
  Future<Quiz?> getQuizForModule(String moduleId);

  /// Calls POST /quiz-attempts once confirmed.
  Future<QuizAttempt> submitAttempt({
    required String quizId,
    required Map<String, String> selectedOptionByQuestionId,
  });
}