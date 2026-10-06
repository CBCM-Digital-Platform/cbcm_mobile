
import 'learning_module.dart';

abstract class LearningRepository {
  /// Calls GET /learning-modules once wired to Dio.
  Future<List<LearningModule>> getModules();

  /// Current knowledge score only — trend view is deferred (per product decision).
  /// Calls GET /progress/knowledge-trend and reads the latest snapshot.
  Future<double> getCurrentKnowledgeScore();
}