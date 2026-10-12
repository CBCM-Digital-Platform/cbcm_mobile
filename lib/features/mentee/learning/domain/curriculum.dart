enum LessonStatus { notStarted, inProgress, completed }

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.status,
    this.progressPercent = 0,
    this.isAudio = false,
    this.content = '',
  });

  final String id;
  final String title;
  final int durationMinutes;
  final LessonStatus status;
  final double progressPercent;
  final bool isAudio;

  /// The readable/listenable lesson content.
  final String content;

  Lesson copyWith({
    LessonStatus? status,
    double? progressPercent,
    bool? isAudio,
    String? content,
  }) {
    return Lesson(
      id: id,
      title: title,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      isAudio: isAudio ?? this.isAudio,
      content: content ?? this.content,
    );
  }
}

class CurriculumModule {
  const CurriculumModule({
    required this.id,
    required this.number,
    required this.title,
    required this.lessons,
  });

  CurriculumModule replacingLesson(Lesson updated) {
    return CurriculumModule(
      id: id,
      number: number,
      title: title,
      lessons: [for (final l in lessons) l.id == updated.id ? updated : l],
    );
  }

  final String id;
  final int number;
  final String title;
  final List<Lesson> lessons;

  int get completedLessons =>
      lessons.where((l) => l.status == LessonStatus.completed).length;
  int get totalLessons => lessons.length;
  double get percent =>
      totalLessons == 0 ? 0 : (completedLessons / totalLessons * 100);
  bool get isCompleted => totalLessons > 0 && completedLessons == totalLessons;
  bool get isStarted => lessons.any((l) => l.status != LessonStatus.notStarted);

  Lesson? get nextLesson {
    for (final l in lessons) {
      if (l.status != LessonStatus.completed) return l;
    }
    return null;
  }
}

class Chapter {
  const Chapter({
    required this.id,
    required this.number,
    required this.title,
    required this.modules,
  });

  Chapter replacingModule(CurriculumModule updated) {
    return Chapter(
      id: id,
      number: number,
      title: title,
      modules: [for (final m in modules) m.id == updated.id ? updated : m],
    );
  }

  final String id;
  final int number;
  final String title;
  final List<CurriculumModule> modules;

  int get completedModules => modules.where((m) => m.isCompleted).length;
  int get totalModules => modules.length;
  bool get isCompleted => totalModules > 0 && completedModules == totalModules;
}

class CurriculumProgress {
  const CurriculumProgress({
    required this.cohortLabel,
    required this.chapters,
    required this.cpdHoursAccrued,
    required this.cpdHoursRequired,
  });

  /// Returns a new CurriculumProgress with the given lesson's status
  /// (and, for in-progress, its percent) updated. Used to apply progress
  /// changes locally without re-fetching everything from the repository.
  CurriculumProgress updatingLesson(
    String lessonId, {
    required LessonStatus status,
    double progressPercent = 0,
  }) {
    for (final chapter in chapters) {
      for (final module in chapter.modules) {
        final hasLesson = module.lessons.any((l) => l.id == lessonId);
        if (!hasLesson) continue;
        final updatedLesson = module.lessons
            .firstWhere((l) => l.id == lessonId)
            .copyWith(status: status, progressPercent: progressPercent);
        final updatedModule = module.replacingLesson(updatedLesson);
        final updatedChapter = chapter.replacingModule(updatedModule);
        return CurriculumProgress(
          cohortLabel: cohortLabel,
          cpdHoursAccrued: cpdHoursAccrued,
          cpdHoursRequired: cpdHoursRequired,
          chapters: [
            for (final c in chapters) c.id == updatedChapter.id ? updatedChapter : c
          ],
        );
      }
    }
    return this; // lesson not found, no change
  }

  final String cohortLabel;
  final List<Chapter> chapters;
  final double cpdHoursAccrued;
  final double cpdHoursRequired;

  int get totalChapters => chapters.length;
  int get completedChapters => chapters.where((c) => c.isCompleted).length;

  int get totalModules => chapters.fold(0, (s, c) => s + c.totalModules);
  int get completedModules =>
      chapters.fold(0, (s, c) => s + c.completedModules);

  int get totalLessons =>
      chapters.fold(0, (s, c) => s + c.modules.fold(0, (s2, m) => s2 + m.totalLessons));
  int get completedLessons => chapters.fold(
      0, (s, c) => s + c.modules.fold(0, (s2, m) => s2 + m.completedLessons));

  double get curriculumPercent {
    return totalLessons == 0 ? 0 : (completedLessons / totalLessons * 100);
  }

  /// Index of the first chapter that isn't fully completed, or -1 if every
  /// chapter is done.
  int get activeChapterIndex => chapters.indexWhere((c) => !c.isCompleted);
  Chapter? get activeChapter =>
      activeChapterIndex == -1 ? null : chapters[activeChapterIndex];

  CurriculumModule? get activeModule {
    final chapter = activeChapter;
    if (chapter == null) return null;
    for (final m in chapter.modules) {
      if (!m.isCompleted) return m;
    }
    return null;
  }

  Lesson? get nextLesson => activeModule?.nextLesson;

  CurriculumModule? findModule(String id) {
    for (final c in chapters) {
      for (final m in c.modules) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  /// Modules in the same chapter as [module], after it.
  List<CurriculumModule> modulesAfter(CurriculumModule module) {
    for (final c in chapters) {
      final idx = c.modules.indexWhere((m) => m.id == module.id);
      if (idx != -1) return c.modules.sublist(idx + 1);
    }
    return [];
  }
}