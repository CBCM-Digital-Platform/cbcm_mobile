import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../data/auth_repository_provider.dart';
import '../domain/user.dart';
import 'current_role_provider.dart';

/// TEMPORARY dev switch: lets the shared test accounts reach the dashboard
/// without changing their shared password. Only works in debug builds.
/// Set to false (or delete) once you have your own test accounts.
const _devSkipForcedReset = true;

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
      var user = await repo.login(email: email, password: password);

      debugPrint('[LOGIN] role=${user.role.name} '
          'mustChangePassword=${user.mustChangePassword}');

      if (kDebugMode && _devSkipForcedReset && user.mustChangePassword) {
        user = User(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          mustChangePassword: false,
        );
      }

      // Tokens are saved by the repository itself (real or mock).
      final storage = ref.read(secureStorageProvider);
      await storage.write(StorageKeys.userRole, user.role.name);
      await storage.write(StorageKeys.userId, user.id);
      await storage.write(StorageKeys.userName, user.name);

      ref.read(currentRoleProvider.notifier).setRole(user.role);

      state = LoginSuccess(user);
    } on ApiException catch (e) {
      debugPrint('[LOGIN] ApiException code=${e.error.code} message=${e.error.message}');
      state = LoginError(e.error.message);
    } catch (e, stack) {
      debugPrint('[LOGIN] Unexpected error: $e');
      debugPrint('[LOGIN] $stack');
      state = const LoginError('Something went wrong. Please try again.');
    }
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);