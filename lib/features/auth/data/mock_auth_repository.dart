import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../domain/user_role.dart';

/// MOCKED. Replace with a real Dio-backed repository once the backend
/// and OpenAPI spec are available. Keep this file until then.
class MockAuthRepository implements AuthRepository {
  static const _menteeUser = User(
    id: 'mentee-1',
    name: 'Amara Bekele',
    email: 'mentee@example.com',
    role: UserRole.mentee,
  );

  static const _mentorUser = User(
    id: 'mentor-1',
    name: 'Dr. Selam Tesfaye',
    email: 'mentor@example.com',
    role: UserRole.mentor,
  );

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // fake latency

    if (email == _menteeUser.email && password == 'password') {
      return _menteeUser;
    }
    if (email == _mentorUser.email && password == 'password') {
      return _mentorUser;
    }
    throw AuthException('Invalid email or password');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}