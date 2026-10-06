import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/user_role.dart';

// Temporary fake tokens for now. Replaced by real auth state in Week 2
// Day 3's Dio integration once the backend exists.
class CurrentRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() {
    _restoreSession();
    return null; // starts null, then updates async once storage is read
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final savedRole = await storage.read(StorageKeys.userRole);
    if (savedRole == UserRole.mentee.name) {
      state = UserRole.mentee;
    } else if (savedRole == UserRole.mentor.name) {
      state = UserRole.mentor;
    }
  }

  void setRole(UserRole? role) => state = role;

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(StorageKeys.accessToken);
    await storage.delete(StorageKeys.refreshToken);
    await storage.delete(StorageKeys.userRole);
    state = null;
  }
}

final currentRoleProvider =
    NotifierProvider<CurrentRoleNotifier, UserRole?>(CurrentRoleNotifier.new);
    