import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DEMO ONLY: which resources each mentee has been given (mentee id to
/// resource ids). Lost on restart. Replaced by the backend assignment API.
class ResourceAssignments extends Notifier<Map<int, Set<String>>> {
  @override
  Map<int, Set<String>> build() => const {};

  void setFor(int menteeId, Set<String> ids) =>
      state = {...state, menteeId: Set.of(ids)};
}

final resourceAssignmentsProvider =
    NotifierProvider<ResourceAssignments, Map<int, Set<String>>>(
  ResourceAssignments.new,
);
