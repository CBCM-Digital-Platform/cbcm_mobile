import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/metric_tile.dart';
import '../../../../routing/app_routes.dart';
import '../../learning/domain/curriculum.dart';
import '../../learning/presentation/curriculum_controller.dart';

final _userNameProvider = FutureProvider.autoDispose((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return (await storage.read(StorageKeys.userName)) ?? 'there';
});

class MenteeDashboardPage extends ConsumerStatefulWidget {
  const MenteeDashboardPage({super.key});

  @override
  ConsumerState<MenteeDashboardPage> createState() => _MenteeDashboardPageState();
}

class _MenteeDashboardPageState extends ConsumerState<MenteeDashboardPage> {
  bool _expandAll = false;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(_userNameProvider);
    final curriculum = ref.watch(curriculumControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: curriculum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load your progress')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            name.when(
              data: (n) => _WelcomeCard(name: n, curriculum: data),
              loading: () => _WelcomeCard(name: '...', curriculum: data),
              error: (_, __) => _WelcomeCard(name: 'there', curriculum: data),
            ),
            const SizedBox(height: 20),
            Text('Curriculum Key Metrics',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetricsGrid(curriculum: data),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Curriculum Breakdown',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => setState(() => _expandAll = !_expandAll),
                  child: Text(_expandAll ? 'Collapse All' : 'Expand All'),
                ),
              ],
            ),
            for (var i = 0; i < data.chapters.length; i++)
              _ChapterTile(
                chapter: data.chapters[i],
                state: i < data.activeChapterIndex
                    ? _ChapterState.completed
                    : i == data.activeChapterIndex
                        ? _ChapterState.active
                        : _ChapterState.locked,
                expanded: _expandAll,
                activeModuleId: i == data.activeChapterIndex
                    ? data.activeModule?.id
                    : null,
              ),
            const SizedBox(height: 24),
            Text('Clinical Support & Simulation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _MentorCardPlaceholder(),
            const SizedBox(height: 12),
            const _SessionCardPlaceholder(),
            const SizedBox(height: 12),
            const _ResourceCardPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends ConsumerWidget {
  const _WelcomeCard({required this.name, required this.curriculum});
  final String name;
  final CurriculumProgress curriculum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = curriculum.nextLesson;
    final module = curriculum.activeModule;
    final isFresh = curriculum.curriculumPercent == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFresh ? 'Welcome, $name!' : 'Welcome back, $name!',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (curriculum.activeChapter != null) ...[
            const SizedBox(height: 4),
            Text(
              'Chapter ${curriculum.activeChapter!.number}: ${curriculum.activeChapter!.title}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (lesson != null && module != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT UP IN MODULE ${module.number}',
                      style: TextStyle(
                          color: AppColors.pageIndicator,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(lesson.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: lesson.status == LessonStatus.inProgress
                          ? lesson.progressPercent / 100
                          : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      color: AppColors.pageIndicator,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Est. ~${lesson.durationMinutes} min${lesson.isAudio ? ' • Audio' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: lesson.status == LessonStatus.inProgress
                    ? 'Resume Lesson'
                    : 'Start Lesson',
                onPressed: () {
                  if (lesson.status == LessonStatus.inProgress) {
                    ref.read(curriculumControllerProvider.notifier).completeLesson(lesson.id);
                  } else {
                    ref.read(curriculumControllerProvider.notifier).startLesson(lesson.id);
                  }
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text("You've completed every chapter!",
                style: TextStyle(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.curriculum});
  final CurriculumProgress curriculum;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.0,
      children: [
        MetricTile(
          label: 'Curriculum',
          value: '${curriculum.curriculumPercent.toStringAsFixed(0)}%',
        ),
        MetricTile(
          label: 'Chapters',
          value: '${curriculum.completedChapters} / ${curriculum.totalChapters}',
        ),
        MetricTile(
          label: 'Modules Completed',
          value: '${curriculum.completedModules} / ${curriculum.totalModules}',
        ),
        MetricTile(
          label: 'CPD Accrued',
          value: '${curriculum.cpdHoursAccrued} / ${curriculum.cpdHoursRequired.toStringAsFixed(0)} hrs',
        ),
      ],
    );
  }
}

enum _ChapterState { completed, active, locked }

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.state,
    required this.expanded,
    this.activeModuleId,
  });

  final Chapter chapter;
  final _ChapterState state;
  final bool expanded;
  final String? activeModuleId;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      _ChapterState.completed => (Icons.check_circle, Colors.green),
      _ChapterState.active => (Icons.play_circle_fill, AppColors.primary),
      _ChapterState.locked => (Icons.lock_outline, Colors.grey),
    };

    final showModules = expanded || state == _ChapterState.active;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: state == _ChapterState.active ? AppColors.primary.withValues(alpha: 0.06) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Chapter ${chapter.number}: ${chapter.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (showModules)
              for (final m in chapter.modules)
                m.id == activeModuleId
                    ? _ActiveModuleBlock(module: m)
                    : ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 32),
                        title: Text('Module ${m.number}: ${m.title}'),
                        trailing: Text(
                            '${m.completedLessons}/${m.totalLessons} (${m.percent.toStringAsFixed(0)}%)'),
                        onTap: state == _ChapterState.locked
                            ? null
                            : () => context.push(AppRoutes.moduleDetail, extra: m),
                      ),
          ],
        ),
      ),
    );
  }
}

/// The in-progress module, expanded inline with its full lesson list.
class _ActiveModuleBlock extends ConsumerWidget {
  const _ActiveModuleBlock({required this.module});
  final CurriculumModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Module ${module.number}: ${module.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Chip(
                label: Text('${module.completedLessons} of ${module.totalLessons} Done'),
                backgroundColor: AppColors.pageIndicator.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final lesson in module.lessons) _LessonRow(lesson: lesson),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Continue Module ${module.number} →',
              onPressed: () {
                final lesson = module.nextLesson;
                if (lesson == null) return;
                if (lesson.status == LessonStatus.inProgress) {
                  ref.read(curriculumControllerProvider.notifier).completeLesson(lesson.id);
                } else {
                  ref.read(curriculumControllerProvider.notifier).startLesson(lesson.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final icon = switch (lesson.status) {
      LessonStatus.completed => Icons.check_circle,
      LessonStatus.inProgress => Icons.play_circle_fill,
      LessonStatus.notStarted => Icons.radio_button_unchecked,
    };
    final color = switch (lesson.status) {
      LessonStatus.completed => Colors.green,
      LessonStatus.inProgress => AppColors.primary,
      LessonStatus.notStarted => Colors.grey,
    };
    final subtitle = lesson.status == LessonStatus.inProgress
        ? 'In progress (${lesson.progressPercent.toStringAsFixed(0)}%)'
        : '${lesson.durationMinutes} min';

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(lesson.title),
      subtitle: Text(subtitle),
    );
  }
}

// --- Placeholders below: these features don't exist yet (messaging in
// Week 7, mentorship scheduling and resources are separate, later features).
// Shown here only so the layout matches the design; not wired to real data.

class _MentorCardPlaceholder extends StatelessWidget {
  const _MentorCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Mentor', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Assigned once mentorship matching is built',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCardPlaceholder extends StatelessWidget {
  const _SessionCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.event_outlined, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text('No upcoming clinical sessions scheduled',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCardPlaceholder extends StatelessWidget {
  const _ResourceCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.menu_book_outlined, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text('Resources will appear here once available',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}