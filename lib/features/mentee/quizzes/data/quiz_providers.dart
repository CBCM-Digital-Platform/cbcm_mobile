import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/quiz_models.dart';
import 'quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.watch(dioProvider));
});

/// Auto-dispose provider fetching Quiz details by quizId.
final quizDetailProvider =
    FutureProvider.autoDispose.family<QuizDetail, int>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuiz(quizId);
});

/// Auto-dispose provider fetching Quiz details for a given moduleId.
final moduleQuizProvider =
    FutureProvider.autoDispose.family<QuizDetail, int>((ref, moduleId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizForModule(moduleId);
});

/// Auto-dispose provider fetching past attempts for a quiz.
final quizAttemptsProvider =
    FutureProvider.autoDispose.family<List<QuizAttemptItem>, int>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getAttempts(quizId);
});

/// Auto-dispose provider fetching quiz results for a quiz.
final quizResultsProvider =
    FutureProvider.autoDispose.family<List<QuizResultItem>, int>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getResults(quizId);
});

