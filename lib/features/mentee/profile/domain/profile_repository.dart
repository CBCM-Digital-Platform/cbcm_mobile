import '../../auth/domain/user.dart';

abstract class ProfileRepository {
  /// Calls GET /users/me once wired to Dio. Throws ApiException on failure.
  Future<User> getCurrentUser();
}