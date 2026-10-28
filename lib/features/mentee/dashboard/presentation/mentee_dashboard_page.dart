import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routing/app_routes.dart';
import '../../learning/domain/curriculum.dart';
import '../../learning/presentation/curriculum_controller.dart';
import '../../../auth/presentation/profile_menu_button.dart';
import '../../../notifications/presentation/notification_bell.dart';
import '../../../mentor/sessions/presentation/mentor_sessions_page.dart';
import '../../../mentor/sessions/presentation/schedule_session_sheet.dart';
import '../../../mentor/sessions/presentation/meeting_launcher.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/presentation/contact_picker.dart';

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          NotificationBell(color: theme.colorScheme.onSurface),

          // Icon 2: Profile menu
          const ProfileMenuButton(),
        ],
      ),
      body: curriculum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load your progress')),
        data: (data) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. WELCOME HERO CARD
            _WelcomeHeroCard(
              name: name.value ?? 'there',
              curriculum: data,
              onViewAllPressed: () => setState(() => _expandAll = !_expandAll),
            ),
            const SizedBox(height: 20),

            // 2. CURRICULUM KEY METRICS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRICULUM KEY METRICS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  data.cohortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetricsGrid(curriculum: data),

            const SizedBox(height: 24),

            // 3. CURRICULUM BREAKDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curriculum Breakdown',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.totalChapters} Chapters • ${data.totalModules} Clinical Modules',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _expandAll = !_expandAll),
                  child: Text(
                    _expandAll ? 'Collapse All' : 'Expand All',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chapter list
            for (var i = 0; i < data.chapters.length; i++)
              _ChapterTile(
                chapter: data.chapters[i],
                chapterIndex: i,
                state: i < data.activeChapterIndex
                    ? _ChapterState.completed
                    : i == data.activeChapterIndex
                        ? _ChapterState.active
                        : (i == data.activeChapterIndex + 1
                            ? _ChapterState.nextUp
                            : _ChapterState.locked),
                expanded: _expandAll,
                activeModuleId: i == data.activeChapterIndex
                    ? data.activeModule?.id
                    : null,
              ),

            const SizedBox(height: 24),

            // 4. CLINICAL SUPPORT & SIMULATION
            Text(
              'CLINICAL SUPPORT & SIMULATION',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            const _MentorPreceptorCard(),
            const SizedBox(height: 12),
            const _PracticalDemoSessionCard(),
            const SizedBox(height: 12),
            const _HandbookResourceCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. WELCOME HERO CARD
// -------------------------------------------------------------
class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard({
    required this.name,
    required this.curriculum,
    required this.onViewAllPressed,
  });

  final String name;
  final CurriculumProgress curriculum;
  final VoidCallback onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    final activeChapter = curriculum.activeChapter;
    final activeModule = curriculum.activeModule;
    final activeLesson = curriculum.nextLesson;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B431E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row tag and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 7, color: Color(0xFFFACC15)),
                    const SizedBox(width: 6),
                    Text(
                      'Active Clinical Pathway • Chapter ${activeChapter?.number ?? 2} of ${curriculum.totalChapters}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.medical_services_outlined,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Greeting & Active Chapter title
          Text(
            '${curriculum.curriculumPercent > 0 ? "Welcome back" : "Welcome"}, $name!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          if (activeChapter != null)
            Text(
              'Chapter ${activeChapter.number}: ${activeChapter.title}',
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
              ),
            ),
          const SizedBox(height: 16),

          // Inner Next Up card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activeModule != null
                          ? 'NEXT UP IN MODULE ${activeModule.number}'
                          : 'NEXT UP',
                      style: const TextStyle(
                        color: Color(0xFFFACC15),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activeLesson != null
                            ? '${activeLesson.progressPercent.toStringAsFixed(0)}%'
                            : '0%',
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activeLesson?.title ?? 'No active lesson',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: activeLesson != null
                        ? (activeLesson.progressPercent / 100).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFFACC15)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Est. ~${activeLesson?.durationMinutes ?? 25} mins left',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.headphones_outlined,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text(
                      'Audio + Video Demo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom buttons row
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: const Color(0xFF1F2937),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.menteeLearn),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_arrow,
                          size: 18, color: Color(0xFF1F2937)),
                      SizedBox(width: 6),
                      Text(
                        'Resume Lesson',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onViewAllPressed,
                  child: Text(
                    'View All ${curriculum.totalChapters} Chapters',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. METRICS GRID (2x2)
// -------------------------------------------------------------
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.curriculum});
  final CurriculumProgress curriculum;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Curriculum',
                topIcon: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: (curriculum.curriculumPercent / 100).clamp(0.0, 1.0),
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
                value: '${curriculum.curriculumPercent.toStringAsFixed(0)}%',
                valueColor: AppColors.primary,
                trailing: SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    value: (curriculum.curriculumPercent / 100).clamp(0.0, 1.0),
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
                subtitle:
                    '${curriculum.completedLessons} of ${curriculum.totalLessons} Finished',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Chapters',
                topIcon: const Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: Color(0xFFA16207),
                ),
                value: '${curriculum.completedChapters} / ${curriculum.totalChapters}',
                subtitle:
                    '${curriculum.completedChapters} Done • 1 Active • ${(curriculum.totalChapters - curriculum.completedChapters - 1).clamp(0, 10)} Next',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Modules Completed',
                topIcon: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Color(0xFF16A34A),
                ),
                value: '${curriculum.completedModules} / ${curriculum.totalModules}',
                subtitle:
                    '${(curriculum.completedModules / (curriculum.totalModules > 0 ? curriculum.totalModules : 1) * 100).toStringAsFixed(0)}% clearance',
                subtitleColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'CPD Accrued',
                topIcon: const Icon(
                  Icons.workspace_premium_outlined,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                value: curriculum.cpdHoursAccrued.toStringAsFixed(1),
                valueExtra: ' / ${curriculum.cpdHoursRequired.toStringAsFixed(0)} hrs',
                subtitle:
                    '${(curriculum.cpdHoursRequired - curriculum.cpdHoursAccrued).clamp(0, 100).toStringAsFixed(1)}h to recertify',
                subtitleColor: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    this.topIcon,
    required this.value,
    this.valueColor,
    this.valueExtra,
    this.trailing,
    required this.subtitle,
    this.subtitleColor,
  });

  final String label;
  final Widget? topIcon;
  final String value;
  final Color? valueColor;
  final String? valueExtra;
  final Widget? trailing;
  final String subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
                  ),
                ),
              ),
              if (topIcon != null) ...[
                const SizedBox(width: 8),
                topIcon!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? (isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937)),
                    ),
                  ),
                  if (valueExtra != null) ...[
                    Text(
                      valueExtra!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor ?? (isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. CHAPTER TILE & BREAKDOWN
// -------------------------------------------------------------
enum _ChapterState { completed, active, nextUp, locked }

class _ChapterTile extends StatefulWidget {
  const _ChapterTile({
    required this.chapter,
    required this.chapterIndex,
    required this.state,
    required this.expanded,
    this.activeModuleId,
  });

  final Chapter chapter;
  final int chapterIndex;
  final _ChapterState state;
  final bool expanded;
  final String? activeModuleId;

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
  bool _localExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = widget.expanded ||
        _localExpanded ||
        widget.state == _ChapterState.active;

    // ACTIVE CHAPTER (Chapter 2)
    if (widget.state == _ChapterState.active) {
      final totalL = widget.chapter.modules.fold<int>(0, (sum, m) => sum + m.totalLessons);
      final completedL = widget.chapter.modules.fold<int>(0, (sum, m) => sum + m.completedLessons);
      final activePct = totalL == 0 ? 0 : (completedL / totalL * 100).round();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            // Dark green active chapter header
            InkWell(
              onTap: () => setState(() => _localExpanded = !_localExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: isExpanded ? Radius.zero : const Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(15),
                    bottom: isExpanded ? Radius.zero : const Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAB308),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.chapter.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT ACTIVE CHAPTER',
                            style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6333),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$activePct% Active',
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded body with active module & subsequent modules
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final m in widget.chapter.modules)
                      if (m.id == widget.activeModuleId || widget.expanded && m == widget.chapter.modules.first)
                        _ActiveModuleBlock(module: m)
                      else ...[
                        const SizedBox(height: 8),
                        _ModuleSummaryTile(module: m),
                      ],
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // COMPLETED CHAPTER (Chapter 1)
    if (widget.state == _ChapterState.completed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _localExpanded = !_localExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF166534),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHAPTER ${widget.chapter.number} • COMPLETED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '100%',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6)),
                    const SizedBox(height: 8),
                    for (final m in widget.chapter.modules)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Module ${m.number}: ${m.title}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          trailing: Text(
                            '${m.completedLessons}/${m.totalLessons} (${m.percent.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () =>
                              context.push(AppRoutes.moduleDetail, extra: m),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // NEXT UP CHAPTER (Chapter 3)
    if (widget.state == _ChapterState.nextUp) {
      final totalL = widget.chapter.modules.fold<int>(0, (sum, m) => sum + m.totalLessons);
      final completedL = widget.chapter.modules.fold<int>(0, (sum, m) => sum + m.completedLessons);
      final readyPct = totalL == 0 ? 0 : (completedL / totalL * 100).round();
      final tagText = readyPct > 0 ? 'NEXT UP • $readyPct% READY' : 'NEXT UP';
      final modulesLabel = widget.chapter.modules.isEmpty
          ? ''
          : (widget.chapter.modules.length == 1
              ? 'Module ${widget.chapter.modules.first.number}'
              : 'Modules ${widget.chapter.modules.first.number}-${widget.chapter.modules.last.number}');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.chapter.number}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tagText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.pageIndicator : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (modulesLabel.isNotEmpty) ...[
                  Text(
                    modulesLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // LOCKED CHAPTER (Chapter 4)
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.chapter.number}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_outline,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

// Compact module summary card inside chapter 2
class _ModuleSummaryTile extends StatelessWidget {
  const _ModuleSummaryTile({required this.module});
  final CurriculumModule module;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => context.push(AppRoutes.moduleDetail, extra: module),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module ${module.number}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  '${module.completedLessons}/${module.totalLessons} (${module.percent.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// ACTIVE MODULE BLOCK (Module 4)
// -------------------------------------------------------------
class _ActiveModuleBlock extends StatelessWidget {
  const _ActiveModuleBlock({required this.module});
  final CurriculumModule module;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFF7F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'MODULE ${module.number} • IN PROGRESS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFBBF7D0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${module.completedLessons} of ${module.totalLessons} Done',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF166534),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            module.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < module.lessons.length; i++)
            _LessonCard(
              index: i + 1,
              lesson: module.lessons[i],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Continue Module ${module.number}',
              trailingIcon: const Icon(
                Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: () {
                final next = module.nextLesson;
                if (next != null) {
                  context.push(AppRoutes.lessonReader, extra: next);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.index, required this.lesson});
  final int index;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (lesson.status == LessonStatus.inProgress) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.timelapse,
              size: 20,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson $index: ${lesson.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'In Progress (${lesson.progressPercent.toStringAsFixed(0)}% Complete)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.pageIndicator : const Color(0xFFB45309),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push(AppRoutes.lessonReader, extra: lesson),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isCompleted = lesson.status == LessonStatus.completed;
    final isQuiz = lesson.title.toLowerCase().contains('quiz');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 20,
            color: isCompleted
                ? const Color(0xFF16A34A)
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lesson $index: ${lesson.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isQuiz ? 'Req. 80%' : '${lesson.durationMinutes}m',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. CLINICAL SUPPORT & SIMULATION CARDS
// -------------------------------------------------------------
class _MentorPreceptorCard extends ConsumerWidget {
  const _MentorPreceptorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mentors = ref.watch(mentorContactsProvider);
    final mentor = mentors.isNotEmpty ? mentors.first : null;
    final mentorName = mentor?.fullName ?? 'Assigned Mentor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  mentorName.isNotEmpty ? mentorName[0].toUpperCase() : 'M',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mentorName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mentor != null
                          ? (mentor.role.isNotEmpty ? mentor.role : 'Mentor')
                          : 'No mentor assigned yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    if (mentor != null) {
                      openChatWith(context, ref, mentor);
                    } else {
                      context.go(AppRoutes.menteeMessages);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 16, color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937)),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    await ScheduleSessionSheet.show(
                      context,
                      menteeName: mentor?.fullName,
                    );
                    ref.invalidate(menteeSessionsProvider);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Schedule 1-on-1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticalDemoSessionCard extends ConsumerWidget {
  const _PracticalDemoSessionCard();

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(menteeSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return sessionsAsync.when(
      loading: () => Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          ),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_note,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No upcoming supervision sessions. Book one with your mentor above!',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final session = sessions.first;
        final dt = session.scheduledStartTime;
        final monthStr = _months[dt.month - 1];
        final dayStr = dt.day.toString();
        final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        final timeStr = '$hour:$minute $period (${session.durationMinutes}m)';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        Text(
                          dayStr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.pageIndicator : const Color(0xFF166534),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.sessionGoals != null && session.sessionGoals!.isNotEmpty
                              ? session.sessionGoals!
                              : (session.mentorName != null
                                  ? 'Mentoring with ${session.mentorName}'
                                  : 'Clinical Supervision Session'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (session.isVirtual)
                    InkWell(
                      onTap: () {
                        launchJitsiMeeting(
                          context: context,
                          ref: ref,
                          sessionId: session.id,
                          sessionTitle: session.sessionGoals ?? 'Mentorship Session',
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam_outlined,
                            size: 16,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Join Virtual Room',
                            style: TextStyle(
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.location ?? 'In-Person Facility',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.isVirtual ? 'Virtual Jitsi' : 'Confirmed',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryLight : const Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HandbookResourceCard extends StatelessWidget {
  const _HandbookResourceCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              color: isDark ? AppColors.pageIndicator : const Color(0xFF1D4ED8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Learning Resources',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse guidelines, protocols, and reference materials',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.go(AppRoutes.menteeResources),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 11,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
