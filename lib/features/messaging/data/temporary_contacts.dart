import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/current_role_provider.dart';
import '../../mentor/mentees/data/assigned_mentees_provider.dart';
import '../domain/message_models.dart';
import 'messaging_providers.dart';
import '../../auth/domain/user_role.dart';

/// Text shown when the user has nobody to message yet.
String noContactsMessage() =>
    'No contacts yet. Your mentor or mentees appear here once assigned.';

/// The backend's list of people the signed-in user may message. Watching the
/// role resets it whenever someone signs in or out.
final contactsApiProvider = FutureProvider<List<MessageUser>>((ref) async {
  final role = ref.watch(currentRoleProvider);
  if (role == null) return const <MessageUser>[];
  try {
    final contacts = await ref.watch(messagingRepositoryProvider).listContacts();
    debugPrint('[CONTACTS] ${contacts.length} from the server');
    return contacts;
  } catch (e) {
    debugPrint('[CONTACTS] Error fetching contacts: $e');
    return const <MessageUser>[];
  }
});

/// A mentee's assigned mentor, taken from the contacts list. Null if none.
final assignedMentorProvider = FutureProvider<MessageUser?>((ref) async {
  final contacts = await ref.watch(contactsApiProvider.future);
  for (final c in contacts) {
    if (c.role.toLowerCase().contains('mentor')) return c;
  }
  return null;
});

/// Everyone the user may message: server contacts, assigned mentees, and
/// anyone they already chat with.
final contactsProvider = Provider<List<MessageUser>>((ref) {
  final myId = ref.watch(currentUserIdProvider).value;
  final fromApi = ref.watch(contactsApiProvider).value ?? const <MessageUser>[];
  final conversations = ref.watch(conversationsProvider).value ?? const [];
  final isMentor = ref.watch(currentRoleProvider) == UserRole.mentor;
  final assignedMentees = isMentor
      ? (ref.watch(assignedMenteesProvider).value ?? const <AssignedMentee>[])
      : const <AssignedMentee>[];

  final byId = <int, MessageUser>{};

  for (final p in fromApi) {
    if (p.id > 0 && p.id != myId) byId[p.id] = p;
  }

  for (final m in assignedMentees) {
    if (m.messageUser != null && m.id > 0 && m.id != myId) {
      byId[m.id] = m.messageUser!;
    }
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