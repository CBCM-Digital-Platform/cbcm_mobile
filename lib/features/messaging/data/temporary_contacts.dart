import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../mentor/mentees/data/assigned_mentees_provider.dart';
import '../domain/message_models.dart';
import 'messaging_providers.dart';

/// Text shown when the user has nobody to message yet.
String noContactsMessage() =>
    'No contacts yet. Your mentor or mentees appear here once assigned.';

/// The backend's list of people the signed-in user may message.
final contactsApiProvider =
    FutureProvider.autoDispose<List<MessageUser>>((ref) async {
  try {
    final contacts = await ref.watch(messagingRepositoryProvider).listContacts();
    debugPrint('[CONTACTS] ${contacts.length} from the server');
    return contacts;
  } catch (e) {
    debugPrint('[CONTACTS] Error fetching contacts: $e');
    return const <MessageUser>[];
  }
});

/// Fetches the signed-in mentee's assigned mentor directly from assignments API.
final assignedMentorProvider =
    FutureProvider.autoDispose<MessageUser?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final menteeIdStr = await storage.read(StorageKeys.userId);
  final menteeId = int.tryParse(menteeIdStr ?? '');
  if (menteeId == null) return null;

  final dio = ref.watch(dioProvider);
  try {
    Response<dynamic>? res;
    try {
      res = await dio.get(ApiEndpoints.menteeAssignments(menteeId));
    } catch (_) {}

    dynamic rawData = res?.data;
    List<dynamic> items = _extractAssignmentItems(rawData);
    if (items.isEmpty) {
      try {
        final r = await dio.get(
          ApiEndpoints.assignments,
          queryParameters: {'mentee_id': menteeId},
        );
        rawData = r.data;
        items = _extractAssignmentItems(rawData);
      } catch (_) {}
    }

    if (items.isNotEmpty) {
      final active = items.firstWhere(
        (a) => a is Map && (a['status'] == 'assigned' || a['status'] == null),
        orElse: () => items.first,
      );
      if (active is Map) {
        final mentorMap = active['mentor'] is Map ? active['mentor'] as Map : null;
        final mentorId = (mentorMap?['id'] as num?)?.toInt() ??
            (active['mentor_id'] as num?)?.toInt() ??
            (active['mentorId'] as num?)?.toInt();
        final name = (mentorMap?['full_name'] ??
                mentorMap?['fullName'] ??
                mentorMap?['name'] ??
                active['mentor_name'] ??
                'Assigned Mentor')
            .toString();

        if (mentorId != null && mentorId > 0) {
          return MessageUser(
            id: mentorId,
            fullName: name,
            role: 'mentor',
          );
        }
      }
    }
  } catch (e) {
    debugPrint('[assignedMentorProvider] Error fetching mentor: $e');
  }
  return null;
});

List<dynamic> _extractAssignmentItems(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw;
  if (raw is Map) {
    final data = raw['data'] ?? raw;
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['items', 'assignments']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    for (final key in ['items', 'assignments']) {
      if (raw[key] is List) return raw[key] as List;
    }
  }
  return [];
}

/// Everyone the user may message: server contacts, assigned mentor/mentees,
/// and existing direct conversations.
final contactsProvider = Provider<List<MessageUser>>((ref) {
  final myId = ref.watch(currentUserIdProvider).value;
  final fromApi = ref.watch(contactsApiProvider).value ?? const <MessageUser>[];
  final conversations = ref.watch(conversationsProvider).value ?? const [];
  final assignedMentees = ref.watch(assignedMenteesProvider).value ?? const [];
  final assignedMentor = ref.watch(assignedMentorProvider).value;

  final byId = <int, MessageUser>{};

  // 1. From /messages/contacts endpoint
  for (final p in fromApi) {
    if (p.id > 0 && p.id != myId) byId[p.id] = p;
  }

  // 2. From assigned mentees (for Mentor Ke)
  for (final m in assignedMentees) {
    if (m.messageUser != null && m.id > 0 && m.id != myId) {
      byId[m.id] = m.messageUser!;
    }
  }

  // 3. From assigned mentor (for Mentee Le)
  if (assignedMentor != null && assignedMentor.id > 0 && assignedMentor.id != myId) {
    byId[assignedMentor.id] = assignedMentor;
  }

  // 4. From existing conversations
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
  final contacts = ref.watch(contactsProvider);
  final mentees = contacts
      .where((u) => u.role.toLowerCase().contains('mentee'))
      .toList();
  if (mentees.isNotEmpty) return mentees;

  // Fallback to assignedMenteesProvider directly if contacts hasn't resolved
  final assigned = ref.watch(assignedMenteesProvider).value ?? const [];
  return assigned
      .where((m) => m.messageUser != null)
      .map((m) => m.messageUser!)
      .toList();
});

/// A mentee's mentor(s).
final mentorContactsProvider = Provider<List<MessageUser>>((ref) {
  final contacts = ref.watch(contactsProvider);
  final mentors = contacts
      .where((u) => u.role.toLowerCase().contains('mentor'))
      .toList();
  if (mentors.isNotEmpty) return mentors;

  // Fallback to assignedMentorProvider directly
  final mentor = ref.watch(assignedMentorProvider).value;
  if (mentor != null) return [mentor];

  return const [];
});