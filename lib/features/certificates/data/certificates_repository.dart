import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/certificate.dart';

class CertificatesRepository {
  CertificatesRepository(this._dio);

  final Dio _dio;

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map) {
        final items = d['items'] ?? d['certificates'];
        if (items is List) return items;
      }
      final items = raw['items'] ?? raw['certificates'];
      if (items is List) return items;
    }
    return const [];
  }

  Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map) {
      final d = raw['data'];
      if (d is Map) return Map<String, dynamic>.from(d);
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  /// Lists certificates with optional filters (mentee_id, cycle_id, thematic_area_id, status).
  Future<List<Certificate>> list({
    int? menteeId,
    int? cycleId,
    int? thematicAreaId,
    String? status,
  }) async {
    try {
      final query = <String, dynamic>{'limit': 50};
      if (menteeId != null && menteeId > 0) query['mentee_id'] = menteeId;
      if (cycleId != null && cycleId > 0) query['cycle_id'] = cycleId;
      if (thematicAreaId != null && thematicAreaId > 0) query['thematic_area_id'] = thematicAreaId;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final res = await _dio.get('/certificates', queryParameters: query);
      final rawList = _extractList(res.data);
      return rawList
          .whereType<Map>()
          .map((m) => Certificate.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      debugPrint('[CertificatesRepository] list failed: ${e.message}');
      if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
        return const [];
      }
      throw apiExceptionFromDio(e);
    } catch (e) {
      debugPrint('[CertificatesRepository] list error: $e');
      return const [];
    }
  }

  /// Fetches a single certificate by ID.
  Future<Certificate> getById(int id) async {
    try {
      final res = await _dio.get('/certificates/$id');
      final data = _extractMap(res.data);
      if (data == null) throw StateError('Empty response for certificate $id');
      return Certificate.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[CertificatesRepository] getById failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Checks certificate eligibility for a mentee in a specific cycle and thematic area.
  Future<CertificateEligibility> checkEligibility({
    required int menteeId,
    required int cycleId,
    required int thematicAreaId,
  }) async {
    try {
      final res = await _dio.get(
        '/certificates/eligibility/$menteeId/$cycleId/$thematicAreaId',
      );
      final data = _extractMap(res.data);
      if (data != null) {
        return CertificateEligibility.fromJson(data);
      }
      return const CertificateEligibility(isEligible: false);
    } on DioException catch (e) {
      debugPrint('[CertificatesRepository] checkEligibility failed: ${e.message}');
      if (e.response?.statusCode == 403 || e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        final d = _extractMap(e.response?.data);
        final msg = d?['error']?['message'] ?? e.message;
        return CertificateEligibility(
          isEligible: false,
          message: msg?.toString(),
        );
      }
      return CertificateEligibility(isEligible: false, message: e.message);
    } catch (e) {
      return CertificateEligibility(isEligible: false, message: e.toString());
    }
  }

  /// Issues a certificate for an eligible mentee.
  Future<Certificate> issueCertificate({
    required int menteeId,
    required int cycleId,
    required int thematicAreaId,
    int? templateId,
  }) async {
    try {
      final body = <String, dynamic>{
        'mentee_id': menteeId,
        'cycle_id': cycleId,
        'thematic_area_id': thematicAreaId,
      };
      if (templateId != null) body['template_id'] = templateId;

      final res = await _dio.post('/certificates', data: body);
      final data = _extractMap(res.data);
      if (data == null) throw StateError('Empty response when issuing certificate');
      return Certificate.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[CertificatesRepository] issueCertificate failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }
}

final certificatesRepositoryProvider = Provider<CertificatesRepository>((ref) {
  return CertificatesRepository(ref.watch(dioProvider));
});

final menteeCertificatesProvider =
    FutureProvider.autoDispose.family<List<Certificate>, int?>((ref, menteeId) {
  final repo = ref.watch(certificatesRepositoryProvider);
  return repo.list(menteeId: menteeId);
});

class EligibilityQuery {
  const EligibilityQuery({
    required this.menteeId,
    required this.cycleId,
    required this.thematicAreaId,
  });

  final int menteeId;
  final int cycleId;
  final int thematicAreaId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EligibilityQuery &&
          runtimeType == other.runtimeType &&
          menteeId == other.menteeId &&
          cycleId == other.cycleId &&
          thematicAreaId == other.thematicAreaId;

  @override
  int get hashCode => Object.hash(menteeId, cycleId, thematicAreaId);
}

final certificateEligibilityProvider = FutureProvider.autoDispose
    .family<CertificateEligibility, EligibilityQuery>((ref, query) {
  final repo = ref.watch(certificatesRepositoryProvider);
  return repo.checkEligibility(
    menteeId: query.menteeId,
    cycleId: query.cycleId,
    thematicAreaId: query.thematicAreaId,
  );
});
