import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/presentation/current_role_provider.dart';

class UserProfileData {
  const UserProfileData({
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.phone = '',
    this.qualification = '',
    this.trainingStatus = '',
    this.notificationsEnabled = true,
    this.language = 'en',
    this.theme = 'system',
  });
  final String fullName, email, role, status;
  final String phone, qualification, trainingStatus;
  final bool notificationsEnabled;
  final String language, theme;
}

class UserProfileRepository {
  UserProfileRepository(this._dio);
  final Dio _dio;

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map) {
      final d = raw['data'];
      return Map<String, dynamic>.from(d is Map ? d : raw);
    }
    return <String, dynamic>{};
  }

  String _s(Object? v) => v?.toString() ?? '';

  Future<UserProfileData> load() async {
    try {
      final meFuture = _dio.get('/users/me');
      final prefsFuture = _dio
          .get('/users/me/preferences')
          .then<Map<String, dynamic>>((r) => _data(r.data))
          .catchError((_) => <String, dynamic>{});

      final u = _data((await meFuture).data);
      final p = await prefsFuture;

      return UserProfileData(
        fullName: _s(u['full_name']),
        email: _s(u['email']),
        role: _s(u['role']),
        status: _s(u['status']),
        phone: _s(u['phone']),
        qualification: _s(u['highest_qualification']),
        trainingStatus: _s(u['training_status']),
        notificationsEnabled: p['notifications_enabled'] != false,
        language: p['language'] is String ? p['language'] as String : 'en',
        theme: p['theme'] is String ? p['theme'] as String : 'system',
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Empty fields are not sent, so a field cannot be cleared until the
  /// backend accepts null.
  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String qualification,
  }) async {
    try {
      await _dio.patch('/users/me', data: {
        'full_name': fullName,
        if (phone.isNotEmpty) 'phone': phone,
        if (qualification.isNotEmpty) 'highest_qualification': qualification,
      });
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> setNotifications(
    bool enabled, {
    required String language,
    required String theme,
  }) async {
    try {
      await _dio.patch('/users/me/preferences', data: {
        'language': language,
        'theme': theme,
        'notifications_enabled': enabled,
      });
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(ref.watch(dioProvider)),
);

final userProfileProvider = FutureProvider.autoDispose<UserProfileData>((ref) {
  ref.watch(currentRoleProvider); // reload when a different user signs in
  return ref.watch(userProfileRepositoryProvider).load();
});