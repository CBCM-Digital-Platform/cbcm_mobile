import '../domain/learning_resource.dart';
import '../domain/resource_repository.dart';

/// MOCKED until or when offline without backend connection.
class MockResourceRepository implements ResourceRepository {
  final Map<String, bool> _starred = {};

  // Public sample PDF, used only to test downloading.
  static const _samplePdf =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  static const all = [
    LearningResource(
      id: 'r1',
      title: 'Fundal Palpation Clinical Handbook',
      type: ResourceType.pdf,
      category: 'Antenatal Care',
      sizeBytes: 4800000,
      description: 'ACOG and WHO standards, v4.2.',
      downloadUrl: _samplePdf,
    ),
    LearningResource(
      id: 'r2',
      title: 'Active Management of the Third Stage',
      type: ResourceType.video,
      category: 'Postpartum Care',
      sizeBytes: 58000000,
      description: 'Step-by-step demonstration.',
    ),
    LearningResource(
      id: 'r3',
      title: 'CTG Interpretation Quick Guide',
      type: ResourceType.pdf,
      category: 'Intrapartum Care',
      sizeBytes: 1200000,
      downloadUrl: _samplePdf,
    ),
    LearningResource(
      id: 'r4',
      title: 'Neonatal Resuscitation Walkthrough',
      type: ResourceType.video,
      category: 'Newborn Care',
      sizeBytes: 72000000,
    ),
    LearningResource(
      id: 'r5',
      title: 'Danger Signs in Pregnancy (Audio)',
      type: ResourceType.audio,
      category: 'Antenatal Care',
      sizeBytes: 9000000,
    ),
    LearningResource(
      id: 'r6',
      title: 'Sample text document (read-aloud test)',
      type: ResourceType.pdf,
      category: 'Testing',
      sizeBytes: 1000000,
      downloadUrl:
          'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
    ),
  ];

  @override
  Future<List<LearningResource>> getResources() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [for (final r in all) r.copyWith(isStarred: _starred[r.id] ?? false)];
  }

  @override
  Future<LearningResource?> getResource(String id) async {
    final list = await getResources();
    for (final r in list) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> assignToMentee(int menteeId, Set<String> resourceIds) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> setStarred(String resourceId, bool starred) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _starred[resourceId] = starred;
  }
}
