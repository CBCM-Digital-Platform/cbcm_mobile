
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../data/curriculum_repository_provider.dart';
import '../domain/curriculum.dart';

class CurriculumController extends AsyncNotifier<CurriculumProgress> {
  String? _menteeId;

  @override
  Future<CurriculumProgress> build() async {
    final storage = ref.watch(secureStorageProvider);

    _menteeId = await storage.read(StorageKeys.userId);

    return ref
        .watch(curriculumRepositoryProvider)
        .getCurriculumProgress(_menteeId ?? 'unknown');
  }

  /// Marks a lesson's status, updates local state immediately so the UI
  /// reflects it without waiting on a refetch, and persists via the
  /// repository (mocked for now).
  Future<void> setLessonStatus(
    String lessonId, {
    required LessonStatus status,
    double progressPercent = 0,
  }) async {
    final current = state.value;

    if (current == null || _menteeId == null) return;

    final updated = current.updatingLesson(
      lessonId,
      status: status,
      progressPercent: progressPercent,
    );

    state = AsyncData(updated);

    await ref.read(curriculumRepositoryProvider).updateLessonStatus(
          menteeId: _menteeId!,
          lessonId: lessonId,
          status: status,
          progressPercent: progressPercent,
        );
  }

  /// Convenience: marks a lesson fully completed.
  Future<void> completeLesson(String lessonId) =>
      setLessonStatus(
        lessonId,
        status: LessonStatus.completed,
      );

  /// Convenience: marks a lesson as in progress (e.g. tapped to start).
  Future<void> startLesson(String lessonId) =>
      setLessonStatus(
        lessonId,
        status: LessonStatus.inProgress,
        progressPercent: 0,
      );
}

final curriculumControllerProvider =
    AsyncNotifierProvider<CurriculumController, CurriculumProgress>(
  CurriculumController.new,
);
