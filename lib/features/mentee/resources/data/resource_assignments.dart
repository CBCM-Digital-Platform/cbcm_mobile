import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';

/// DEMO ONLY: resources given to each mentee, saved on THIS phone only.
/// Replaced by the backend assignment API.
const _key = 'demo_resource_assignments';

/// Shown to a mentee until her mentor changes the list (the test files).
const demoDefaultResourceIds = {'r1', 'r6', 'r7'};

class ResourceAssignments extends AsyncNotifier<Map<int, Set<String>>> {
  @override
  Future<Map<int, Set<String>>> build() async {
    final raw = await ref.read(secureStorageProvider).read(_key);
    if (raw == null) return const {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          int.parse(e.key): {...(e.value as List).map((x) => '$x')},
      };
    } catch (_) {
      return const {};
    }
  }

  Set<String> idsFor(int? menteeId) =>
      state.value?[menteeId] ?? demoDefaultResourceIds;

  Future<void> setFor(int menteeId, Set<String> ids) async {
    final next = {...?state.value, menteeId: Set.of(ids)};
    state = AsyncData(next);
    await ref.read(secureStorageProvider).write(
          _key,
          jsonEncode({for (final e in next.entries) '${e.key}': e.value.toList()}),
        );
  }
}

final resourceAssignmentsProvider =
    AsyncNotifierProvider<ResourceAssignments, Map<int, Set<String>>>(
  ResourceAssignments.new,
);
