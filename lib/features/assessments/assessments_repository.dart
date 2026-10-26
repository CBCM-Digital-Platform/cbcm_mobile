import 'package:flutter_riverpod/flutter_riverpod.dart';

const kAssessmentAreas = [
  'Antenatal Care',
  'Intrapartum Care',
  'Postpartum Care',
  'Newborn Care',
];
const kAssessmentCriteria = [
  'Clinical knowledge',
  'Technical skill',
  'Communication',
  'Professionalism',
];
const kAssessmentChecklist = [
  'Hand hygiene performed',
  'Consent obtained',
  'Equipment prepared',
  'Documentation completed',
];

class Assessment {
  const Assessment({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    required this.mentorId,
    required this.area,
    required this.criteria,
    required this.checklist,
    required this.feedback,
    required this.score,
    required this.createdAt,
  });
  final int id;
  final int menteeId;
  final String menteeName;
  final int mentorId;
  final String area;
  final Map<String, int> criteria;
  final Map<String, bool> checklist;
  final String feedback;
  final double score;
  final DateTime createdAt;
}

abstract class AssessmentRepository {
  /// Real: GET /assessments?mentee_id=...
  Future<List<Assessment>> list({required int menteeId});

  /// Real: POST /assessments, POST .../criteria-scores,
  /// POST .../checklist-items, PATCH feedback, POST .../finalize.
  Future<Assessment> finalize({
    required int menteeId,
    required String menteeName,
    required int mentorId,
    required String area,
    required Map<String, int> criteria,
    required Map<String, bool> checklist,
    required String feedback,
  });
}

/// DEMO ONLY: kept in memory, lost on restart.
class MockAssessmentRepository implements AssessmentRepository {
  final List<Assessment> _all = [];

  @override
  Future<List<Assessment>> list({required int menteeId}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [for (final a in _all.reversed) if (a.menteeId == menteeId) a];
  }

  @override
  Future<Assessment> finalize({
    required int menteeId,
    required String menteeName,
    required int mentorId,
    required String area,
    required Map<String, int> criteria,
    required Map<String, bool> checklist,
    required String feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final score = criteria.isEmpty
        ? 0.0
        : criteria.values.fold<int>(0, (s, v) => s + v) / criteria.length;
    final a = Assessment(
      id: _all.length + 1,
      menteeId: menteeId,
      menteeName: menteeName,
      mentorId: mentorId,
      area: area,
      criteria: criteria,
      checklist: checklist,
      feedback: feedback,
      score: score,
      createdAt: DateTime.now(),
    );
    _all.add(a);
    return a;
  }
}

/// false = demo. true = real backend: write DioAssessmentRepository first.
const _useRealAssessments = false;

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  if (_useRealAssessments) {
    throw UnimplementedError('Write DioAssessmentRepository first.');
  }
  return _mock;
});
final _mock = MockAssessmentRepository();

final assessmentsProvider =
    FutureProvider.autoDispose.family<List<Assessment>, int>(
  (ref, menteeId) =>
      ref.watch(assessmentRepositoryProvider).list(menteeId: menteeId),
);
