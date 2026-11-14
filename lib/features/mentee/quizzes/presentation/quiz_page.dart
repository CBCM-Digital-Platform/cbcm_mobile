import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../learning/presentation/curriculum_controller.dart';
import '../data/quiz_providers.dart';
import '../domain/quiz_models.dart';
import 'quiz_result_detail_sheet.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({
    super.key,
    this.quizId,
    this.moduleId,
  });

  final int? quizId;
  final int? moduleId;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  bool _isTakingQuiz = false;
  int _questionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionId -> selectedOptionId
  bool _submitting = false;
  String? _submitError;
  QuizResultItem? _latestResult;

  String _msg(Object e) =>
      e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
  }

  Future<void> _startQuiz(QuizDetail quiz) async {
    setState(() {
      _isTakingQuiz = true;
      _questionIndex = 0;
      _selectedAnswers.clear();
      _submitError = null;
      _latestResult = null;
    });

    try {
      await ref.read(quizRepositoryProvider).startAttempt(quiz.id);
    } catch (_) {
      // Don't block attempt if start attempt log fails
    }
  }

  Future<void> _submitQuiz(QuizDetail quiz) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final answersPayload = <Map<String, dynamic>>[];
    for (final q in quiz.questions) {
      final selectedOptId = _selectedAnswers[q.id];
      if (selectedOptId != null) {
        answersPayload.add({
          'questionId': q.id,
          'selectedOptionId': selectedOptId,
        });
      }
    }

    try {
      final result = await ref
          .read(quizRepositoryProvider)
          .submitQuiz(quiz.id, answersPayload);

      // Refresh attempts and results after successful submission
      ref.invalidate(quizAttemptsProvider(quiz.id));
      ref.invalidate(quizResultsProvider(quiz.id));

      if (mounted) {
        setState(() {
          _submitting = false;
          _isTakingQuiz = false;
          _latestResult = result;
        });

        // Open result sheet
        QuizResultDetailSheet.show(
          context,
          result: result,
          passScore: quiz.passScore,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = _msg(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve quiz: by quizId if provided, else by moduleId, else from active curriculum
    final resolvedQuizId = widget.quizId;
    final resolvedModuleId = widget.moduleId ??
        int.tryParse(ref.watch(curriculumControllerProvider).value?.activeModule?.id ?? '') ??
        1;

    final AsyncValue<QuizDetail> quizAsync = resolvedQuizId != null
        ? ref.watch(quizDetailProvider(resolvedQuizId))
        : ref.watch(moduleQuizProvider(resolvedModuleId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isTakingQuiz ? 'Knowledge Check' : 'Clinical Quiz',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: _isTakingQuiz
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Exit Quiz',
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Exit Quiz?'),
                      content: const Text(
                        'Your current progress on this attempt will not be submitted.',
                      ),
                      actions: [
                        AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        AppButton(
                          label: 'Exit',
                          variant: AppButtonVariant.danger,
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  ).then((confirmed) {
                    if (confirmed == true && mounted) {
                      setState(() => _isTakingQuiz = false);
                    }
                  });
                },
              )
            : null,
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                const SizedBox(height: 12),
                Text(_msg(e), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Try Again',
                  onPressed: () {
                    if (resolvedQuizId != null) {
                      ref.invalidate(quizDetailProvider(resolvedQuizId));
                    } else {
                      ref.invalidate(moduleQuizProvider(resolvedModuleId));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        data: (quiz) {
          if (_isTakingQuiz) {
            return _buildActiveQuiz(quiz, isDark);
          }
          return _buildEntryScreen(quiz, isDark);
        },
      ),
    );
  }

  // -----------------------------------------------------------
  // 1. QUIZ ENTRY & HISTORY SCREEN
  // -----------------------------------------------------------
  Widget _buildEntryScreen(QuizDetail quiz, bool isDark) {
    final attemptsAsync = ref.watch(quizAttemptsProvider(quiz.id));
    final resultsAsync = ref.watch(quizResultsProvider(quiz.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(quizAttemptsProvider(quiz.id));
        ref.invalidate(quizResultsProvider(quiz.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quiz Title & Description Header Card
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              quiz.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Metrics Row (Passing Score, Time Limit, Questions Count)
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.check_circle_outline,
                      label: 'Pass: ${quiz.passScore.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(width: 10),
                    if (quiz.timeLimitMinutes != null && quiz.timeLimitMinutes! > 0) ...[
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: '${quiz.timeLimitMinutes} min',
                      ),
                      const SizedBox(width: 10),
                    ],
                    _InfoChip(
                      icon: Icons.format_list_numbered,
                      label: '${quiz.questions.length} questions',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Attempts Status & Limits
          attemptsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => AppCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Could not load attempts history: ${_msg(e)}',
                style: const TextStyle(color: AppColors.destructive, fontSize: 13),
              ),
            ),
            data: (attempts) {
              final attemptLimit = quiz.attemptLimit;
              final hasLimit = quiz.hasAttemptLimit;
              final attemptsLeft = hasLimit
                  ? (attemptLimit! - attempts.length).clamp(0, attemptLimit)
                  : null;
              final noAttemptsLeft = hasLimit && (attemptsLeft ?? 0) <= 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attempt Limit Banner
                  if (hasLimit)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: noAttemptsLeft
                            ? AppColors.destructive.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: noAttemptsLeft
                              ? AppColors.destructive.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            noAttemptsLeft
                                ? Icons.lock_outline
                                : Icons.info_outline,
                            size: 20,
                            color: noAttemptsLeft
                                ? AppColors.destructive
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              noAttemptsLeft
                                  ? 'Attempt limit reached ($attemptLimit/$attemptLimit). No attempts left.'
                                  : 'Attempt Limit: $attemptLimit • Attempts left: $attemptsLeft',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: noAttemptsLeft
                                    ? AppColors.destructive
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Start Quiz Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: quiz.questions.isEmpty
                          ? 'No Questions Available'
                          : (noAttemptsLeft ? 'No Attempts Left' : 'Start Quiz'),
                      icon: const Icon(Icons.play_arrow),
                      onPressed: (quiz.questions.isEmpty || noAttemptsLeft)
                          ? null
                          : () => _startQuiz(quiz),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Past Attempts Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Past Attempts (${attempts.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (attempts.isNotEmpty)
                        Text(
                          'Tap to view results',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Empty State or Attempts List
                  if (attempts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_outlined,
                            size: 48,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attempts yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take your first quiz attempt above to test your knowledge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final attempt in attempts) ...[
                      _AttemptTile(
                        attempt: attempt,
                        passScore: quiz.passScore,
                        onTap: () {
                          // Find matching result or fallback to attempt item
                          final results = resultsAsync.value ?? [];
                          final matchedResult = results.firstWhere(
                            (r) =>
                                r.id == attempt.id ||
                                r.attemptNumber == attempt.attemptNumber,
                            orElse: () => QuizResultItem(
                              id: attempt.id,
                              quizId: attempt.quizId,
                              menteeId: attempt.menteeId,
                              attemptNumber: attempt.attemptNumber,
                              score: attempt.score,
                              passed: attempt.passed,
                              status: attempt.status,
                              startedAt: attempt.startedAt,
                              completedAt: attempt.completedAt,
                            ),
                          );

                          QuizResultDetailSheet.show(
                            context,
                            result: matchedResult,
                            passScore: quiz.passScore,
                          );
                        },
                        formatDate: _formatDate,
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // 2. ACTIVE QUIZ TAKING VIEW
  // -----------------------------------------------------------
  Widget _buildActiveQuiz(QuizDetail quiz, bool isDark) {
    if (quiz.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No questions available in this quiz.'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Go Back',
              onPressed: () => setState(() => _isTakingQuiz = false),
            ),
          ],
        ),
      );
    }

    final question = quiz.questions[_questionIndex];
    final isLast = _questionIndex == quiz.questions.length - 1;
    final selectedOptionId = _selectedAnswers[question.id];
    final hasAnswered = selectedOptionId != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_submitError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.destructive.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.destructive, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submitError!,
                    style: const TextStyle(color: AppColors.destructive, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Progress bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_questionIndex + 1} of ${quiz.questions.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            Text(
              '${((_questionIndex + 1) / quiz.questions.length * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_questionIndex + 1) / quiz.questions.length,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 20),

        // Question Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (question.clinicalContext != null &&
                  question.clinicalContext!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    question.clinicalContext!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                question.prompt,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Options List
        for (final opt in question.options) ...[
          _OptionCard(
            option: opt,
            isSelected: selectedOptionId == opt.id,
            onTap: () {
              setState(() {
                _selectedAnswers[question.id] = opt.id;
              });
            },
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 24),

        // Navigation Buttons (Back on left, Next/Submit on right)
        AppButtonRow(
          secondary: AppButton(
            label: 'Previous',
            variant: AppButtonVariant.secondary,
            onPressed: _questionIndex > 0 && !_submitting
                ? () => setState(() => _questionIndex--)
                : null,
          ),
          primary: AppButton(
            label: isLast ? (_submitting ? 'Submitting...' : 'Submit Quiz') : 'Next',
            onPressed: !hasAnswered || _submitting
                ? null
                : (isLast
                    ? () => _submitQuiz(quiz)
                    : () => setState(() => _questionIndex++)),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({
    required this.attempt,
    required this.passScore,
    required this.onTap,
    required this.formatDate,
  });

  final QuizAttemptItem attempt;
  final double passScore;
  final VoidCallback onTap;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPassed = attempt.passed;
    final dateStr = formatDate(attempt.completedAt ?? attempt.startedAt);

    return Material(
      color: isDark ? AppColors.darkSurface : theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPassed
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.destructive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.check : Icons.close,
                  color: isPassed ? AppColors.primary : AppColors.destructive,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attempt #${attempt.attemptNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${attempt.score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? AppColors.primary : AppColors.destructive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPassed ? 'Passed' : 'Failed',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? AppColors.primary : AppColors.destructive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final QuizOptionModel option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : (isDark ? AppColors.darkSurface : theme.cardColor),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
