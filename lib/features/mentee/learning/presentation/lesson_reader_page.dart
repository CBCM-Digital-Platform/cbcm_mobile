import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/curriculum.dart';
import 'curriculum_controller.dart';

class LessonReaderPage extends ConsumerStatefulWidget {
  const LessonReaderPage({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<LessonReaderPage> createState() => _LessonReaderPageState();
}

class _LessonReaderPageState extends ConsumerState<LessonReaderPage> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(widget.lesson.content.isEmpty
          ? widget.lesson.title
          : widget.lesson.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

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
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${lesson.durationMinutes} min',
                          style: TextStyle(color: Colors.grey.shade600)),
                      if (lesson.isAudio) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.headphones, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Audio available', style: TextStyle(color: Colors.grey.shade600)),
                      ],
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
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton.filled(
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(56, 56),
                  ),
                  icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                  onPressed: lesson.content.isEmpty ? null : _toggleSpeech,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: lesson.status == LessonStatus.completed
                        ? 'Completed'
                        : 'Mark as Complete',
                    onPressed: lesson.status == LessonStatus.completed
                        ? null
                        : () {
                            ref
                                .read(curriculumControllerProvider.notifier)
                                .completeLesson(lesson.id);
                            Navigator.of(context).pop();
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}