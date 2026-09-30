import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';
import 'mock_auth_repository.dart';

/// Swap MockAuthRepository() for a real Dio-backed one here when the
/// backend is ready. Nothing else in the app needs to change.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
