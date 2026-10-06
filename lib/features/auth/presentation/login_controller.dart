import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../data/auth_repository_provider.dart';
import '../domain/user.dart';
import 'current_role_provider.dart';

sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);
  final User user;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginIdle();

  Future<void> submit({required String email, required String password}) async {
    state = const LoginLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email: email, password: password);

      // MOCKED tokens: the mock repository doesn't return real ones yet.
      final storage = ref.read(secureStorageProvider);
      await storage.write(StorageKeys.accessToken, 'mock-access-token');
      await storage.write(StorageKeys.refreshToken, 'mock-refresh-token');
      await storage.write(StorageKeys.userRole, user.role.name);
      await storage.write(StorageKeys.userId, user.id);
      await storage.write(StorageKeys.userName, user.name);

      ref.read(currentRoleProvider.notifier).setRole(user.role);

      state = LoginSuccess(user);
    } on ApiException catch (e) {
      state = LoginError(e.error.message);
    } catch (e) {
      state = const LoginError('Something went wrong. Please try again.');
    }
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);