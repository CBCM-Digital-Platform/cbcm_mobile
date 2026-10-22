import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
import '../data/temporary_contacts.dart';
import '../domain/message_models.dart';
import 'chat_page.dart';
import 'messaging_widgets.dart';

/// Opens the one-to-one chat with [user], creating it if it doesn't exist.
Future<void> openChatWith(
  BuildContext context,
  WidgetRef ref,
  MessageUser user,
) async {
  try {
    final existingList = ref.read(conversationsProvider).value ?? [];
    final existing = existingList.cast<Conversation?>().firstWhere(
          (c) => c != null && c.type == 'direct' && c.participants.any((p) => p.id == user.id),
          orElse: () => null,
        );

    final int convId;
    if (existing != null && existing.id > 0) {
      convId = existing.id;
    } else {
      final conversation = await ref
          .read(messagingRepositoryProvider)
          .createDirectConversation(user.id);
      convId = conversation.id;
    }

    ref.invalidate(conversationsProvider);
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: convId),
      ),
    );
    ref.invalidate(conversationsProvider);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messagingErrorText(e))),
    );
  }
}

/// The "new message" button: shows who the user can message.
Future<void> startNewMessage(BuildContext context, WidgetRef ref) async {
  final contacts = ref.read(contactsProvider);

  if (contacts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(noContactsMessage())),
    );
    return;
  }

  if (contacts.length == 1) {
    await openChatWith(context, ref, contacts.first);
    return;
  }

  final picked = await showModalBottomSheet<MessageUser>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final c in contacts)
            ListTile(
              leading: UserAvatar(user: c, radius: 20),
              title: Text(c.fullName),
              subtitle: Text(c.role),
              onTap: () => Navigator.of(sheetContext).pop(c),
            ),
        ],
      ),
    ),
  );

  if (picked == null || !context.mounted) return;
  await openChatWith(context, ref, picked);
}