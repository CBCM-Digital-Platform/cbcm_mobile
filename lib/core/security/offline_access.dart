import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_provider.dart';

enum AccessLevel { checking, valid, expired }

class AccessStatus {
  const AccessStatus(this.level, {this.daysLeft = 0});
  final AccessLevel level;
  final int daysLeft;
}

/// Checks, online, that the signed-in user may still use paid material.
abstract class AccessVerifier {
  Future<bool> verify();
}

/// Today: asks the server to validate the signed-in session. Later this is
/// where the subscription and course-access check goes.
class SessionAccessVerifier implements AccessVerifier {
  SessionAccessVerifier(this._dio);
  final Dio _dio;

  @override
  Future<bool> verify() async {
    try {
      final res = await _dio.get(ApiEndpoints.session);
      final body = res.data;
      return body is Map && body['success'] == true;
    } on DioException {
      return false;
    }
  }
}

final accessVerifierProvider = Provider<AccessVerifier>((ref) {
  return SessionAccessVerifier(ref.watch(dioProvider));
});

/// Decides whether downloaded files may be opened right now.
class OfflineAccess extends Notifier<AccessStatus> {
  /// PROPOSED policy, subject to business approval.
  static const maxOfflineDays = 7;

  static const _verifiedKey = 'access_verified_at';
  static const _seenKey = 'access_last_seen_at';

  SecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  AccessStatus build() {
    refresh();
    return const AccessStatus(AccessLevel.checking);
  }

  Future<AccessStatus> refresh() async {
    final status = await _compute();
    state = status;
    return status;
  }

  Future<AccessStatus> _compute() async {
    final verifiedText = await _storage.read(_verifiedKey);
    final seenText = await _storage.read(_seenKey);
    final verified =
        verifiedText == null ? null : DateTime.tryParse(verifiedText);
    final seen = seenText == null ? null : DateTime.tryParse(seenText);
    final now = DateTime.now();

    if (verified == null) return const AccessStatus(AccessLevel.expired);

    // The clock was moved backwards: don't trust the offline period.
    if (seen != null && now.isBefore(seen.subtract(const Duration(minutes: 5)))) {
      return const AccessStatus(AccessLevel.expired);
    }
    if (seen == null || now.isAfter(seen)) {
      await _storage.write(_seenKey, now.toIso8601String());
    }

    final remaining =
        const Duration(days: maxOfflineDays) - now.difference(verified);
    if (remaining <= Duration.zero) {
      return const AccessStatus(AccessLevel.expired);
    }
    return AccessStatus(
      AccessLevel.valid,
      daysLeft: (remaining.inHours / 24).ceil(),
    );
  }

  /// Records that access was just confirmed online.
  Future<void> markVerified() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(_verifiedKey, now);
    await _storage.write(_seenKey, now);
    await refresh();
  }

  /// Tries to confirm access with the server. False when offline or refused.
  Future<bool> verifyNow() async {
    try {
      if (await ref.read(accessVerifierProvider).verify()) {
        await markVerified();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// True if a downloaded file may be opened now. Tries an online check
  /// first when the offline period has run out.
  Future<bool> ensureAccess() async {
    final status = await refresh();
    if (status.level == AccessLevel.valid) return true;
    return verifyNow();
  }

  /// DEBUG ONLY: pretends the last verification was [by] ago.
  Future<void> debugAge(Duration by) async {
    final aged = DateTime.now().subtract(by);
    await _storage.write(_verifiedKey, aged.toIso8601String());
    await refresh();
  }
}

final offlineAccessProvider =
    NotifierProvider<OfflineAccess, AccessStatus>(OfflineAccess.new);