import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../messaging/data/messaging_providers.dart';
import '../domain/logbook_entry.dart';
import 'logbook_repository.dart';

final logbookRepositoryProvider = Provider<LogbookRepository>((ref) {
  return LogbookRepository(ref.watch(dioProvider));
});

/// Logbook entries for the currently signed-in mentee.
final menteeLogbookEntriesProvider =
    FutureProvider.autoDispose<List<LogbookEntry>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider).value;
  if (currentUserId == null) return [];
  final repo = ref.watch(logbookRepositoryProvider);
  return repo.getEntries(menteeId: currentUserId);
});

/// Logbook entries for a specific mentee (used by mentors).
final mentorMenteeLogbookEntriesProvider =
    FutureProvider.autoDispose.family<List<LogbookEntry>, int>((ref, menteeId) async {
  final repo = ref.watch(logbookRepositoryProvider);
  return repo.getEntries(menteeId: menteeId);
});
