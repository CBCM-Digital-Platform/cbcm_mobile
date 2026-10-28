import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../routing/app_routes.dart';
import '../domain/curriculum.dart';
import 'curriculum_controller.dart';
import '../../../progress/presentation/my_progress_section.dart';

class LearnPage extends ConsumerWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(curriculumControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(curriculumControllerProvider),
              child: const Text('Could not load your learning. Try again'),
            ),
          ),
          data: (data) => _LearnBody(data: data),
        ),
      ),
    );
  }
}

class _LearnBody extends StatelessWidget {
  const _LearnBody({required this.data});
  final CurriculumProgress data;

  @override
  Widget build(BuildContext context) {
    // -1 means every chapter is finished.
    final activeIndex =
        data.activeChapterIndex == -1 ? data.chapters.length : data.activeChapterIndex;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Learning',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _OverallCard(data: data),
        const SizedBox(height: 16),
        _ContinueCard(data: data),
        const SizedBox(height: 24),
        const _SectionTitle('My Progress'),
        for (var i = 0; i < data.chapters.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChapterCard(
              chapter: data.chapters[i],
              locked: i > activeIndex,
              startExpanded: i == activeIndex,
            ),
          ),
        const SizedBox(height: 14),
        const _SectionTitle('Assignments & Quizzes'),
        GestureDetector(
          onTap: () => context.push(AppRoutes.menteeQuiz),
          child: AppCard(
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Practice quiz (sample)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('My Competencies'),
        const MyProgressSection(),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push(AppRoutes.menteeAssessments),
          child: AppCard(
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Formal competency assessments & sign-offs',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push(AppRoutes.menteeCertificates),
          child: AppCard(
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined, color: Color(0xFFB8860B)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Clinical certificates & credentials',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Clinical Logbook'),
        GestureDetector(
          onTap: () => context.push(AppRoutes.menteeLogbook),
          child: AppCard(
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Clinical logbook: procedures and sessions recorded by your mentor',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Resources'),
        GestureDetector(
          onTap: () => context.push(AppRoutes.menteeResources),
          child: AppCard(
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resource library: handbooks, videos and audio, available offline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.onDark = false});
  final double value; // 0 to 1
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 6,
        backgroundColor: onDark
            ? Colors.white24
            : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
        color: onDark ? AppColors.pageIndicator : AppColors.primary,
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.data});
  final CurriculumProgress data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall progress',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            '${data.curriculumPercent.toStringAsFixed(0)}%',
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: data.curriculumPercent / 100, onDark: true),
          const SizedBox(height: 10),
          Text(
            '${data.completedModules} of ${data.totalModules} modules completed',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.data});
  final CurriculumProgress data;

  @override
  Widget build(BuildContext context) {
    final lesson = data.nextLesson;
    final module = data.activeModule;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (lesson == null || module == null) {
      return const AppCard(
        child: Text("You've completed every lesson. Well done!"),
      );
    }

    final inProgress = lesson.status == LessonStatus.inProgress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE LEARNING',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text('Module ${module.number}: ${module.title}',
              style: TextStyle(fontSize: 12, color: mutedColor)),
          const SizedBox(height: 4),
          Text(lesson.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (inProgress) ...[
            const SizedBox(height: 10),
            _ProgressBar(value: lesson.progressPercent / 100),
          ],
          const SizedBox(height: 8),
          Text(
            '~${lesson.durationMinutes} min${lesson.isAudio ? ' • Audio available' : ''}',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: inProgress ? 'Resume Lesson' : 'Start Lesson',
              onPressed: () =>
                  context.push(AppRoutes.lessonReader, extra: lesson),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.locked,
    required this.startExpanded,
  });

  final Chapter chapter;
  final bool locked;
  final bool startExpanded;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    var total = 0;
    var done = 0;
    for (final m in chapter.modules) {
      total += m.totalLessons;
      done += m.completedLessons;
    }
    final fraction = total == 0 ? 0.0 : done / total;
    final title = 'Chapter ${chapter.number}: ${chapter.title}';

    if (locked) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: mutedColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: mutedColor)),
            ),
            Text('Locked',
                style: TextStyle(color: mutedColor, fontSize: 12)),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: startExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressBar(value: fraction),
                  const SizedBox(height: 4),
                  Text('$done of $total lessons',
                      style: TextStyle(fontSize: 12, color: mutedColor)),
                ],
              ),
            ),
            children: [
              for (final m in chapter.modules)
                ListTile(
                  dense: true,
                  title: Text('Module ${m.number}: ${m.title}'),
                  trailing: Text('${m.completedLessons}/${m.totalLessons}'),
                  onTap: () => context.push(AppRoutes.moduleDetail, extra: m),
                ),
            ],
          ),
        ),
      ),
    );
  }
}