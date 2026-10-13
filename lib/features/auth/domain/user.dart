import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool mustChangePassword;
}