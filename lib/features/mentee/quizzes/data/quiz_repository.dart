import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/quiz_models.dart';

const _sampleQuiz = QuizSpec(
  id: 'sample',
  title: 'Clinical Practice Quiz',
  passScore: 80,
  questions: [
    QuizQuestionSpec(
      id: 'q1',
      prompt:
          'What is the first line of intervention for postpartum hemorrhage due to uterine atony?',
      options: {
        'A': 'Immediate surgical intervention',
        'B': 'Bimanual uterine compression and oxytocin administration',
        'C': 'Administer IV broad-spectrum antibiotics',
        'D': 'Bed rest with continuous monitoring',
      },
    ),
    QuizQuestionSpec(
      id: 'q2',
      prompt:
          'During active labor, what is the normal baseline fetal heart rate range between contractions?',
      options: {
        'A': '80–100 beats per minute',
        'B': '110–160 beats per minute',
        'C': '160–200 beats per minute',
        'D': '60–90 beats per minute',
      },
    ),
    QuizQuestionSpec(
      id: 'q3',
      prompt:
          'Which sign indicates effective neonatal resuscitation within the first 60 seconds (Golden Minute)?',
      options: {
        'A': 'Weak, irregular gasping',
        'B': 'Peripheral cyanosis only',
        'C': 'Prompt increase in heart rate above 100 bpm and spontaneous breathing',
        'D': 'Absence of reflex irritability',
      },
    ),
    QuizQuestionSpec(
      id: 'q4',
      prompt:
          'What is the recommended timing for initiating immediate skin-to-skin contact after an uncomplicated birth?',
      options: {
        'A': 'Immediately within the first minute of birth',
        'B': 'After bathing and weighing the newborn',
        'C': '4 to 6 hours after delivery',
        'D': 'Only after the mother has rested',
      },
    ),
    QuizQuestionSpec(
      id: 'q5',
      prompt:
          'Which clinical feature is a primary danger sign requiring urgent referral during antenatal triage?',
      options: {
        'A': 'Mild morning nausea during the first trimester',
        'B': 'Severe persistent headache with blurred vision and elevated BP',
        'C': 'Occasional painless Braxton Hicks contractions',
        'D': 'Mild bilateral ankle edema in late third trimester',
      },
    ),
  ],
);

const _sampleAnswerKey = {
  'q1': 'B',
  'q2': 'B',
  'q3': 'C',
  'q4': 'A',
  'q5': 'B',
};

class QuizRepository {
  QuizRepository(this._dio);
  final Dio _dio;

  Future<QuizSpec> quizForModule(String moduleId) async {
    if (moduleId == 'sample' || moduleId.isEmpty) {
      return _sampleQuiz;
    }

    try {
      final response = await _dio.get(
        '/quizzes',
        queryParameters: {'module_id': moduleId},
      );
      final raw = response.data;
      final data = raw is Map && raw['data'] != null ? raw['data'] : raw;
      if (data is Map) {
        return _parseQuiz(Map<String, dynamic>.from(data));
      }
    } on DioException catch (_) {
      // Backend endpoint may not be implemented yet; fallback to sample quiz.
    }
    return _sampleQuiz;
  }

  QuizSpec _parseQuiz(Map<String, dynamic> data) {
    final rawQuestions = data['questions'] as List? ?? [];
    final questions = <QuizQuestionSpec>[];
    for (final q in rawQuestions) {
      if (q is Map) {
        final rawOptions = q['options'];
        final options = <String, String>{};
        if (rawOptions is Map) {
          rawOptions.forEach((k, v) => options[k.toString()] = v.toString());
        } else if (rawOptions is List) {
          for (var i = 0; i < rawOptions.length; i++) {
            final opt = rawOptions[i];
            final key = String.fromCharCode(65 + i);
            options[key] = opt is Map
                ? (opt['text'] ?? opt['label'] ?? '').toString()
                : opt.toString();
          }
        }
        questions.add(QuizQuestionSpec(
          id: (q['id'] ?? questions.length.toString()).toString(),
          prompt: (q['prompt'] ?? q['question'] ?? '').toString(),
          options: options,
        ));
      }
    }
    return QuizSpec(
      id: (data['id'] ?? 'quiz').toString(),
      title: (data['title'] ?? 'Module Quiz').toString(),
      passScore: (data['passScore'] ?? data['pass_score'] ?? 80) is num
          ? (data['passScore'] ?? data['pass_score'] ?? 80).toInt()
          : 80,
      questions: questions.isNotEmpty ? questions : _sampleQuiz.questions,
    );
  }

  Future<QuizAttemptResult> submit(
    QuizSpec quiz,
    Map<String, String> answers,
  ) async {
    if (quiz.id != 'sample') {
      try {
        final response = await _dio.post(
          '/quiz-attempts',
          data: {
            'quiz_id': quiz.id,
            'answers': answers,
          },
        );
        final raw = response.data;
        final data = raw is Map && raw['data'] != null ? raw['data'] : raw;
        if (data is Map) {
          final score = (data['score'] ?? 0) as num;
          final passed = data['passed'] as bool? ?? (score >= quiz.passScore);
          final correct = (data['correct'] ?? 0) as num;
          final total = (data['total'] ?? quiz.questions.length) as num;
          return QuizAttemptResult(
            score: score.toInt(),
            passed: passed,
            correct: correct.toInt(),
            total: total.toInt(),
          );
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          throw apiExceptionFromDio(e);
        }
      }
    }

    // Local evaluation for sample quiz or when backend is unavailable
    var correct = 0;
    for (final q in quiz.questions) {
      if (answers[q.id] != null && answers[q.id] == _sampleAnswerKey[q.id]) {
        correct++;
      }
    }
    final total = quiz.questions.length;
    final score = total > 0 ? ((correct / total) * 100).round() : 0;
    final passed = score >= quiz.passScore;
    return QuizAttemptResult(
      score: score,
      passed: passed,
      correct: correct,
      total: total,
    );
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.watch(dioProvider));
});
