import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/domain/message_models.dart';
import '../../../messaging/presentation/contact_picker.dart';
import '../../../messaging/presentation/messaging_widgets.dart';

class MyMentorPage extends ConsumerWidget {
  const MyMentorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentors = ref.watch(mentorContactsProvider);
    final loading = ref.watch(contactsApiProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(contactsApiProvider);
            await ref
                .read(contactsApiProvider.future)
                .catchError((_) => <MessageUser>[]);
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
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Message',
                            onPressed: () => openChatWith(context, ref, m),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const AppCard(
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your upcoming sessions with your mentor will appear here.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
