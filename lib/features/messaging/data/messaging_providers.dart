import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/message_models.dart';
import 'messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioProvider));
});

/// All of the signed-in user's conversations (no messages inside).
final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(messagingRepositoryProvider).listConversations();
});

/// One conversation with all its messages.
final conversationProvider =
    FutureProvider.autoDispose.family<Conversation, int>((ref, id) {
  return ref.watch(messagingRepositoryProvider).getConversation(id);
});

/// The signed-in user's id, saved at login. autoDispose so a different
/// user signing in on the same phone never sees the previous user's id.
final currentUserIdProvider = FutureProvider.autoDispose<int?>((ref) async {
  final saved = await ref.read(secureStorageProvider).read(StorageKeys.userId);
  return saved == null ? null : int.tryParse(saved);
});