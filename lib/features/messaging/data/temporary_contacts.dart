import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message_models.dart';
import 'messaging_providers.dart';

/// Text shown when the user has nobody to message yet.
String noContactsMessage() =>
    'No contacts yet. Your mentor or mentees appear here once assigned.';

/// The backend's list of people the signed-in user may message.
final contactsApiProvider =
    FutureProvider.autoDispose<List<MessageUser>>((ref) async {
  final contacts = await ref.watch(messagingRepositoryProvider).listContacts();
  debugPrint('[CONTACTS] ${contacts.length} from the server');
  return contacts;
});

/// Everyone the user may message: the server's contacts, plus anyone they
/// already chat with (so nobody disappears if the endpoint is unavailable).
final contactsProvider = Provider<List<MessageUser>>((ref) {
  final myId = ref.watch(currentUserIdProvider).value;
  final fromApi = ref.watch(contactsApiProvider).value ?? const <MessageUser>[];
  final conversations = ref.watch(conversationsProvider).value ?? const [];

  final byId = <int, MessageUser>{};
  for (final p in fromApi) {
    if (p.id > 0 && p.id != myId) byId[p.id] = p;
  }
  for (final c in conversations) {
    if (c.type != 'direct') continue;
    for (final p in c.participants) {
      if (p.id <= 0 || p.id == myId) continue;
      byId.putIfAbsent(p.id, () => p);
    }
  }
  return byId.values.toList();
});

/// A mentor's mentees.
final menteeContactsProvider = Provider<List<MessageUser>>((ref) {
  return ref
      .watch(contactsProvider)
      .where((u) => u.role.toLowerCase().contains('mentee'))
      .toList();
});

/// A mentee's mentor(s).
final mentorContactsProvider = Provider<List<MessageUser>>((ref) {
  return ref
      .watch(contactsProvider)
      .where((u) => u.role.toLowerCase().contains('mentor'))
      .toList();
});