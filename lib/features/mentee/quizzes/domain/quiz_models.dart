/// Quiz domain models conforming to CBCM backend OpenAPI spec:
/// GET /learning/quizzes/{quizId}
/// GET /learning/quizzes/{quizId}/attempts
/// GET /learning/quizzes/{quizId}/results
/// POST /learning/quizzes/{quizId}/submit

class QuizDetail {
  const QuizDetail({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    this.passScore = 70.0,
    this.timeLimitMinutes,
    this.attemptLimit,
    this.isPublished = true,
    this.isAuthorized = true,
    this.questions = const [],
  });

  final int id;
  final int moduleId;
  final String title;
  final String? description;
  final double passScore;
  final int? timeLimitMinutes;
  final int? attemptLimit;
  final bool isPublished;
  final bool isAuthorized;
  final List<QuizQuestionModel> questions;

  bool get hasAttemptLimit => attemptLimit != null && attemptLimit! > 0;

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final List<QuizQuestionModel> questionsList = [];
    if (rawQuestions is List) {
      for (final q in rawQuestions) {
        if (q is Map) {
          questionsList.add(
            QuizQuestionModel.fromJson(Map<String, dynamic>.from(q)),
          );
        }
      }
    }

    return QuizDetail(
      id: _asInt(json['id']) ?? 0,
      moduleId: _asInt(json['moduleId'] ?? json['module_id']) ?? 0,
      title: json['title']?.toString() ?? 'Clinical Quiz',
      description: json['description']?.toString(),
      passScore:
          _asDouble(json['passScore'] ?? json['passingScore'] ?? json['pass_score']) ??
          70.0,
      timeLimitMinutes: _asInt(json['timeLimitMinutes'] ?? json['time_limit_minutes']),
      attemptLimit: _asInt(json['attemptLimit'] ?? json['attempt_limit']),
      isPublished: json['isPublished'] == true || json['is_published'] == true,
      isAuthorized: json['isAuthorized'] == true || json['is_authorized'] == true,
      questions: questionsList,
    );
  }
}

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.prompt,
    this.questionType = 'single_choice',
    this.clinicalContext,
    this.points = 1.0,
    this.explanation,
    this.orderNumber = 0,
    this.options = const [],
  });

  final int id;
  final String prompt;
  final String questionType;
  final String? clinicalContext;
  final double points;
  final String? explanation;
  final int orderNumber;
  final List<QuizOptionModel> options;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'];
    final List<QuizOptionModel> optsList = [];
    if (rawOpts is List) {
      for (int i = 0; i < rawOpts.length; i++) {
        final opt = rawOpts[i];
        if (opt is Map) {
          optsList.add(
            QuizOptionModel.fromJson(Map<String, dynamic>.from(opt), defaultIndex: i),
          );
        }
      }
    }

    return QuizQuestionModel(
      id: _asInt(json['id']) ?? 0,
      prompt: json['prompt']?.toString() ?? '',
      questionType:
          json['questionType']?.toString() ??
          json['question_type']?.toString() ??
          'single_choice',
      clinicalContext:
          json['clinicalContext']?.toString() ?? json['clinical_context']?.toString(),
      points: _asDouble(json['points']) ?? 1.0,
      explanation: json['explanation']?.toString(),
      orderNumber: _asInt(json['orderNumber'] ?? json['order_number']) ?? 0,
      options: optsList,
    );
  }
}

class QuizOptionModel {
  const QuizOptionModel({
    required this.id,
    required this.text,
    this.label,
    this.orderNumber = 0,
    this.isCorrect,
  });

  final int id;
  final String text;
  final String? label; // 'A', 'B', 'C', 'D'
  final int orderNumber;
  final bool? isCorrect;

  factory QuizOptionModel.fromJson(Map<String, dynamic> json, {int defaultIndex = 0}) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final fallbackLabel =
        defaultIndex < letters.length ? letters[defaultIndex] : '${defaultIndex + 1}';

    return QuizOptionModel(
      id: _asInt(json['id']) ?? 0,
      text: json['text']?.toString() ?? '',
      label: json['label']?.toString() ?? fallbackLabel,
      orderNumber: _asInt(json['orderNumber'] ?? json['order_number']) ?? defaultIndex,
      isCorrect: json['isCorrect'] as bool? ?? json['is_correct'] as bool?,
    );
  }
}

class QuizAttemptItem {
  const QuizAttemptItem({
    required this.id,
    required this.quizId,
    required this.menteeId,
    required this.attemptNumber,
    required this.score,
    required this.passed,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  final int id;
  final int quizId;
  final int menteeId;
  final int attemptNumber;
  final double score;
  final bool passed;
  final String status; // 'in_progress', 'submitted', 'completed'
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory QuizAttemptItem.fromJson(Map<String, dynamic> json) {
    return QuizAttemptItem(
      id: _asInt(json['id']) ?? 0,
      quizId: _asInt(json['quizId'] ?? json['quiz_id']) ?? 0,
      menteeId: _asInt(json['menteeId'] ?? json['mentee_id']) ?? 0,
      attemptNumber: _asInt(json['attemptNumber'] ?? json['attempt_number']) ?? 1,
      score: _asDouble(json['score']) ?? 0.0,
      passed: json['passed'] == true,
      status: json['status']?.toString() ?? 'completed',
      startedAt: _asDateTime(json['startedAt'] ?? json['started_at']),
      completedAt: _asDateTime(json['completedAt'] ?? json['completed_at']),
    );
  }
}

class QuizResultItem {
  const QuizResultItem({
    required this.id,
    required this.quizId,
    required this.menteeId,
    required this.attemptNumber,
    required this.score,
    required this.passed,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.perQuestionReview = const [],
  });

  final int id;
  final int quizId;
  final int menteeId;
  final int attemptNumber;
  final double score;
  final bool passed;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<QuizQuestionReview> perQuestionReview;

  bool get hasQuestionReview => perQuestionReview.isNotEmpty;

  factory QuizResultItem.fromJson(Map<String, dynamic> json) {
    final rawReview = json['questions'] ?? json['review'] ?? json['answers'];
    final List<QuizQuestionReview> reviewList = [];
    if (rawReview is List) {
      for (final r in rawReview) {
        if (r is Map) {
          reviewList.add(
            QuizQuestionReview.fromJson(Map<String, dynamic>.from(r)),
          );
        }
      }
    }

    return QuizResultItem(
      id: _asInt(json['id']) ?? 0,
      quizId: _asInt(json['quizId'] ?? json['quiz_id']) ?? 0,
      menteeId: _asInt(json['menteeId'] ?? json['mentee_id']) ?? 0,
      attemptNumber: _asInt(json['attemptNumber'] ?? json['attempt_number']) ?? 1,
      score: _asDouble(json['score']) ?? 0.0,
      passed: json['passed'] == true,
      status: json['status']?.toString() ?? 'completed',
      startedAt: _asDateTime(json['startedAt'] ?? json['started_at']),
      completedAt: _asDateTime(json['completedAt'] ?? json['completed_at']),
      perQuestionReview: reviewList,
    );
  }
}

class QuizQuestionReview {
  const QuizQuestionReview({
    required this.questionId,
    this.prompt,
    this.selectedOptionId,
    this.selectedOptionText,
    this.isCorrect,
    this.explanation,
  });

  final int questionId;
  final String? prompt;
  final int? selectedOptionId;
  final String? selectedOptionText;
  final bool? isCorrect;
  final String? explanation;

  factory QuizQuestionReview.fromJson(Map<String, dynamic> json) {
    return QuizQuestionReview(
      questionId: _asInt(json['questionId'] ?? json['question_id']) ?? 0,
      prompt: json['prompt']?.toString(),
      selectedOptionId: _asInt(json['selectedOptionId'] ?? json['selected_option_id']),
      selectedOptionText:
          json['selectedOptionText']?.toString() ??
          json['selected_option_text']?.toString(),
      isCorrect: json['isCorrect'] as bool? ?? json['is_correct'] as bool?,
      explanation: json['explanation']?.toString(),
    );
  }
}

// Safe conversion helpers
int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDateTime(dynamic v) {
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
