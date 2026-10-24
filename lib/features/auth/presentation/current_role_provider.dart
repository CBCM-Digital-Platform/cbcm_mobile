import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/user_role.dart';
import 'must_change_password_provider.dart';
import 'pending_password_provider.dart';

class CurrentRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() {
    _restoreSession();
    return null; // starts null, then updates once storage is read
  }

  Future<void> _restoreSession() async {
    final savedRole =
        await ref.read(secureStorageProvider).read(StorageKeys.userRole);

    if (savedRole == UserRole.mentee.name) {
      state = UserRole.mentee;
    } else if (savedRole == UserRole.mentor.name) {
      state = UserRole.mentor;
    }
  }

  void setRole(UserRole? role) => state = role;

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);

    // Leave protected screens immediately, then clean up.
    state = null;
    ref.read(pendingPasswordProvider.notifier).clear();
    ref.read(mustChangePasswordProvider.notifier).set(false);

    await Future.wait([
      storage.delete(StorageKeys.accessToken),
      storage.delete(StorageKeys.refreshToken),
      storage.delete(StorageKeys.userRole),
      storage.delete(StorageKeys.userId),
      storage.delete(StorageKeys.userName),
      storage.delete(StorageKeys.userEmail),
    ]);
  }
}

final currentRoleProvider =
    NotifierProvider<CurrentRoleNotifier, UserRole?>(
  CurrentRoleNotifier.new,
);