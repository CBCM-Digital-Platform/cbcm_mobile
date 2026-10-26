import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz_models.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key, this.moduleId = 'sample'});
  final String moduleId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  QuizSpec? _quiz;
  String? _error;
  int _index = 0;
  final _answers = <String, String>{};
  QuizAttemptResult? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _msg(Object e) =>
      e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

  Future<void> _load() async {
    setState(() {
      _error = null;
      _quiz = null;
      _result = null;
      _index = 0;
      _answers.clear();
    });
    try {
      final q = await ref.read(quizRepositoryProvider).quizForModule(widget.moduleId);
      if (mounted) setState(() => _quiz = q);
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final r = await ref
          .read(quizRepositoryProvider)
          .submit(_quiz!, Map.of(_answers));
      if (mounted) setState(() {
        _result = r;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;

    Widget body;
    if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    } else if (quiz == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_result != null) {
      body = _resultView(quiz, _result!);
    } else {
      body = _questionView(quiz);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(quiz?.title ?? 'Quiz'),
      ),
      body: body,
    );
  }

  Widget _questionView(QuizSpec quiz) {
    final q = quiz.questions[_index];
    final last = _index == quiz.questions.length - 1;
    final answered = _answers[q.id] != null;

    final next = AppButton(
      label: last ? (_submitting ? 'Submitting...' : 'Submit') : 'Next',
      onPressed: !answered || _submitting
          ? null
          : (last ? _submit : () => setState(() => _index++)),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Question ${_index + 1} of ${quiz.questions.length}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (_index + 1) / quiz.questions.length,
          color: AppColors.primary,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 20),
        Text(q.prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final e in q.options.entries)
          Card(
            child: ListTile(
              leading: Icon(
                _answers[q.id] == e.key
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.primary,
              ),
              title: Text('${e.key}. ${e.value}'),
              onTap: () => setState(() => _answers[q.id] = e.key),
            ),
          ),
        const SizedBox(height: 20),
        if (_index == 0)
          SizedBox(width: double.infinity, child: next)
        else
          AppButtonRow(
            secondary: AppButton(
              label: 'Back',
              variant: AppButtonVariant.secondary,
              onPressed: () => setState(() => _index--),
            ),
            primary: next,
          ),
      ],
    );
  }

  Widget _resultView(QuizSpec quiz, QuizAttemptResult r) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          r.passed ? Icons.check_circle : Icons.cancel,
          size: 72,
          color: r.passed ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('${r.score}%',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Text(
            r.passed ? 'Passed' : 'Not passed (pass mark ${quiz.passScore}%)',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text('${r.correct} of ${r.total} correct')),
        const SizedBox(height: 28),
        AppButtonRow(
          secondary: AppButton(
            label: 'Try again',
            variant: AppButtonVariant.secondary,
            onPressed: _load,
          ),
          primary: AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}