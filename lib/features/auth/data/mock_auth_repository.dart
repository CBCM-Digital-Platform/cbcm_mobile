import '../../../core/network/api_response.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../domain/user_role.dart';

class _MockAccount {
  const _MockAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.mustChangeByDefault,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool mustChangeByDefault;
}

/// MOCKED. Used while _useRealBackend is false. Remembers password
/// changes in secure storage, like the real backend would.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._storage);

  final SecureStorage _storage;

  static const _defaultPassword = 'password';

  static const _accounts = [
    _MockAccount(
      id: 'mentee-1',
      name: 'Amara Bekele',
      email: 'mentee@example.com',
      role: UserRole.mentee,
      mustChangeByDefault: true, // simulates an admin-issued password
    ),
    _MockAccount(
      id: 'mentor-1',
      name: 'Dr. Selam Tesfaye',
      email: 'mentor@example.com',
      role: UserRole.mentor,
      mustChangeByDefault: false,
    ),
  ];

  _MockAccount? _byEmail(String email) {
    for (final a in _accounts) {
      if (a.email == email) return a;
    }
    return null;
  }

  _MockAccount? _byId(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<String> _passwordFor(_MockAccount a) async =>
      (await _storage.read('mock_password:${a.id}')) ?? _defaultPassword;

  Future<bool> _mustChangeFor(_MockAccount a) async {
    final saved = await _storage.read('mock_must_change:${a.id}');
    return saved == null ? a.mustChangeByDefault : saved == 'true';
  }

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // fake latency

    final account = _byEmail(email);
    if (account == null || password != await _passwordFor(account)) {
      throw ApiException(
        const ApiError(
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password',
        ),
      );
    }

    return User(
      id: account.id,
      name: account.name,
      email: account.email,
      role: account.role,
      mustChangePassword: await _mustChangeFor(account),
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final id = await _storage.read(StorageKeys.userId);
    final account = id == null ? null : _byId(id);
    if (account == null) {
      throw ApiException(
        const ApiError(code: 'UNAUTHORIZED', message: 'Please sign in again.'),
      );
    }

    if (currentPassword != await _passwordFor(account)) {
      throw ApiException(
        const ApiError(
          code: 'INVALID_CURRENT_PASSWORD',
          message: 'Your current password is incorrect.',
        ),
      );
    }

    await _storage.write('mock_password:${account.id}', newPassword);
    await _storage.write('mock_must_change:${account.id}', 'false');
  }

  @override
  Future<void> requestPasswordResetOtp({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> requestPasswordResetLink({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}