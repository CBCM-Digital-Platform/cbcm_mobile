import 'user.dart';

abstract class AuthRepository {
  /// Throws ApiException on invalid credentials or server error.
  Future<User> login({required String email, required String password});

  Future<void> logout();
}