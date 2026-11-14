import 'package:dio/dio.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../domain/quiz_models.dart';

class QuizRepository {
  QuizRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final d = raw['data'];
      if (d is Map) return Map<String, dynamic>.from(d);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final d = raw['data'];
      if (d is List) {
        return [
          for (final item in d)
            if (item is Map) Map<String, dynamic>.from(item),
        ];
      }
    }
    if (raw is List) {
      return [
        for (final item in raw)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }
    return const [];
  }

  /// Retrieves quiz details including questions and options for a specific quizId.
  /// Endpoint: GET /learning/quizzes/{quizId}
  Future<QuizDetail> getQuiz(int quizId) async {
    try {
      final res = await _dio.get('/learning/quizzes/$quizId');
      final data = _extractData(res.data);
      if (data.isEmpty) {
        throw StateError('Quiz $quizId data not found on server.');
      }
      return QuizDetail.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Retrieves the quiz for a given module.
  /// Endpoint: GET /learning/modules/{moduleId}/quiz
  Future<QuizDetail> getQuizForModule(int moduleId) async {
    try {
      final res = await _dio.get('/learning/modules/$moduleId/quiz');
      final data = _extractData(res.data);
      if (data.isEmpty) {
        throw StateError('Quiz for module $moduleId not found on server.');
      }
      return QuizDetail.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Retrieves the authenticated mentee's past attempts for a quiz.
  /// Endpoint: GET /learning/quizzes/{quizId}/attempts
  Future<List<QuizAttemptItem>> getAttempts(int quizId) async {
    try {
      final res = await _dio.get('/learning/quizzes/$quizId/attempts');
      final list = _extractList(res.data);
      return list.map((item) => QuizAttemptItem.fromJson(item)).toList();
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Retrieves the authenticated mentee's results for a quiz.
  /// Endpoint: GET /learning/quizzes/{quizId}/results
  Future<List<QuizResultItem>> getResults(int quizId) async {
    try {
      final res = await _dio.get('/learning/quizzes/$quizId/results');
      final list = _extractList(res.data);
      return list.map((item) => QuizResultItem.fromJson(item)).toList();
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Starts a new quiz attempt on the backend.
  /// Endpoint: POST /learning/quizzes/{quizId}/start
  Future<void> startAttempt(int quizId) async {
    try {
      await _dio.post('/learning/quizzes/$quizId/start');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Submits answers for an active quiz attempt.
  /// Endpoint: POST /learning/quizzes/{quizId}/submit
  /// Body: { "answers": [ { "questionId": int, "selectedOptionId": int } ] }
  Future<QuizResultItem> submitQuiz(
    int quizId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final res = await _dio.post(
        '/learning/quizzes/$quizId/submit',
        data: {'answers': answers},
      );
      final data = _extractData(res.data);
      return QuizResultItem.fromJson(data);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
