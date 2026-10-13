import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../domain/auth_repository.dart';
import 'dio_auth_repository.dart';
import 'mock_auth_repository.dart';

/// false = fake data (works with no server). true = real backend.
/// Flip to true once you have working test accounts.
const _useRealBackend = true;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  if (_useRealBackend) {
    return DioAuthRepository(ref.watch(dioProvider), storage);
  }
  return MockAuthRepository(storage);
});