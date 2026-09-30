import 'user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

abstract class AuthRepository {
  /// Throws AuthException on invalid credentials.
  Future<User> login({required String email, required String password});

  Future<void> logout();
}