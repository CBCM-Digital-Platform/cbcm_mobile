import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../messaging/data/messaging_providers.dart';
import '../domain/learning_resource.dart';
import '../domain/resource_repository.dart';
import 'mock_resource_repository.dart';
import 'resource_assignments.dart';

final resourceRepositoryProvider =
    Provider<ResourceRepository>((ref) => MockResourceRepository());

/// The signed-in mentee's library: only what her mentor assigned.
class ResourcesController extends AsyncNotifier<List<LearningResource>> {
  @override
  Future<List<LearningResource>> build() async {
    final myId = await ref.watch(currentUserIdProvider.future);
    final assigned =
        ref.watch(resourceAssignmentsProvider)[myId] ?? const <String>{};
    final all = await ref.watch(resourceRepositoryProvider).getResources();
    return [for (final r in all) if (assigned.contains(r.id)) r];
  }

  Future<void> toggleStar(String id) async {
    final current = state.value;
    if (current == null) return;
    final starred = !current.firstWhere((r) => r.id == id).isStarred;

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