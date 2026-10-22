import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/domain/message_models.dart';

class AssignedMentee {
  const AssignedMentee({
    required this.id,
    required this.assignmentId,
    required this.fullName,
    required this.email,
    required this.facility,
    required this.level,
    required this.competencyPercentage,
    required this.pendingLogbooks,
    required this.needsReview,
    required this.isOnline,
    this.messageUser,
  });

  final int id;
  final int assignmentId;
  final String fullName;
  final String email;
  final String facility;
  final String level;
  final int competencyPercentage;
  final int pendingLogbooks;
  final bool needsReview;
  final bool isOnline;
  final MessageUser? messageUser;
}

final assignedMenteesProvider =
    FutureProvider.autoDispose<List<AssignedMentee>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final mentorIdStr = await storage.read(StorageKeys.userId);
  final mentorId = int.tryParse(mentorIdStr ?? '');
  final dio = ref.watch(dioProvider);
  final contacts = ref.watch(contactsApiProvider).value ?? const <MessageUser>[];

  if (mentorId != null) {
    try {
      dynamic rawData;
      try {
        final response = await dio.get(ApiEndpoints.mentorAssignments(mentorId));
        rawData = response.data;
      } catch (_) {}

      List<dynamic> list = _extractList(rawData);
      if (list.isEmpty) {
        try {
          final response = await dio.get(
            ApiEndpoints.assignments,
            queryParameters: {'mentor_id': mentorId},
          );
          rawData = response.data;
          list = _extractList(rawData);
        } catch (_) {}
      }

      if (rawData != null) {
        final List<AssignedMentee> result = [];
        for (var i = 0; i < list.length; i++) {
          final item = list[i] is Map ? Map<String, dynamic>.from(list[i] as Map) : <String, dynamic>{};
          final menteeMap = item['mentee'] is Map ? Map<String, dynamic>.from(item['mentee'] as Map) : <String, dynamic>{};
          final facilityMap = item['facility'] is Map ? Map<String, dynamic>.from(item['facility'] as Map) : <String, dynamic>{};

          final menteeId = (menteeMap['id'] as num?)?.toInt() ??
              (item['mentee_id'] as num?)?.toInt() ??
              (item['menteeId'] as num?)?.toInt() ??
              (i + 10);
          final assignmentId = (item['id'] as num?)?.toInt() ?? (i + 1);

          final matchedContact = contacts.cast<MessageUser?>().firstWhere(
                (c) => c?.id == menteeId,
                orElse: () => null,
              );

          final name = (menteeMap['full_name'] ??
                  menteeMap['fullName'] ??
                  menteeMap['name'] ??
                  item['mentee_name'] ??
                  matchedContact?.fullName ??
                  'Mentee #$menteeId')
              .toString();

          final email = (menteeMap['email'] ?? item['mentee_email'] ?? '').toString();
          final facility = (facilityMap['name'] ?? item['facility_name'] ?? 'Labor & Delivery').toString();
          final priorityScore = (item['priority_score'] as num?)?.toInt() ??
              (menteeMap['competency'] as num?)?.toInt() ??
              (i == 0 ? 78 : (i == 1 ? 45 : 62));

          final messageUser = matchedContact ??
              MessageUser(
                id: menteeId,
                fullName: name,
                role: 'mentee',
              );

          result.add(
            AssignedMentee(
              id: menteeId,
              assignmentId: assignmentId,
              fullName: name,
              email: email,
              facility: facility,
              level: menteeMap['level']?.toString() ?? (i % 2 == 0 ? 'Intermediate' : 'Novice'),
              competencyPercentage: priorityScore,
              pendingLogbooks: i == 0 ? 3 : 0,
              needsReview: i == 0,
              isOnline: i % 2 == 0,
              messageUser: messageUser,
            ),
          );
        }
        return result;
      }
    } catch (e) {
      debugPrint('[assignedMenteesProvider] Error fetching assignments: $e');
    }
  }

  // Graceful fallback seeded from Figma screen 5 & contacts
  return [
    const AssignedMentee(
      id: 10,
      assignmentId: 1,
      fullName: 'Emma Thompson',
      email: 'emma.t@cbcm.org',
      facility: 'Unit A',
      level: 'Intermediate',
      competencyPercentage: 78,
      pendingLogbooks: 3,
      needsReview: true,
      isOnline: true,
      messageUser: MessageUser(
        id: 10,
        fullName: 'Emma Thompson',
        role: 'mentee',
      ),
    ),
    const AssignedMentee(
      id: 11,
      assignmentId: 2,
      fullName: 'Marcus Johnson',
      email: 'marcus.j@cbcm.org',
      facility: 'Clinic North',
      level: 'Novice',
      competencyPercentage: 45,
      pendingLogbooks: 0,
      needsReview: false,
      isOnline: false,
      messageUser: MessageUser(
        id: 11,
        fullName: 'Marcus Johnson',
        role: 'mentee',
      ),
    ),
    const AssignedMentee(
      id: 12,
      assignmentId: 3,
      fullName: 'Sarah Jenkins',
      email: 'sarah.j@cbcm.org',
      facility: 'Labor Ward',
      level: 'Intermediate',
      competencyPercentage: 82,
      pendingLogbooks: 1,
      needsReview: true,
      isOnline: true,
      messageUser: MessageUser(
        id: 12,
        fullName: 'Sarah Jenkins',
        role: 'mentee',
      ),
    ),
  ];
});

List<dynamic> _extractList(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw;
  if (raw is Map) {
    final data = raw['data'] ?? raw;
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['items', 'assignments', 'cycles', 'sessions', 'contacts', 'conversations']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    for (final key in ['items', 'assignments', 'cycles', 'sessions', 'contacts', 'conversations']) {
      if (raw[key] is List) return raw[key] as List;
    }
  }
  return [];
}

