import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_role.dart';

// Temporary fake role. Replaced by real auth state in Week 2.
class CurrentRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null; // null = not logged in

  void setRole(UserRole? role) => state = role;
}

final currentRoleProvider =
    NotifierProvider<CurrentRoleNotifier, UserRole?>(CurrentRoleNotifier.new);