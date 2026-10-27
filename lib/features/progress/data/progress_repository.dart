import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';

double? _num(Object? v) => v == null ? null : double.tryParse('$v');

dynamic _unwrap(dynamic raw) =>
    raw is Map && raw['data'] != null ? raw['data'] : raw;

List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)]
    : const [];

class Competency {
  const Competency({
    required this.thematicAreaId,
    required this.score,
    required this.level,
  });
  final int thematicAreaId;
  final double score;
  final String level;
}

class MenteeProgress {
  const MenteeProgress({required this.competencies, required this.snapshotCount});
  final List<Competency> competencies;
  final int snapshotCount;

  double? get average => competencies.isEmpty
      ? null
      : competencies.fold<double>(0, (s, c) => s + c.score) /
          competencies.length;
}

class ProgressRepository {
  ProgressRepository(this._dio);
  final Dio _dio;

  Future<MenteeProgress> forMentee(int menteeId) async {
    try {
      final results = await Future.wait([
        _dio.get('/progress/mentees/$menteeId/competencies'),
        _dio.get('/progress/mentees/$menteeId/knowledge-snapshots'),
      ]);

      final comp = _unwrap(results[0].data);
      final list = comp is Map ? comp['latest_competencies'] : comp;
      final competencies = [
        for (final m in _maps(list))
          if (_num(m['score']) != null)
            Competency(
              thematicAreaId: (_num(m['thematic_area_id']) ?? 0).toInt(),
              score: _num(m['score'])!,
              level: (m['competency_level'] ?? '').toString(),
            ),
      ];

      final snaps = _unwrap(results[1].data);
      final count = snaps is List
          ? snaps.length
          : (snaps is Map && snaps['items'] is List
              ? (snaps['items'] as List).length
              : 0);

      return MenteeProgress(competencies: competencies, snapshotCount: count);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  /// Names come from the cycles' thematic areas (any signed-in user may
  /// read them), because GET /thematic-areas is administrators only.
  Future<Map<int, String>> thematicAreaNames() async {
    try {
      final raw = _unwrap((await _dio.get('/mentorship-cycles')).data);
      final cycles = _maps(raw is Map ? raw['items'] : raw);
      final names = <int, String>{};
      for (final c in cycles.take(3)) {
        final id = _num(c['id'])?.toInt();
        if (id == null) continue;
        try {
          final r = await _dio.get('/mentorship-cycles/$id/thematic-areas');
          for (final a in _maps(_unwrap(r.data))) {
            final aid = _num(a['id'])?.toInt();
            if (aid != null) names[aid] = (a['name'] ?? a['code'] ?? '').toString();
          }
        } catch (_) {}
      }
      return names;
    } catch (_) {
      return const {};
    }
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(dioProvider)),
);

final menteeProgressProvider =
    FutureProvider.autoDispose.family<MenteeProgress, int>(
  (ref, id) => ref.watch(progressRepositoryProvider).forMentee(id),
);

final thematicAreaNamesProvider = FutureProvider<Map<int, String>>(
  (ref) => ref.watch(progressRepositoryProvider).thematicAreaNames(),
);