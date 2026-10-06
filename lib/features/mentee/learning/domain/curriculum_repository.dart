import 'curriculum.dart';

abstract class CurriculumRepository {
  /// Calls a real progress/curriculum endpoint once the backend confirms one.
  Future<CurriculumProgress> getCurriculumProgress(String menteeId);

  /// Calls PATCH/PUT on the real progress endpoint once confirmed.
  /// Persists a single lesson's new status for this mentee.
  Future<void> updateLessonStatus({
    required String menteeId,
    required String lessonId,
    required LessonStatus status,
    double progressPercent = 0,
  });
}