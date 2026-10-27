import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/security/offline_access.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../messaging/data/messaging_providers.dart';
import '../../messaging/data/temporary_contacts.dart';
import '../../mentor/mentees/data/assigned_mentees_provider.dart';
import '../../mentor/sessions/data/assignments_provider.dart';
import '../data/auth_repository_provider.dart';
import '../domain/user.dart';
import 'current_role_provider.dart';
import 'must_change_password_provider.dart';
import 'pending_password_provider.dart';

/// TEMPORARY dev switch: lets accounts that still have a temporary password
/// reach the dashboard without changing it. Only works in debug builds.
const _devSkipForcedReset = false;

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

      debugPrint('[LOGIN] role=${user.role.name} id=${user.id} '
          'name=${user.name} mustChangePassword=${user.mustChangePassword}');

      if (kDebugMode && _devSkipForcedReset && user.mustChangePassword) {
        user = User(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          mustChangePassword: false,
        );
      }

      // Remember the temporary password in memory only, for the forced change.
      final pending = ref.read(pendingPasswordProvider.notifier);
      if (user.mustChangePassword) {
        pending.set(password);
      } else {
        pending.clear();
      }

      // Set this BEFORE the role so the router never flashes the dashboard.
      ref.read(mustChangePasswordProvider.notifier).set(user.mustChangePassword);

      // Tokens are saved by the repository itself.
      final storage = ref.read(secureStorageProvider);
      await Future.wait([
        storage.write(StorageKeys.userRole, user.role.name),
        storage.write(StorageKeys.userId, user.id),
        storage.write(StorageKeys.userName, user.name),
      ]);

      ref.read(currentRoleProvider.notifier).setRole(user.role);
      ref.invalidate(currentUserIdProvider);
      ref.invalidate(conversationsProvider);
      ref.invalidate(contactsApiProvider);
      ref.invalidate(assignedMenteesProvider);
      ref.invalidate(mentorAssignmentsProvider);

      // Not awaited: login should not wait for this bookkeeping.
      ref.read(offlineAccessProvider.notifier).markVerified();

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