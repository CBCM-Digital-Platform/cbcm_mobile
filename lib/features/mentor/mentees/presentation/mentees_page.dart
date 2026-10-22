import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/presentation/contact_picker.dart';
import '../../../messaging/presentation/messaging_widgets.dart';
import 'share_material_page.dart';

class MenteesPage extends ConsumerWidget {
  const MenteesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentees = ref.watch(menteeContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'My Mentees',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (mentees.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('No mentees assigned yet.')),
              ),
            for (final m in mentees)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatar(user: m, radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('Mentee',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppButtonRow(
                        secondary: AppButton(
                          label: 'Message',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => openChatWith(context, ref, m),
                        ),
                        primary: AppButton(
                          label: 'Share material',
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShareMaterialPage(initialMentee: m),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}