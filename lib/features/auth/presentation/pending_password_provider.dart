import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The temporary password the user just typed at login, held in memory only
/// so the forced password change doesn't ask for it a second time.
/// Never saved to disk. Cleared after the change, on logout, and when the
/// app closes.
class PendingPasswordNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? password) => state = password;
  void clear() => state = null;
}

final pendingPasswordProvider =
    NotifierProvider<PendingPasswordNotifier, String?>(
  PendingPasswordNotifier.new,
);