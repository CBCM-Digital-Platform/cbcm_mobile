import '../domain/curriculum.dart';
import '../domain/curriculum_repository.dart';
import 'curriculum_seed_data.dart';

/// MOCKED. Real data will come from the backend's progress/curriculum
/// endpoints once confirmed. Fake data itself lives in CurriculumSeedData.
/// Holds an in-memory copy per mentee so changes persist for the rest of
/// the app session (resets on full app restart, since there's no backend
/// or local DB wired in yet).
class MockCurriculumRepository implements CurriculumRepository {
  final Map<String, CurriculumProgress> _byMentee = {};

  CurriculumProgress _seedFor(String menteeId) {
    return menteeId == 'mentee-1'
        ? CurriculumSeedData.inProgressMentee
        : CurriculumSeedData.freshMentee;
  }

  @override
  Future<CurriculumProgress> getCurriculumProgress(String menteeId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _byMentee.putIfAbsent(menteeId, () => _seedFor(menteeId));
  }

  @override
  Future<void> updateLessonStatus({
    required String menteeId,
    required String lessonId,
    required LessonStatus status,
    double progressPercent = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final current = _byMentee.putIfAbsent(menteeId, () => _seedFor(menteeId));
    _byMentee[menteeId] = current.updatingLesson(
      lessonId,
      status: status,
      progressPercent: progressPercent,
    );
  }
}