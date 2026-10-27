import 'learning_resource.dart';

abstract class ResourceRepository {
  /// Reads resources from the backend (or mock fallback).
  Future<List<LearningResource>> getResources();

  /// Reads a single resource detail by ID.
  Future<LearningResource?> getResource(String id);

  /// Mentors assign resources to a mentee.
  Future<void> assignToMentee(int menteeId, Set<String> resourceIds);

  /// Real version writes to starred_resources.
  Future<void> setStarred(String resourceId, bool starred);
}
