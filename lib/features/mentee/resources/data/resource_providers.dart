import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/learning_resource.dart';
import '../domain/resource_repository.dart';
import 'mock_resource_repository.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return MockResourceRepository();
});

class ResourcesController extends AsyncNotifier<List<LearningResource>> {
  @override
  Future<List<LearningResource>> build() =>
      ref.watch(resourceRepositoryProvider).getResources();

  /// Updates the screen immediately, then saves. Undoes it if saving fails.
  Future<void> toggleStar(String id) async {
    final current = state.value;
    if (current == null) return;

    final target = current.firstWhere((r) => r.id == id);
    final starred = !target.isStarred;

    state = AsyncData([
      for (final r in current) r.id == id ? r.copyWith(isStarred: starred) : r
    ]);

    try {
      await ref.read(resourceRepositoryProvider).setStarred(id, starred);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final resourcesControllerProvider =
    AsyncNotifierProvider<ResourcesController, List<LearningResource>>(
  ResourcesController.new,
);