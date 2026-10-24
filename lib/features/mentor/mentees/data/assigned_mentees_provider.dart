import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../messaging/data/messaging_providers.dart';
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

/// The signed-in mentor's active mentees, from
/// GET /assignments/mentors/{id}/assignments. Names come from the contacts
/// list, because an assignment only carries ids. Nothing is invented: a
/// missing value stays empty or zero.
final assignedMenteesProvider =
    FutureProvider.autoDispose<List<AssignedMentee>>((ref) async {
  final mentorId = await ref.watch(currentUserIdProvider.future);
  if (mentorId == null) return const [];

  final dio = ref.watch(dioProvider);

  // Start loading names while the assignments request is in flight.
  final contactsFuture = ref
      .watch(contactsApiProvider.future)
      .catchError((_) => <MessageUser>[]);

  dynamic raw;
  try {
    raw = (await dio.get(ApiEndpoints.mentorAssignments(mentorId))).data;
  } on DioException catch (e) {
    throw apiExceptionFromDio(e);
  }

  final contacts = await contactsFuture;
  final result = <AssignedMentee>[];

  for (final item in _extractList(raw)) {
    if (item is! Map) continue;
    final a = Map<String, dynamic>.from(item);

    // Only active assignments.
    final status = a['status']?.toString();
    if (status != null && status != 'assigned') continue;

    final menteeMap = a['mentee'] is Map
        ? Map<String, dynamic>.from(a['mentee'] as Map)
        : const <String, dynamic>{};

    final menteeId = (menteeMap['id'] as num?)?.toInt() ??
        (a['mentee_id'] as num?)?.toInt() ??
        (a['menteeId'] as num?)?.toInt();
    if (menteeId == null) continue;

    MessageUser? contact;
    for (final c in contacts) {
      if (c.id == menteeId) {
        contact = c;
        break;
      }
    }

    var name = (menteeMap['full_name'] ??
            menteeMap['fullName'] ??
            menteeMap['name'] ??
            a['mentee_name'] ??
            contact?.fullName ??
            '')
        .toString()
        .trim();
    if (name.isEmpty || name == 'Unknown') name = 'Mentee #$menteeId';

    final facilityMap = a['facility'] is Map ? a['facility'] as Map : null;
    final facility =
        (facilityMap?['name'] ?? a['facility_name'] ?? '').toString();

    result.add(
      AssignedMentee(
        id: menteeId,
        assignmentId: (a['id'] as num?)?.toInt() ?? 0,
        fullName: name,
        email: (contact?.email ?? menteeMap['email'] ?? '').toString(),
        facility: facility,
        level: '',
        competencyPercentage: 0, // no data yet: comes from the progress API
        pendingLogbooks: 0,
        needsReview: false,
        isOnline: false, // the server does not report presence
        messageUser: contact ??
            MessageUser(id: menteeId, fullName: name, role: 'mentee'),
      ),
    );
  }

  debugPrint('[MENTEES] ${result.length} active assignment(s)');
  return result;
});

List<dynamic> _extractList(dynamic raw) {
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