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

  /// Requests a 6-digit OTP code sent to the given email for password reset.
  Future<void> requestPasswordResetOtp({required String email});

  /// Resets password using the 6-digit OTP received via email.
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });

  /// Requests a password reset link by email.
  Future<void> requestPasswordResetLink({required String email});
}