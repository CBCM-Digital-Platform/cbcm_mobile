class QuizOption {
  const QuizOption({required this.id, required this.text, required this.isCorrect});

  final String id;
  final String text;
  final bool isCorrect;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    this.clinicalContext,
    required this.options,
  });

  final String id;
  final String prompt;
  final String? clinicalContext;
  final List<QuizOption> options;
}

class Quiz {
  const Quiz({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.questions,
    this.passingScorePercent = 80,
  });

  final String id;
  final String moduleId;
  final String title;
  final List<QuizQuestion> questions;
  final double passingScorePercent;
}

class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.score,
    required this.passed,
    required this.attemptedAt,
  });

  final String quizId;
  final double score;
  final bool passed;
  final DateTime attemptedAt;
}