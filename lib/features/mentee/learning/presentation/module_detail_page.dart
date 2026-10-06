import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/curriculum.dart';

class ModuleDetailPage extends StatelessWidget {
  const ModuleDetailPage({super.key, required this.module, this.nextModules = const []});

  final CurriculumModule module;
  final List<CurriculumModule> nextModules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Module ${module.number}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(module.title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Chip(
                label: Text('${module.completedLessons} of ${module.totalLessons} Done'),
                backgroundColor: AppColors.pageIndicator.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final lesson in module.lessons) _LessonTile(lesson: lesson),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Continue Module ${module.number} →',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson player coming later this week')),
                );
              },
            ),
          ),
          if (nextModules.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Up next', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final m in nextModules)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Module ${m.number}: ${m.title}'),
                  trailing: Text('${m.completedLessons}/${m.totalLessons} '
                      '(${m.percent.toStringAsFixed(0)}%)'),
                  onTap: () => context.push(
                    '/mentee/module-detail',
                    extra: m,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
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
      leading: Icon(icon, color: color),
      title: Text(lesson.title),
      subtitle: Text(subtitle),
    );
  }
}