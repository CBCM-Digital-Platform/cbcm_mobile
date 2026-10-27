import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/quiz_models.dart';

class QuizRepository {
  QuizRepository(this._dio);
  final Dio _dio;

  // Maps questionId:letter -> optionId (for backend submission)
  final Map<String, int> _optionIdMap = {};

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  static const _sampleQuiz = QuizSpec(
    id: 'sample',
    title: 'Clinical Knowledge Check',
    passScore: 80,
    questions: [
      QuizQuestionSpec(
        id: 'q1',
        prompt: 'What is the primary indicator of postpartum hemorrhage?',
        options: {
          'A': 'Blood loss exceeding 500 mL after vaginal delivery',
          'B': 'Slight elevation in maternal temperature',
          'C': 'Mild uterine cramping',
          'D': 'Transient tachycardia only',
        },
      ),
      QuizQuestionSpec(
        id: 'q2',
        prompt: 'Which uterotonic is recommended as first-line prophylaxis in AMTSL?',
        options: {
          'A': 'Oxytocin 10 IU IM',
          'B': 'Ergometrine 0.2 mg IV',
          'C': 'Misoprostol 800 mcg sublingual',
          'D': 'Carboprost 0.25 mg IM',
        },
      ),
      QuizQuestionSpec(
        id: 'q3',
        prompt: 'In newborn resuscitation, what is the initial golden-minute step?',
        options: {
          'A': 'Dry, warm, stimulate, and assess breathing',
          'B': 'Immediate chest compressions at 3:1 ratio',
          'C': 'Administer 100% oxygen by mask',
          'D': 'Intubate within 30 seconds',
        },
      ),
    ],
  );

  static const _sampleAnswerKey = {
    'q1': 'A',
    'q2': 'A',
    'q3': 'A',
  };

  /// Loads the quiz for a given module.
  /// First queries the backend GET /learning/modules/{moduleId}/quiz.
  /// If not found or on network failure, falls back to sample quiz.
  Future<QuizSpec> quizForModule(String moduleId) async {
    if (moduleId != 'sample') {
      try {
        final res = await _dio.get('/learning/modules/$moduleId/quiz');
        final raw = res.data;
        final data = raw is Map && raw['data'] is Map ? raw['data'] as Map : (raw is Map ? raw : null);
        if (data != null) {
          final quizId = (data['id'] ?? moduleId).toString();
          final title = (data['title'] ?? 'Module Quiz').toString();
          final passScore = (data['passScore'] ?? data['passingScore'] ?? 80) as num;

          // Start attempt on backend
          try {
            await _dio.post('/learning/quizzes/$quizId/start');
            debugPrint('[QUIZ] Started quiz attempt for quiz $quizId');
          } catch (_) {}

          final rawQuestions = data['questions'];
          final List<QuizQuestionSpec> questions = [];
          if (rawQuestions is List) {
            for (int qi = 0; qi < rawQuestions.length; qi++) {
              final q = rawQuestions[qi];
              if (q is! Map) continue;
              final qId = (q['id'] ?? (qi + 1)).toString();
              final prompt = (q['prompt'] ?? '').toString();
              final rawOptions = q['options'];

              final Map<String, String> optionsMap = {};
              if (rawOptions is List) {
                for (int oi = 0; oi < rawOptions.length; oi++) {
                  final opt = rawOptions[oi];
                  if (opt is! Map) continue;
                  final optId = opt['id'];
                  final letter = oi < _letters.length ? _letters[oi] : '${oi + 1}';
                  final optText = (opt['text'] ?? '').toString();

                  optionsMap[letter] = optText;
                  if (optId is num) {
                    _optionIdMap['$qId:$letter'] = optId.toInt();
                  }
                }
              }

              questions.add(QuizQuestionSpec(
                id: qId,
                prompt: prompt,
                options: optionsMap,
              ));
            }
          }

          if (questions.isNotEmpty) {
            return QuizSpec(
              id: quizId,
              title: title,
              passScore: passScore.toInt(),
              questions: questions,
            );
          }
        }
      } on DioException catch (e) {
        debugPrint('[QUIZ] Backend quiz not available: ${e.message}. Using sample quiz.');
      }
    }

    return _sampleQuiz;
  }

  /// Submits answers to the backend: POST /learning/quizzes/{quizId}/submit.
  /// Falls back to local evaluation if quiz is sample or backend errors.
  Future<QuizAttemptResult> submit(
    QuizSpec quiz,
    Map<String, String> answers,
  ) async {
    if (quiz.id != 'sample') {
      try {
        final submissionAnswers = <Map<String, dynamic>>[];
        for (final entry in answers.entries) {
          final qId = entry.key;
          final letter = entry.value;
          final intQId = int.tryParse(qId);
          final optId = _optionIdMap['$qId:$letter'];

          if (intQId != null) {
            submissionAnswers.add({
              'questionId': intQId,
              'selectedOptionId': optId,
            });
          }
        }

        final res = await _dio.post(
          '/learning/quizzes/${quiz.id}/submit',
          data: {'answers': submissionAnswers},
        );

        final raw = res.data;
        final data = raw is Map && raw['data'] is Map ? raw['data'] as Map : (raw is Map ? raw : null);
        if (data != null) {
          final score = (data['score'] ?? 0) as num;
          final passed = data['passed'] as bool? ?? (score >= quiz.passScore);
          final total = quiz.questions.length;
          final correct = ((score / 100.0) * total).round();

          return QuizAttemptResult(
            score: score.toInt(),
            passed: passed,
            correct: correct,
            total: total,
          );
        }
      } on DioException catch (e) {
        debugPrint('[QUIZ] Submit to backend failed: ${e.message}. Evaluating locally.');
      }
    }

    // Local evaluation for sample quiz or offline fallback
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
