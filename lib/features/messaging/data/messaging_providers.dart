import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../auth/presentation/current_role_provider.dart';
import '../domain/message_models.dart';
import 'messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioProvider));
});

/// All of the signed-in user's conversations (no messages inside).
final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final role = ref.watch(currentRoleProvider);
  if (role == null) return const <Conversation>[];
  return ref.watch(messagingRepositoryProvider).listConversations();
});

/// One conversation with all its messages.
final conversationProvider =
    FutureProvider.autoDispose.family<Conversation, int>((ref, id) {
  return ref.watch(messagingRepositoryProvider).getConversation(id);
});

/// The signed-in user's id, from the value saved at login. Watching the role
/// makes it re-read whenever someone signs in or out, so a different user on
/// the same phone never inherits the previous user's id.
final currentUserIdProvider = FutureProvider.autoDispose<int?>((ref) async {
  ref.watch(currentRoleProvider);
  final saved = await ref.read(secureStorageProvider).read(StorageKeys.userId);
  return saved == null ? null : int.tryParse(saved);
});