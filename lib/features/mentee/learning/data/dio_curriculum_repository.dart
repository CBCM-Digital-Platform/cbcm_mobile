import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/curriculum.dart';
import '../domain/curriculum_repository.dart';
import 'curriculum_seed_data.dart';

class DioCurriculumRepository implements CurriculumRepository {
  DioCurriculumRepository(this._dio);

  final Dio _dio;
  final Map<String, int> _lessonToModule = {};

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final d = raw['data'];
      if (d is List) {
        return [for (final item in d) if (item is Map) Map<String, dynamic>.from(item)];
      }
    }
    if (raw is List) {
      return [for (final item in raw) if (item is Map) Map<String, dynamic>.from(item)];
    }
    return const [];
  }

  @override
  Future<CurriculumProgress> getCurriculumProgress(String menteeId) async {
    try {
      // 1. Fetch modules assigned to the authenticated mentee
      List<Map<String, dynamic>> moduleItems = [];
      try {
        final res = await _dio.get('/learning/my/modules');
        moduleItems = _extractList(res.data);
      } on DioException catch (e) {
        debugPrint('[LEARNING] /learning/my/modules: ${e.message}');
      }

      // If no modules specifically assigned to mentee yet, fetch all available modules
      if (moduleItems.isEmpty) {
        try {
          final res = await _dio.get('/learning/modules');
          moduleItems = _extractList(res.data);
        } on DioException catch (e) {
          debugPrint('[LEARNING] /learning/modules: ${e.message}');
        }
      }

      // If still empty (e.g. offline, mock, or empty backend database), use seed data fallback
      if (moduleItems.isEmpty) {
        return menteeId == 'mentee-1'
            ? CurriculumSeedData.inProgressMentee
            : CurriculumSeedData.freshMentee;
      }

      // 2. For each module, fetch contents and completion progress
      final List<CurriculumModule> curriculumModules = [];
      final Map<String, List<CurriculumModule>> groupedByThematic = {};

      for (int i = 0; i < moduleItems.length; i++) {
        final m = moduleItems[i];
        final rawId = m['id'];
        final moduleId = rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? (i + 1);
        final title = (m['title'] ?? 'Module ${i + 1}').toString();
        final orderNum = (m['orderNumber'] ?? m['order_number'] ?? (i + 1)) as num;

        // Fetch contents
        List<Map<String, dynamic>> contentItems = [];
        try {
          final cRes = await _dio.get('/learning/modules/$moduleId/contents');
          contentItems = _extractList(cRes.data);
        } catch (_) {
          if (m['contents'] is List) {
            contentItems = [
              for (final c in (m['contents'] as List))
                if (c is Map) Map<String, dynamic>.from(c)
            ];
          }
        }

        // Fetch completion progress for this module
        final Set<int> completedContentIds = {};
        try {
          final pRes = await _dio.get('/learning/my/modules/$moduleId/contents/progress');
          final progList = _extractList(pRes.data);
          for (final p in progList) {
            if (p['status'] == 'completed') {
              final cId = p['contentId'] ?? p['content_id'];
              if (cId is num) completedContentIds.add(cId.toInt());
            }
          }
        } catch (_) {}

        // Map contents to Lessons
        final List<Lesson> lessons = [];
        for (int j = 0; j < contentItems.length; j++) {
          final c = contentItems[j];
          final rawContentId = c['id'];
          final contentId = rawContentId is num ? rawContentId.toInt() : int.tryParse('$rawContentId') ?? (j + 1);
          final lessonIdStr = '$contentId';

          _lessonToModule[lessonIdStr] = moduleId;

          final isDone = completedContentIds.contains(contentId);
          final lessonTitle = (c['title'] ?? 'Lesson ${j + 1}').toString();
          final duration = (c['durationMinutes'] ?? c['duration_minutes'] ?? 10) as num;
          final typeStr = (c['type'] ?? 'article').toString().toLowerCase();

          lessons.add(Lesson(
            id: lessonIdStr,
            title: lessonTitle,
            durationMinutes: duration.toInt(),
            status: isDone ? LessonStatus.completed : LessonStatus.notStarted,
            progressPercent: isDone ? 100 : 0,
            isAudio: typeStr == 'audio',
            content: (c['contentText'] ?? c['content_text'] ?? '').toString(),
          ));
        }

        final mod = CurriculumModule(
          id: '$moduleId',
          number: orderNum.toInt(),
          title: title,
          lessons: lessons,
        );

        curriculumModules.add(mod);

        final thematicName = m['thematicArea'] is Map
            ? (m['thematicArea']['name'] ?? 'Core Curriculum').toString()
            : (m['thematic_area'] is Map
                ? (m['thematic_area']['name'] ?? 'Core Curriculum').toString()
                : 'Core Curriculum');

        groupedByThematic.putIfAbsent(thematicName, () => []).add(mod);
      }

      // 3. Build Chapters
      final List<Chapter> chapters = [];
      int chapterNum = 1;
      for (final entry in groupedByThematic.entries) {
        chapters.add(Chapter(
          id: 'ch-$chapterNum',
          number: chapterNum,
          title: entry.key,
          modules: entry.value,
        ));
        chapterNum++;
      }

      // 4. Calculate CPD hours
      int totalMinutes = 0;
      int completedMinutes = 0;
      for (final mod in curriculumModules) {
        for (final l in mod.lessons) {
          totalMinutes += l.durationMinutes;
          if (l.status == LessonStatus.completed) {
            completedMinutes += l.durationMinutes;
          }
        }
      }

      final cpdHoursAccrued = double.parse((completedMinutes / 60.0).toStringAsFixed(1));
      final cpdHoursRequired = totalMinutes > 0
          ? double.parse((totalMinutes / 60.0).toStringAsFixed(1))
          : 15.0;

      return CurriculumProgress(
        cohortLabel: '2026 Cohort',
        chapters: chapters,
        cpdHoursAccrued: cpdHoursAccrued,
        cpdHoursRequired: cpdHoursRequired,
      );
    } catch (e) {
      debugPrint('[LEARNING] Error loading curriculum: $e. Using fallback.');
      return menteeId == 'mentee-1'
          ? CurriculumSeedData.inProgressMentee
          : CurriculumSeedData.freshMentee;
    }
  }

  @override
  Future<void> updateLessonStatus({
    required String menteeId,
    required String lessonId,
    required LessonStatus status,
    double progressPercent = 0,
  }) async {
    if (status == LessonStatus.completed) {
      final moduleId = _lessonToModule[lessonId];
      final contentId = int.tryParse(lessonId);
      if (moduleId != null && contentId != null) {
        try {
          await _dio.post('/learning/my/modules/$moduleId/contents/$contentId/complete');
          debugPrint('[LEARNING] Marked content $contentId complete in module $moduleId');
        } on DioException catch (e) {
          debugPrint('[LEARNING] Mark complete error: ${e.message}');
        }
      }
    }
  }
}
