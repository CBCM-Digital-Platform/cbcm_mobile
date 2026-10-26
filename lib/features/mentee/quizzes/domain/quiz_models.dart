class QuizQuestionSpec {
  const QuizQuestionSpec({required this.id, required this.prompt, required this.options});
  final String id;
  final String prompt;

  /// Option key (A, B, ...) to its text.
  final Map<String, String> options;
}

class QuizSpec {
  const QuizSpec({
    required this.id,
    required this.title,
    required this.passScore,
    required this.questions,
  });
  final String id;
  final String title;
  final int passScore; // percent
  final List<QuizQuestionSpec> questions;
}

class QuizAttemptResult {
  const QuizAttemptResult({
    required this.score,
    required this.passed,
    required this.correct,
    required this.total,
  });
  final int score; // percent
  final bool passed;
  final int correct;
  final int total;
}