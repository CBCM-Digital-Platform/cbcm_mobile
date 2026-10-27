import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../messaging/data/messaging_providers.dart';
import '../domain/learning_resource.dart';
import '../domain/resource_repository.dart';
import 'mock_resource_repository.dart';
import 'resource_assignments.dart';

final resourceRepositoryProvider =
    Provider<ResourceRepository>((ref) => MockResourceRepository());

class ResourcesController extends AsyncNotifier<List<LearningResource>> {
  String _key(int? id) => 'starred:$id';

  @override
  Future<List<LearningResource>> build() async {
    final myId = await ref.watch(currentUserIdProvider.future);
    await ref.watch(resourceAssignmentsProvider.future);
    final assigned = ref.read(resourceAssignmentsProvider.notifier).idsFor(myId);
    final raw = await ref.read(secureStorageProvider).read(_key(myId));
    final stars = (raw ?? '').split(',').where((s) => s.isNotEmpty).toSet();
    final all = await ref.watch(resourceRepositoryProvider).getResources();
    return [
      for (final r in all)
        if (assigned.contains(r.id)) r.copyWith(isStarred: stars.contains(r.id)),
    ];
  }

  Future<void> toggleStar(String id) async {
    final current = state.value;
    if (current == null) return;
    final starred = !current.firstWhere((r) => r.id == id).isStarred;
    final next = [
      for (final r in current) r.id == id ? r.copyWith(isStarred: starred) : r
    ];
    state = AsyncData(next);
    final myId = await ref.read(currentUserIdProvider.future);
    await ref.read(secureStorageProvider).write(
          _key(myId),
          next.where((r) => r.isStarred).map((r) => r.id).join(','),
        );
  }
}

final resourcesControllerProvider =
    AsyncNotifierProvider<ResourcesController, List<LearningResource>>(
  ResourcesController.new,
);
