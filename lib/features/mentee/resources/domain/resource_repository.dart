import 'learning_resource.dart';

abstract class ResourceRepository {
  /// Real version reads the resources endpoint once the backend has one.
  Future<List<LearningResource>> getResources();

  /// Real version writes to starred_resources.
  Future<void> setStarred(String resourceId, bool starred);
}