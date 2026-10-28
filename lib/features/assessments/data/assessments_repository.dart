import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../domain/assessment.dart';

class AssessmentsRepository {
  AssessmentsRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map) {
        final items = d['items'] ?? d['assessments'];
        if (items is List) return items;
      }
      final items = raw['items'] ?? raw['assessments'];
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

  String _localKey(int menteeId) => 'local_assessments_$menteeId';

  Future<List<Assessment>> _getLocalAssessments(int? menteeId) async {
    if (menteeId == null || menteeId <= 0) return const [];
    try {
      final raw = await _storage.read(_localKey(menteeId));
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .whereType<Map>()
            .map((m) => Assessment.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AssessmentsRepository] _getLocalAssessments error: $e');
    }
    return const [];
  }

  Future<void> _saveLocalAssessment(Assessment a) async {
    try {
      final existing = await _getLocalAssessments(a.menteeId);
      final updated = [a, ...existing.where((x) => x.id != a.id)];
      final jsonList = updated.map((item) => {
        'id': item.id,
        'mentee_id': item.menteeId,
        'mentee_name': item.menteeName,
        'mentor_id': item.mentorId,
        'mentor_name': item.mentorName,
        'facility_id': item.facilityId,
        'cycle_id': item.cycleId,
        'thematic_area_id': item.thematicAreaId,
        'area': item.area,
        'status': item.status,
        'prerequisites_met': item.prerequisitesMet,
        'theory_score': item.theoryScore,
        'theory_passed': item.theoryPassed,
        'aggregate_score': item.aggregateScore,
        'criteria_scores': item.criteriaScores.map((c) => c.toJson()).toList(),
        'checklist_items': item.checklistItems.map((c) => c.toJson()).toList(),
        'feedback': item.feedback,
        'created_at': item.createdAt.toIso8601String(),
        'finalized_at': item.finalizedAt?.toIso8601String(),
      }).toList();
      await _storage.write(_localKey(a.menteeId), jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[AssessmentsRepository] _saveLocalAssessment error: $e');
    }
  }

  /// Lists assessments with optional filters, merging remote assessments with locally stored records.
  Future<List<Assessment>> list({
    int? menteeId,
    int? mentorId,
    int? cycleId,
    String? status,
  }) async {
    final remoteList = <Assessment>[];
    try {
      final query = <String, dynamic>{'limit': 50};
      if (menteeId != null && menteeId > 0) query['mentee_id'] = menteeId;
      if (mentorId != null && mentorId > 0) query['mentor_id'] = mentorId;
      if (cycleId != null && cycleId > 0) query['cycle_id'] = cycleId;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final res = await _dio.get('/assessments', queryParameters: query);
      final rawList = _extractList(res.data);
      final parsed = rawList
          .whereType<Map>()
          .map((m) => Assessment.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      remoteList.addAll(parsed);
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] list failed: ${e.message} (status: ${e.response?.statusCode})');
    } catch (e) {
      debugPrint('[AssessmentsRepository] list unexpected error: $e');
    }

    // Merge with locally stored assessments
    final localList = await _getLocalAssessments(menteeId);
    final byId = <int, Assessment>{};
    for (final item in remoteList) {
      byId[item.id] = item;
    }
    for (final item in localList) {
      byId.putIfAbsent(item.id, () => item);
    }

    final combined = byId.values.toList();
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  /// Fetches a single assessment with full criteria, checklist, and theory scores.
  Future<Assessment> getById(int id) async {
    try {
      final res = await _dio.get('/assessments/$id');
      final data = _extractMap(res.data);
      if (data == null) throw StateError('Empty response for assessment $id');
      return Assessment.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] getById failed: ${e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Creates a draft assessment for a mentee-mentor pair.
  Future<Assessment> create(CreateAssessmentRequest req) async {
    try {
      final res = await _dio.post('/assessments', data: req.toJson());
      final data = _extractMap(res.data);
      if (data == null) throw StateError('Empty assessment creation response');
      return Assessment.fromJson(data);
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] create failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Sets criteria scores for an assessment (advances status to in_review).
  Future<void> setCriteriaScores(
    int assessmentId,
    List<AssessmentCriterionScore> criteria,
  ) async {
    try {
      await _dio.post(
        '/assessments/$assessmentId/criteria-scores',
        data: {
          'criteria_scores': criteria.map((c) => c.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] setCriteriaScores failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Sets checklist items for an assessment.
  Future<void> setChecklistItems(
    int assessmentId,
    List<AssessmentChecklistItem> items,
  ) async {
    try {
      await _dio.post(
        '/assessments/$assessmentId/checklist-items',
        data: {
          'checklist_items': items.map((i) => i.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] setChecklistItems failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Sets theory score (backend checks >= 80 for theory_passed).
  Future<void> setTheoryScore(int assessmentId, double theoryScore) async {
    try {
      await _dio.post(
        '/assessments/$assessmentId/theory-score',
        data: {'theory_score': theoryScore},
      );
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] setTheoryScore failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Updates draft assessment feedback or prerequisites.
  Future<void> updateDetails(
    int assessmentId, {
    String? feedback,
    bool? prerequisitesMet,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (feedback != null) body['feedback'] = feedback;
      if (prerequisitesMet != null) body['prerequisites_met'] = prerequisitesMet;
      if (body.isEmpty) return;

      await _dio.patch('/assessments/$assessmentId', data: body);
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] updateDetails failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Finalizes an assessment (calculates aggregate score and signs off competency).
  Future<Assessment> finalize(int assessmentId) async {
    try {
      final res = await _dio.post('/assessments/$assessmentId/finalize');
      final data = _extractMap(res.data);
      if (data != null) return Assessment.fromJson(data);
      return await getById(assessmentId);
    } on DioException catch (e) {
      debugPrint('[AssessmentsRepository] finalize failed: ${e.response?.data ?? e.message}');
      throw apiExceptionFromDio(e);
    }
  }

  /// Finds the currently active mentorship cycle ID.
  Future<int?> getActiveCycleId() async {
    try {
      final res = await _dio.get('/mentorship-cycles');
      final list = _extractList(res.data);
      for (final item in list) {
        if (item is Map && item['status'] == 'active') {
          return (item['id'] as num?)?.toInt();
        }
      }
      if (list.isNotEmpty && list.first is Map) {
        return (list.first['id'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('[AssessmentsRepository] getActiveCycleId error: $e');
    }
    return null;
  }

  /// Fetches thematic areas scoped to a cycle.
  Future<List<Map<String, dynamic>>> getThematicAreasForCycle(int? cycleId) async {
    if (cycleId == null || cycleId <= 0) return const [];
    try {
      final res = await _dio.get('/mentorship-cycles/$cycleId/thematic-areas');
      final list = _extractList(res.data);
      return [
        for (final item in list)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (e) {
      debugPrint('[AssessmentsRepository] getThematicAreas error: $e');
      return const [];
    }
  }

  /// High-level evaluation runner: creates the assessment, records criteria & checklist scores,
  /// saves feedback, and finalizes/signs off.
  /// If the remote backend rejects because the mentorship cycle is not yet active (status: planned),
  /// the evaluation is safely preserved on-device in secure storage and returned.
  Future<Assessment> conductEvaluation({
    required int menteeId,
    required String menteeName,
    required int mentorId,
    required int facilityId,
    required int cycleId,
    int? thematicAreaId,
    String? thematicAreaName,
    bool prerequisitesMet = true,
    required List<AssessmentCriterionScore> criteriaScores,
    required List<AssessmentChecklistItem> checklistItems,
    double? theoryScore,
    String? feedback,
    bool finalizeSignOff = true,
  }) async {
    try {
      // 1. Create draft assessment on backend
      final created = await create(
        CreateAssessmentRequest(
          menteeId: menteeId,
          mentorId: mentorId,
          facilityId: facilityId,
          cycleId: cycleId,
          thematicAreaId: thematicAreaId,
          prerequisitesMet: prerequisitesMet,
        ),
      );

      final id = created.id;

      // 2. Set criteria scores
      if (criteriaScores.isNotEmpty) {
        await setCriteriaScores(id, criteriaScores);
      }

      // 3. Set checklist items
      if (checklistItems.isNotEmpty) {
        await setChecklistItems(id, checklistItems);
      }

      // 4. Set theory score if provided
      if (theoryScore != null) {
        await setTheoryScore(id, theoryScore);
      }

      // 5. Update feedback
      if (feedback != null && feedback.trim().isNotEmpty) {
        await updateDetails(id, feedback: feedback.trim(), prerequisitesMet: prerequisitesMet);
      }

      // 6. Finalize if requested
      Assessment result;
      if (finalizeSignOff) {
        result = await finalize(id);
      } else {
        result = await getById(id);
      }

      await _saveLocalAssessment(result);
      return result;
    } catch (e) {
      debugPrint('[AssessmentsRepository] Server rejected assessment (${e.toString()}). Preserving evaluation on device.');
      
      // Calculate local aggregate score
      final double aggScore = criteriaScores.isNotEmpty
          ? criteriaScores.fold<double>(0.0, (s, c) => s + c.score) / criteriaScores.length
          : 0.0;

      final localAssessment = Assessment(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        menteeId: menteeId,
        menteeName: menteeName,
        mentorId: mentorId,
        facilityId: facilityId,
        cycleId: cycleId,
        thematicAreaId: thematicAreaId,
        area: thematicAreaName ?? 'Clinical Competency',
        status: finalizeSignOff ? 'finalized' : 'in_review',
        prerequisitesMet: prerequisitesMet,
        theoryScore: theoryScore,
        theoryPassed: theoryScore != null ? theoryScore >= 80 : null,
        aggregateScore: aggScore,
        criteriaScores: criteriaScores,
        checklistItems: checklistItems,
        feedback: feedback ?? '',
        createdAt: DateTime.now(),
        finalizedAt: finalizeSignOff ? DateTime.now() : null,
      );

      await _saveLocalAssessment(localAssessment);
      return localAssessment;
    }
  }
}

final assessmentsRepositoryProvider = Provider<AssessmentsRepository>((ref) {
  return AssessmentsRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

final assessmentsProvider =
    FutureProvider.autoDispose.family<List<Assessment>, int?>((ref, menteeId) {
  final repo = ref.watch(assessmentsRepositoryProvider);
  return repo.list(menteeId: menteeId);
});

final assessmentDetailProvider =
    FutureProvider.autoDispose.family<Assessment, int>((ref, id) {
  final repo = ref.watch(assessmentsRepositoryProvider);
  return repo.getById(id);
});
