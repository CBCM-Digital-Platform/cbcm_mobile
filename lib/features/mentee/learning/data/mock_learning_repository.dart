
import '../domain/learning_module.dart';
import '../domain/learning_repository.dart';

/// MOCKED. Replace with a real Dio-backed repository once the backend
/// confirms the learning-modules and knowledge-trend endpoints.
class MockLearningRepository implements LearningRepository {
  static const _modules = [
    LearningModule(
      id: 'module-1',
      title: 'Active Management of the Third Stage of Labour',
      thematicArea: 'Postpartum Care',
      protocolSummary:
          'Covers the three components of active management: uterotonic '
          'administration, controlled cord traction, and uterine massage.',
      status: ModuleStatus.completed,
    ),
    LearningModule(
      id: 'module-2',
      title: 'Neonatal Resuscitation Basics',
      thematicArea: 'Newborn Care',
      protocolSummary:
          'Step-by-step approach to assessing and resuscitating a newborn '
          'in the first minute of life.',
      status: ModuleStatus.inProgress,
    ),
    LearningModule(
      id: 'module-3',
      title: 'Recognizing Pre-eclampsia',
      thematicArea: 'Antenatal Care',
      protocolSummary:
          'Signs, symptoms, and immediate response steps for suspected '
          'pre-eclampsia during antenatal visits.',
      status: ModuleStatus.notStarted,
    ),
  ];

  @override
  Future<List<LearningModule>> getModules() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _modules;
  }

  @override
  Future<double> getCurrentKnowledgeScore() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 72.5; // fake current score, shown inline per the deferred-trend decision
  }
}