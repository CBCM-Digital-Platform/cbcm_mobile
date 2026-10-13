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

final _userNameProvider = FutureProvider.autoDispose((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return (await storage.read(StorageKeys.userName)) ?? 'Sarah';
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
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          // Icon 1: Notifications
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1F2937),
            ),
            onPressed: () {
              // TODO: Open notifications
            },
          ),

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
              name: name.value ?? 'Sarah',
              curriculum: data,
              onViewAllPressed: () => setState(() => _expandAll = !_expandAll),
            ),
            const SizedBox(height: 20),

            // 2. CURRICULUM KEY METRICS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CURRICULUM KEY METRICS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF6B7280),
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
                    const Text(
                      'Curriculum Breakdown',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.totalChapters} Chapters • ${data.totalModules} Clinical Modules',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
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
            const Text(
              'CLINICAL SUPPORT & SIMULATION',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Color(0xFF6B7280),
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
            'Welcome back, $name!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chapter ${activeChapter?.number ?? 2}: ${activeChapter?.title ?? 'Intrapartum Care & Clinical Obstetric Skills'}',
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
                      'NEXT UP IN MODULE ${activeModule?.number ?? 4}',
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
                        activeLesson != null &&
                                activeLesson.status == LessonStatus.inProgress
                            ? '${activeLesson.progressPercent.toStringAsFixed(0)}%'
                            : '75%',
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
                  activeLesson?.title ??
                      'Lesson 2: Fundal Height & Palpation Assessment',
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
                    value: activeLesson != null &&
                            activeLesson.status == LessonStatus.inProgress
                        ? (activeLesson.progressPercent / 100).clamp(0.0, 1.0)
                        : 0.75,
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
                  onPressed: () {
                    final next = curriculum.nextLesson;
                    if (next != null) {
                      context.push(AppRoutes.lessonReader, extra: next);
                    }
                  },
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
                topIcon: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: 0.71,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    backgroundColor: Color(0xFFE5E7EB),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              ?topIcon,
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
                      color: valueColor ?? const Color(0xFF1F2937),
                    ),
                  ),
                  if (valueExtra != null) ...[
                    Text(
                      valueExtra!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
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
              color: subtitleColor ?? const Color(0xFF6B7280),
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
    final isExpanded = widget.expanded ||
        _localExpanded ||
        widget.state == _ChapterState.active;

    // ACTIVE CHAPTER (Chapter 2)
    if (widget.state == _ChapterState.active) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      child: const Text(
                        '75% Active',
                        style: TextStyle(
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
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
                      color: const Color(0xFF9CA3AF),
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
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 8),
                    for (final m in widget.chapter.modules)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Module ${m.number}: ${m.title}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        trailing: Text(
                          '${m.completedLessons}/${m.totalLessons} (${m.percent.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12),
                        ),
                        onTap: () =>
                            context.push(AppRoutes.moduleDetail, extra: m),
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
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.chapter.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF6B7280),
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
                    'NEXT UP • 15% READY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: const [
                Text(
                  'Modules 7-9',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.chapter.number}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
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
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
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
    return InkWell(
      onTap: () => context.push(AppRoutes.moduleDetail, extra: module),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module ${module.number}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xFF9CA3AF),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFFBBF7D0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${module.completedLessons} of ${module.totalLessons} Done',
                  style: const TextStyle(
                    color: Color(0xFF166534),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
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
    if (lesson.status == LessonStatus.inProgress) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'In Progress (${lesson.progressPercent.toStringAsFixed(0)}% Complete)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB45309),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lesson $index: ${lesson.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isQuiz ? 'Req. 80%' : '${lesson.durationMinutes}m',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
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
class _MentorPreceptorCard extends StatelessWidget {
  const _MentorPreceptorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage:
                    AssetImage('assets/images/mentee_N_mentro_photo.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Dr. Sarah Jenkins, CNM',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Lead Midwifery Preceptor • St. Jude Maternity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
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
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => context.go(AppRoutes.menteeMessages),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline,
                          size: 16, color: Color(0xFF1F2937)),
                      SizedBox(width: 8),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('1-on-1 scheduling feature coming soon!'),
                      ),
                    );
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

class _PracticalDemoSessionCard extends StatelessWidget {
  const _PracticalDemoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'OCT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      '12',
                      style: TextStyle(
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
                  children: const [
                    Text(
                      'PRACTICAL DEMO SESSION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Simulation Lab B • Bedside Fundal Assessment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thu, 14:00 - 15:30 (Mandatory CPD clearance)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
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
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Lab Checklist...')),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'View Lab Checklist',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Seat Confirmed',
                  style: TextStyle(
                    color: Color(0xFF166534),
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
  }
}

class _HandbookResourceCard extends StatelessWidget {
  const _HandbookResourceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.picture_as_pdf,
                color: Color(0xFFE11D48),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Fundal Palpation Clinical Handbook',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ACOG & WHO Standards (v4.2 • 4.8MB)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading Clinical Handbook...')),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_downward,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}