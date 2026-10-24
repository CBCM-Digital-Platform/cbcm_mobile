import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';

/// Whether the signed-in user still has a temporary password. Held in memory
/// so the router can check it instantly instead of reading secure storage on
/// every navigation.
class MustChangePasswordNotifier extends Notifier<bool> {
  bool _touched = false;

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final saved = await ref
        .read(secureStorageProvider)
        .read(StorageKeys.mustChangePassword);
    if (!_touched && saved == 'true') state = true;
  }

  /// Updates memory and the saved copy.
  void set(bool value) {
    _touched = true;
    state = value;
    ref
        .read(secureStorageProvider)
        .write(StorageKeys.mustChangePassword, value.toString());
  }
}

final mustChangePasswordProvider =
    NotifierProvider<MustChangePasswordNotifier, bool>(
  MustChangePasswordNotifier.new,
);