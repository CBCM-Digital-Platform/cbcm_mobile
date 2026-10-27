import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';

/// Resources given to each mentee, saved securely on this device and synced with backend.
const _key = 'resource_assignments';

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

  /// Returns the assigned IDs for a mentee.
  /// If null, all catalog resources granted by backend are accessible.
  Set<String>? idsFor(int? menteeId) => state.value?[menteeId];

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
