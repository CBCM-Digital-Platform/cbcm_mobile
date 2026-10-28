
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../domain/user_role.dart';

/// Talks to the real backend. Response field names are read in the
/// helpers at the bottom of this file, so if the backend names differ
/// from what is assumed here, only those helpers need to change.
class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final body = response.data;

      if (body is! Map ||
          body['success'] != true ||
          body['data'] is! Map) {
        throw _unexpected('Unexpected login response');
      }

      final data = Map<String, dynamic>.from(
        body['data'] as Map,
      );

      // Debug only: shows the real field names in the console so they
      // can be checked against what this file assumes.
      debugPrint(
        'Login response data keys: ${data.keys.toList()}',
      );

      final accessToken = _pick(
        data,
        ['accessToken', 'access_token', 'token'],
      );

      final refreshToken = _pick(
        data,
        ['refreshToken', 'refresh_token'],
      );

      if (accessToken == null) {
        throw _unexpected(
          'Login response has no access token',
        );
      }

      final userJson = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;

      final user = _userFromJson(userJson);

      await _storage.write(
        StorageKeys.accessToken,
        accessToken.toString(),
      );

      if (refreshToken != null) {
        await _storage.write(
          StorageKeys.refreshToken,
          refreshToken.toString(),
        );
      }

      // Kept so the app can sign in again after a password change.
      await _storage.write(StorageKeys.userEmail, email);

      return user;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.read(
      StorageKeys.refreshToken,
    );

    try {
      await _dio.post(
        ApiEndpoints.logout,
        data: refreshToken == null
            ? null
            : {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      // The caller should still clear the local session even if this
      // request fails, for example when offline or when a token expires.
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }

    // The backend invalidates every existing token after a password
    // change, so clear the old ones and sign in again with the new
    // password to get fresh ones.
    final email = await _storage.read(StorageKeys.userEmail);

    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.refreshToken);

    if (email == null) {
      throw _reauthRequired();
    }

    try {
      await login(
        email: email,
        password: newPassword,
      );
    } on ApiException {
      throw _reauthRequired();
    }
  }

  @override
  Future<void> requestPasswordResetOtp({required String email}) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotOtp,
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.resetOtp,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  @override
  Future<void> requestPasswordResetLink({required String email}) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  // --- Response reading helpers --------------------------------------

  dynamic _pick(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final k in keys) {
      if (map[k] != null) return map[k];
    }

    return null;
  }

  User _userFromJson(Map<String, dynamic> j) {
    final roleText = (_pick(j, ['role']) ?? '')
        .toString()
        .toUpperCase()
        .trim();

    final UserRole role;

    if (roleText == 'MENTEE') {
      role = UserRole.mentee;
    } else if (roleText == 'MENTOR') {
      role = UserRole.mentor;
    } else {
      // e.g. FACILITY_ADMIN: not supported in the mobile app.
      throw ApiException(
        const ApiError(
          code: 'ROLE_NOT_SUPPORTED',
          message: 'This app is for mentors and mentees only.',
        ),
      );
    }

    return User(
      id: (_pick(j, ['id', 'userId', 'user_id']) ?? '')
          .toString(),
      name: (_pick(j, ['fullName', 'full_name', 'name']) ?? '')
          .toString(),
      email: (_pick(j, ['email']) ?? '').toString(),
      role: role,
      mustChangePassword:
          _pick(j, ['mustChangePassword', 'must_change_password']) ==
              true,
    );
  }

  ApiException _unexpected(String message) {
    return ApiException(
      ApiError(
        code: 'UNEXPECTED_RESPONSE',
        message: message,
      ),
    );
  }

  ApiException _reauthRequired() {
    return ApiException(
      const ApiError(
        code: 'REAUTH_REQUIRED',
        message: 'Password updated. Please sign in again.',
      ),
    );
  }
}
