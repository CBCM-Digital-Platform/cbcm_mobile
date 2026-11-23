import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/security/offline_access.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../routing/app_router.dart';
import '../../assessments/assessments_page.dart';
import '../../assessments/assessments_repository.dart';
import '../../assessments/presentation/assessment_detail_page.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/current_role_provider.dart';
import '../../certificates/presentation/certificate_eligibility_sheet.dart';
import '../../certificates/presentation/certificates_page.dart';
import '../../logbook/presentation/mentee_logbook_detail_page.dart';
import '../../logbook/presentation/mentee_logbook_page.dart';
import '../../logbook/presentation/mentor_logbook_detail_page.dart';
import '../../logbook/presentation/mentor_logbook_review_page.dart';
import '../../mentee/dashboard/presentation/mentee_dashboard_page.dart';
import '../../mentee/learning/data/curriculum_repository_provider.dart';
import '../../mentee/learning/domain/curriculum.dart';
import '../../mentee/learning/presentation/learn_page.dart';
import '../../mentee/learning/presentation/module_detail_page.dart';
import '../../mentee/mentorship/presentation/my_mentor_page.dart';
import '../../mentee/quizzes/presentation/quiz_page.dart';
import '../../mentee/resources/data/resource_providers.dart';
import '../../mentee/resources/domain/learning_resource.dart';
import '../../mentee/resources/presentation/protected_pdf_page.dart';
import '../../mentee/resources/presentation/resources_page.dart';
import '../../mentor/dashboard/presentation/mentor_dashboard_page.dart';
import '../../mentor/mentees/data/assigned_mentees_provider.dart';
import '../../mentor/mentees/presentation/learning_access_page.dart';
import '../../mentor/mentees/presentation/mentee_picker_sheet.dart';
import '../../mentor/sessions/data/sessions_repository_provider.dart';
import '../../mentor/sessions/domain/session_model.dart';
import '../../mentor/sessions/presentation/mentor_sessions_page.dart';
import '../../mentor/sessions/presentation/session_detail_page.dart';
import '../../messaging/presentation/message_time.dart';
import '../../messaging/data/messaging_providers.dart';
import '../../messaging/data/temporary_contacts.dart';
import '../../messaging/domain/message_models.dart';
import '../../messaging/presentation/chat_page.dart';
import '../../messaging/presentation/contact_picker.dart';
import '../../messaging/presentation/conversations_page.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

String _errorText(Object e) =>
    e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final Set<int> _readOrDismissedIds = {};
  int _selectedTab = 0; // 0 = Unread, 1 = All

  void _refreshAll() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  void _markItemReadLocally(int id) {
    setState(() {
      _readOrDismissedIds.add(id);
    });
  }

  Widget _tabButton(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
            onPressed: () async {
              try {
                final currentItems = async.value ?? [];
                setState(() {
                  _readOrDismissedIds.addAll(currentItems.map((e) => e.id));
                });
                await ref.read(notificationsRepositoryProvider).markAllRead();
                _refreshAll();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(_errorText(e))));
                }
              }
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorText(e), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (allItems) {
          final unreadItems = allItems.where((it) =>
            !it.isRead && !_readOrDismissedIds.contains(it.id)
          ).toList();

          final displayedItems = _selectedTab == 0
              ? unreadItems
              : allItems;

          return Column(
            children: [
              // Segmented Tab Filter: Unread | All
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton('Unread (${unreadItems.length})', 0, isDark),
                    ),
                    Expanded(
                      child: _tabButton('All (${allItems.length})', 1, isDark),
                    ),
                  ],
                ),
              ),

              // Notification List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                    await ref.read(notificationsProvider.future);
                  },
                  child: displayedItems.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        color: AppColors.primary,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _selectedTab == 0
                                          ? 'All caught up!'
                                          : 'No notifications yet.',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedTab == 0
                                          ? 'You have read all pending notifications.'
                                          : 'You do not have any notifications recorded.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (_selectedTab == 0 && allItems.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () => setState(() => _selectedTab = 1),
                                        child: const Text('View All Notifications'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _NotificationTile(
                            item: displayedItems[i],
                            isLocallyRead: _readOrDismissedIds.contains(displayedItems[i].id),
                            onTapProcessed: () => _markItemReadLocally(displayedItems[i].id),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({
    required this.item,
    this.isLocallyRead = false,
    this.onTapProcessed,
  });

  final AppNotification item;
  final bool isLocallyRead;
  final VoidCallback? onTapProcessed;

  IconData get _icon {
    final t = '${item.type} ${item.referenceType ?? ''} ${item.title} ${item.body}'.toLowerCase();
    if (t.contains('message') || t.contains('chat')) return Icons.chat_bubble_outline;
    if (t.contains('session') || t.contains('meeting') || t.contains('schedule')) return Icons.event_outlined;
    if (t.contains('logbook') || t.contains('procedure')) return Icons.menu_book_outlined;
    if (t.contains('assess') || t.contains('evaluat')) return Icons.assignment_outlined;
    if (t.contains('certif')) return Icons.verified_outlined;
    if (t.contains('resource')) return Icons.folder_shared_outlined;
    if (t.contains('module') || t.contains('learn') || t.contains('quiz')) {
      return Icons.school_outlined;
    }
    return Icons.notifications_none;
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
      }
    }
  }

  int? _extractId(AppNotification item, [List<String>? keywords]) {
    if (item.referenceId != null && item.referenceId! > 0) {
      return item.referenceId;
    }
    final text = '${item.title} ${item.body}';
    if (keywords != null && keywords.isNotEmpty) {
      final kw = keywords.join('|');
      final match = RegExp('(?:$kw)\\s*#?\\s*(\\d+)', caseSensitive: false).firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
    }
    final fallbackMatch = RegExp(r'#(\d+)').firstMatch(text);
    if (fallbackMatch != null) {
      return int.tryParse(fallbackMatch.group(1) ?? '');
    }
    return null;
  }

  Future<AssignedMentee?> _findMentee(WidgetRef ref, AppNotification item) async {
    try {
      List<AssignedMentee> mentees = ref.read(assignedMenteesProvider).value ?? [];
      if (mentees.isEmpty) {
        try {
          mentees = await ref.read(assignedMenteesProvider.future);
        } catch (_) {}
      }
      if (item.referenceId != null && item.referenceId! > 0) {
        final direct = mentees.where((m) => m.id == item.referenceId).firstOrNull;
        if (direct != null) return direct;
      }
      final text = '${item.title} ${item.body}'.toLowerCase();
      for (final m in mentees) {
        if (m.fullName.isNotEmpty && text.contains(m.fullName.toLowerCase())) {
          return m;
        }
      }
    } catch (_) {}
    return null;
  }

  void _showResourceSheet(
    BuildContext context,
    WidgetRef ref,
    LearningResource resource,
    bool isMentor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resource.type == ResourceType.pdf
                          ? Icons.picture_as_pdf_outlined
                          : (resource.type == ResourceType.video
                              ? Icons.videocam_outlined
                              : Icons.folder_outlined),
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
                          resource.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resource.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${resource.fileExtension.toUpperCase()} • ${resource.sizeLabel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (resource.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    resource.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (resource.type == ResourceType.pdf && resource.downloadUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chrome_reader_mode_outlined),
                    label: const Text('Read Document Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.of(sheetCtx).pop();
                      await _readOnlineResource(context, ref, resource);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View in Resource Library'),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    rootNavigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (_) => const ResourcesPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _readOnlineResource(
    BuildContext context,
    WidgetRef ref,
    LearningResource r,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = rootNavigatorKey.currentState;
    final allowed = await ref.read(offlineAccessProvider.notifier).ensureAccess();
    if (!context.mounted) return;
    if (!allowed) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Offline access expired. Please connect to internet.')),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text('Opening "${r.title}"...'),
      duration: const Duration(seconds: 2),
    ));
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<int>>(
        r.downloadUrl!,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      if (nav != null) {
        await nav.push(MaterialPageRoute(
          builder: (_) => ProtectedPdfPage(title: r.title, bytes: bytes, resourceId: r.id),
        ));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not open document. Check your connection.'),
      ));
    }
  }

  Future<void> _openLogbook(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    final entryId = _extractId(item, ['entry', 'logbook', 'procedure']);
    if (isMentor) {
      if (entryId != null && entryId > 0) {
        nav.push(MaterialPageRoute(
          builder: (_) => MentorLogbookDetailPage(entryId: entryId),
        ));
        return;
      }
      final mentee = await _findMentee(ref, item);
      if (mentee != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => MentorLogbookReviewPage(
            menteeId: mentee.id,
            menteeName: mentee.fullName,
          ),
        ));
        return;
      }
      nav.push(MaterialPageRoute(
        builder: (_) => const MentorLogbookReviewPage(),
      ));
    } else {
      if (entryId != null && entryId > 0) {
        nav.push(MaterialPageRoute(
          builder: (_) => MenteeLogbookDetailPage(entryId: entryId),
        ));
        return;
      }
      nav.push(MaterialPageRoute(
        builder: (_) => const MenteeLogbookPage(),
      ));
    }
  }

  Future<void> _openSession(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    final sessionId = _extractId(item, ['session', 'meeting', 'appointment']);
    SessionModel? matchedSession;

    try {
      final repo = ref.read(sessionsRepositoryProvider);
      if (sessionId != null && sessionId > 0) {
        try {
          matchedSession = await repo.getSessionDetails(sessionId);
        } catch (_) {}
      }

      if (matchedSession == null) {
        final storage = ref.read(secureStorageProvider);
        final userIdStr = await storage.read(StorageKeys.userId);
        final userId = int.tryParse(userIdStr ?? '');
        final sessions = await repo.getSessions(
          mentorId: isMentor ? userId : null,
          menteeId: isMentor ? null : userId,
        );

        if (sessionId != null && sessionId > 0) {
          matchedSession = sessions.where((s) => s.id == sessionId).firstOrNull;
        }
        if (matchedSession == null && sessions.isNotEmpty) {
          final text = '${item.title} ${item.body}'.toLowerCase();
          matchedSession = sessions.where((s) {
            final partner = isMentor ? s.menteeName : s.mentorName;
            return partner != null && partner.isNotEmpty && text.contains(partner.toLowerCase());
          }).firstOrNull;
          matchedSession ??= sessions.firstOrNull;
        }
      }
    } catch (_) {}

    if (matchedSession != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => SessionDetailPage(session: matchedSession!),
      ));
      return;
    }

    nav.push(MaterialPageRoute(
      builder: (_) => isMentor ? const MentorSessionsPage() : const MyMentorPage(),
    ));
  }

  Future<void> _openAssessments(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    final repo = ref.read(assessmentsRepositoryProvider);
    final text = '${item.type} ${item.referenceType ?? ''} ${item.title} ${item.body}'.toLowerCase();
    final assessmentId = _extractId(item, ['assessment', 'evaluat', 'competenc']);
    Assessment? targetAssessment;

    // 1. Try to fetch direct assessment by ID
    if (assessmentId != null && assessmentId > 0) {
      try {
        targetAssessment = await repo.getById(assessmentId);
      } catch (_) {}
    }

    // 2. If not found by direct ID, search in assessment list
    if (targetAssessment == null) {
      try {
        final list = await repo.list();
        if (assessmentId != null && assessmentId > 0) {
          targetAssessment = list.where((a) => a.id == assessmentId).firstOrNull;
        }
        if (targetAssessment == null && list.isNotEmpty) {
          targetAssessment = list.where((a) =>
            a.menteeName.isNotEmpty && text.contains(a.menteeName.toLowerCase())
          ).firstOrNull;
          targetAssessment ??= list.where((a) =>
            a.area.isNotEmpty && text.contains(a.area.toLowerCase())
          ).firstOrNull;
          if (text.contains('finaliz') || text.contains('complet') || text.contains('sign')) {
            targetAssessment ??= list.where((a) => a.isFinalized).firstOrNull;
          }
          targetAssessment ??= list.firstOrNull;
        }
      } catch (_) {}
    }

    if (targetAssessment != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => AssessmentDetailPage(assessment: targetAssessment!),
      ));
      return;
    }

    // Fallback: list page
    if (isMentor) {
      final mentee = await _findMentee(ref, item);
      if (mentee != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => AssessmentsPage(
            menteeId: mentee.id,
            menteeName: mentee.fullName,
            facilityId: mentee.facilityId,
            cycleId: mentee.cycleId,
            thematicAreaId: mentee.thematicAreaId,
          ),
        ));
        return;
      }
      final activeCtx = rootNavigatorKey.currentContext;
      if (activeCtx != null && activeCtx.mounted) {
        final picked = await MenteePickerSheet.show(
          activeCtx,
          title: 'Select Mentee for Assessments',
          subtitle: 'View competency assessments and evaluations',
        );
        if (picked != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => AssessmentsPage(
              menteeId: picked.id,
              menteeName: picked.fullName,
              facilityId: picked.facilityId,
              cycleId: picked.cycleId,
              thematicAreaId: picked.thematicAreaId,
            ),
          ));
        }
      }
    } else {
      nav.push(MaterialPageRoute(
        builder: (_) => const AssessmentsPage(),
      ));
    }
  }

  Future<void> _openLearning(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    final text = '${item.type} ${item.referenceType ?? ''} ${item.title} ${item.body}'.toLowerCase();
    if (!isMentor) {
      if (text.contains('quiz')) {
        final quizId = _extractId(item, ['quiz']);
        nav.push(MaterialPageRoute(
          builder: (_) => QuizPage(quizId: quizId),
        ));
        return;
      }
      try {
        final storage = ref.read(secureStorageProvider);
        final menteeId = await storage.read(StorageKeys.userId);
        final progress = await ref.read(curriculumRepositoryProvider).getCurriculumProgress(menteeId ?? 'unknown');
        final allModules = progress.chapters.expand((c) => c.modules).toList();
        final moduleId = _extractId(item, ['module', 'lesson']);
        CurriculumModule? matchedModule;
        if (moduleId != null) {
          matchedModule = allModules.where((m) => m.id == '$moduleId').firstOrNull;
        }
        matchedModule ??= allModules.where((m) => text.contains(m.title.toLowerCase())).firstOrNull;
        if (matchedModule != null) {
          final found = matchedModule;
          nav.push(MaterialPageRoute(
            builder: (_) => ModuleDetailPage(module: found),
          ));
          return;
        }
      } catch (_) {}
      nav.push(MaterialPageRoute(
        builder: (_) => const LearnPage(),
      ));
    } else {
      final mentee = await _findMentee(ref, item);
      if (mentee != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => LearningAccessPage(mentee.id, mentee.fullName),
        ));
        return;
      }
      final activeCtx = rootNavigatorKey.currentContext;
      if (activeCtx != null && activeCtx.mounted) {
        final picked = await MenteePickerSheet.show(
          activeCtx,
          title: 'Select Mentee for Learning Resources',
          subtitle: 'Manage and assign clinical learning modules',
        );
        if (picked != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => LearningAccessPage(picked.id, picked.fullName),
          ));
        }
      }
    }
  }

  Future<void> _openResources(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    final text = '${item.type} ${item.referenceType ?? ''} ${item.title} ${item.body}'.toLowerCase();
    final resourceId = _extractId(item, ['resource', 'guideline', 'protocol', 'doc']);

    LearningResource? targetResource;
    try {
      final allResources = await ref.read(resourceRepositoryProvider).getResources();
      if (resourceId != null && resourceId > 0) {
        targetResource = allResources.where((r) => r.id == '$resourceId').firstOrNull;
      }
      if (targetResource == null && allResources.isNotEmpty) {
        targetResource = allResources.where((r) =>
          r.title.isNotEmpty && text.contains(r.title.toLowerCase())
        ).firstOrNull;
        final quoteMatch = RegExp(r'''['"]([^'"]+)['"]''').firstMatch('${item.title} ${item.body}');
        if (quoteMatch != null) {
          final quoted = quoteMatch.group(1)!.toLowerCase();
          targetResource ??= allResources.where((r) =>
            r.title.toLowerCase().contains(quoted)
          ).firstOrNull;
        }
        targetResource ??= allResources.where((r) =>
          r.category.isNotEmpty && text.contains(r.category.toLowerCase())
        ).firstOrNull;
      }
    } catch (_) {}

    final activeCtx = rootNavigatorKey.currentContext;
    if (targetResource != null && activeCtx != null && activeCtx.mounted) {
      _showResourceSheet(activeCtx, ref, targetResource, isMentor);
      return;
    }

    if (isMentor) {
      final mentee = await _findMentee(ref, item);
      if (mentee != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => LearningAccessPage(mentee.id, mentee.fullName),
        ));
        return;
      }
    }
    nav.push(MaterialPageRoute(
      builder: (_) => const ResourcesPage(),
    ));
  }

  Future<void> _openCertificates(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    if (!isMentor) {
      nav.push(MaterialPageRoute(
        builder: (_) => const CertificatesPage(),
      ));
      return;
    }
    final mentee = await _findMentee(ref, item);
    final activeCtx = rootNavigatorKey.currentContext;
    if (mentee != null && activeCtx != null && activeCtx.mounted) {
      showModalBottomSheet(
        context: activeCtx,
        isScrollControlled: true,
        builder: (_) => CertificateEligibilitySheet(
          menteeId: mentee.id,
          menteeName: mentee.fullName,
          cycleId: mentee.cycleId ?? 1,
          thematicAreaId: mentee.thematicAreaId ?? 1,
        ),
      );
      return;
    }
    if (activeCtx != null && activeCtx.mounted) {
      final picked = await MenteePickerSheet.show(
        activeCtx,
        title: 'Select Mentee for Certificate',
        subtitle: 'View eligibility and issue clinical certificates',
      );
      if (picked != null && activeCtx.mounted) {
        showModalBottomSheet(
          context: activeCtx,
          isScrollControlled: true,
          builder: (_) => CertificateEligibilitySheet(
            menteeId: picked.id,
            menteeName: picked.fullName,
            cycleId: picked.cycleId ?? 1,
            thematicAreaId: picked.thematicAreaId ?? 1,
          ),
        );
      }
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) async {
    onTapProcessed?.call();
    final repo = ref.read(notificationsRepositoryProvider);
    if (!item.isRead) {
      repo.markRead(item.id).then((_) {
        ref.invalidate(unreadCountProvider);
      }).catchError((_) {});
    }

    final role = ref.read(currentRoleProvider);
    final isMentor = role == UserRole.mentor;
    final t = '${item.type} ${item.referenceType ?? ''} ${item.title} ${item.body}'.toLowerCase();

    // Close notifications list page first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    // 1. Messages / Chat
    if (t.contains('message') || t.contains('chat') || t.contains('conversation')) {
      await _openMessageChat(nav, ref, item, isMentor);
      return;
    }

    // 2. Clinical Logbooks & Procedures
    if (t.contains('logbook') || t.contains('procedure')) {
      await _openLogbook(nav, ref, item, isMentor);
      return;
    }

    // 3. Mentoring Sessions & Meetings
    if (t.contains('session') || t.contains('meeting') || t.contains('schedule') || t.contains('appointment')) {
      await _openSession(nav, ref, item, isMentor);
      return;
    }

    // 4. Competency Assessments & Evaluations
    if (t.contains('assess') || t.contains('evaluat') || t.contains('competenc')) {
      await _openAssessments(nav, ref, item, isMentor);
      return;
    }

    // 5. Quizzes & Learning Modules / Lessons
    if (t.contains('quiz') || t.contains('module') || t.contains('lesson') || t.contains('learn') || t.contains('curriculum')) {
      await _openLearning(nav, ref, item, isMentor);
      return;
    }

    // 6. Clinical Resources & Guidelines
    if (t.contains('resource') || t.contains('guideline') || t.contains('protocol')) {
      await _openResources(nav, ref, item, isMentor);
      return;
    }

    // 7. Certificates & Completion
    if (t.contains('certif')) {
      await _openCertificates(nav, ref, item, isMentor);
      return;
    }

    // 8. Mentorship Cycles & Fallback
    nav.push(MaterialPageRoute(
      builder: (_) => isMentor ? const MentorDashboardPage() : const MenteeDashboardPage(),
    ));
  }

  Future<void> _openMessageChat(
    NavigatorState nav,
    WidgetRef ref,
    AppNotification item,
    bool isMentor,
  ) async {
    try {
      final refId = item.referenceId;
      int? targetConvId;

      // 1. Fetch conversations (cached or from API)
      List<Conversation> convs = ref.read(conversationsProvider).value ?? [];
      if (convs.isEmpty) {
        try {
          convs = await ref.read(conversationsProvider.future);
        } catch (_) {}
      }

      // 2. Direct match by conversation ID
      if (refId != null && refId > 0) {
        final directMatch = convs.where((c) => c.id == refId).firstOrNull;
        if (directMatch != null) {
          targetConvId = directMatch.id;
        } else {
          // Check if refId is a participant user ID
          final userMatch = convs.where((c) => c.participants.any((p) => p.id == refId)).firstOrNull;
          if (userMatch != null) {
            targetConvId = userMatch.id;
          } else if (item.referenceType?.toLowerCase().contains('conversation') == true) {
            targetConvId = refId;
          }
        }
      }

      // 3. Match by sender name in title or body
      if (targetConvId == null && convs.isNotEmpty) {
        final textToSearch = '${item.title} ${item.body}'.toLowerCase();
        for (final c in convs) {
          for (final p in c.participants) {
            if (p.fullName.isNotEmpty && textToSearch.contains(p.fullName.toLowerCase())) {
              targetConvId = c.id;
              break;
            }
          }
          if (targetConvId != null) break;
        }
      }

      // 4. If still null, check contactsProvider
      if (targetConvId == null) {
        final contacts = ref.read(contactsProvider);
        final textToSearch = '${item.title} ${item.body}'.toLowerCase();
        MessageUser? matchedContact;
        for (final u in contacts) {
          if (u.fullName.isNotEmpty && textToSearch.contains(u.fullName.toLowerCase())) {
            matchedContact = u;
            break;
          }
        }
        if (matchedContact != null) {
          final activeCtx = rootNavigatorKey.currentContext;
          if (activeCtx != null && activeCtx.mounted) {
            await openChatWith(activeCtx, ref, matchedContact);
          }
          return;
        }
      }

      // 5. Fallback to the most recent conversation (the one that received the message)
      if (targetConvId == null && convs.isNotEmpty) {
        targetConvId = convs.first.id;
      }

      // 6. Navigate directly to ChatPage
      if (targetConvId != null && targetConvId > 0) {
        await nav.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(conversationId: targetConvId!),
          ),
        );
        ref.invalidate(conversationsProvider);
        return;
      }
    } catch (_) {}

    // Final fallback: Messages tab
    nav.push(
      MaterialPageRoute(
        builder: (_) => const ConversationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notificationsRepositoryProvider);
    final isRead = item.isRead || isLocallyRead;

    return Material(
      color: isRead
          ? Theme.of(context).colorScheme.surface
          : AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty ? 'Notification' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  item.isRead ? FontWeight.w600 : FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listTime(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _run(context, ref, () => repo.delete(item.id)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
