import 'user.dart';

abstract class AuthRepository {
  /// Throws ApiException on invalid credentials or server error.
  Future<User> login({required String email, required String password});

  Future<void> logout();

  /// Changes the signed-in user's password and clears their
  /// "must change password" flag. Throws ApiException if the current
  /// password is wrong.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}