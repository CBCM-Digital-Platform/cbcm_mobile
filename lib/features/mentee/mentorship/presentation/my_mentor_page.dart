import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/domain/message_models.dart';
import '../../../messaging/presentation/contact_picker.dart';
import '../../../messaging/presentation/messaging_widgets.dart';
import '../../../mentor/sessions/domain/session_model.dart';
import '../../../mentor/sessions/presentation/mentor_sessions_page.dart';
import '../../../mentor/sessions/presentation/schedule_session_sheet.dart';

class MyMentorPage extends ConsumerWidget {
  const MyMentorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawMentors = ref.watch(mentorContactsProvider);
    final fallbackMentor = ref.watch(assignedMentorProvider).value;
    final mentors = rawMentors.isNotEmpty
        ? rawMentors
        : (fallbackMentor != null ? [fallbackMentor] : const <MessageUser>[]);
    final loading = ref.watch(contactsApiProvider).isLoading && mentors.isEmpty;
    final sessionsAsync = ref.watch(menteeSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(contactsApiProvider);
            ref.invalidate(assignedMentorProvider);
            ref.invalidate(menteeSessionsProvider);
            await ref
                .read(contactsApiProvider.future)
                .catchError((_) => <MessageUser>[]);
            await ref
                .read(assignedMentorProvider.future)
                .catchError((_) => null);
            await ref
                .read(menteeSessionsProvider.future)
                .catchError((_) => <SessionModel>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'My Mentor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (loading && mentors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!loading && mentors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No mentor assigned yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              for (final m in mentors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            UserAvatar(user: m, radius: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Your mentor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : Colors.grey.shade600,
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
                              child: AppButton(
                                label: 'Schedule',
                                onPressed: () => ScheduleSessionSheet.show(
                                  context,
                                  menteeName: m.fullName,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                label: 'Message',
                                variant: AppButtonVariant.secondary,
                                onPressed: () => openChatWith(context, ref, m),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Upcoming Sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              sessionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Could not load sessions.'),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(menteeSessionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return AppCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No sessions scheduled yet. Use the "Schedule" button above to request a supervision session.',
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
                  return Column(
                    children: [
                      for (final s in sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SessionCard(
                            session: s,
                            isMenteeView: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
