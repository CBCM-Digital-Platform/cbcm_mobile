import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/current_role_provider.dart';
import '../../../messaging/data/messaging_providers.dart';

/// The user's active assignments, fetched once per sign-in and shared by the
/// dashboard, the mentees list and the schedule sheet.
final mentorAssignmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final role = ref.watch(currentRoleProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  if (role == null || userId == null) return const [];

  final path = role == UserRole.mentor
      ? ApiEndpoints.mentorAssignments(userId)
      : ApiEndpoints.menteeAssignments(userId);
  try {
    final r = await ref.watch(dioProvider).get(path);
    final raw = r.data;
    final d = raw is Map ? (raw['data'] ?? raw) : raw;
    final list = d is List
        ? d
        : (d is Map ? (d['items'] ?? d['assignments']) : null);
    return [
      for (final e in (list is List ? list : const []))
        if (e is Map &&
            (e['status'] == null || e['status'].toString() == 'assigned'))
          Map<String, dynamic>.from(e),
    ];
  } on DioException catch (e) {
    throw apiExceptionFromDio(e);
  }
});
