import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/current_role_provider.dart';
import 'dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient(
    // Clears the stored session and the role; the router then sends the
    // user to the login screen.
    onSessionExpired: () => ref.read(currentRoleProvider.notifier).logout(),
  ).dio;
});