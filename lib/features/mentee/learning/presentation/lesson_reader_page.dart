import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/read_aloud_controller.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/read_aloud_bar.dart';
import '../domain/curriculum.dart';
import 'curriculum_controller.dart';

class LessonReaderPage extends ConsumerStatefulWidget {
  const LessonReaderPage({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<LessonReaderPage> createState() => _LessonReaderPageState();
}

class _LessonReaderPageState extends ConsumerState<LessonReaderPage> {
  late final ReadAloudController _reader;

  @override
  void initState() {
    super.initState();
    _reader = ReadAloudController(
      loadText: () async => widget.lesson.content,
      storage: ref.read(secureStorageProvider),
      resourceKey: 'lesson:${widget.lesson.id}',
    );
  }

  @override
  void dispose() {
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final completed = lesson.status == LessonStatus.completed;

    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule,
                              size: 16, color: mutedColor),
                          const SizedBox(width: 4),
                          Text('${lesson.durationMinutes} min',
                              style: TextStyle(color: mutedColor)),
                        ],
                      ),
                      if (lesson.isAudio)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.headphones,
                                size: 16, color: mutedColor),
                            const SizedBox(width: 4),
                            Text('Audio available',
                                style: TextStyle(color: mutedColor)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lesson.content.isEmpty
                        ? 'Content for this lesson is not available yet.'
                        : lesson.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          ReadAloudBar(reader: _reader, safeBottom: false),
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: completed ? 'Completed' : 'Mark as Complete',
                    onPressed: completed
                        ? null
                        : () {
                            ref
                                .read(curriculumControllerProvider.notifier)
                                .completeLesson(lesson.id);
                            Navigator.of(context).pop();
                          },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}