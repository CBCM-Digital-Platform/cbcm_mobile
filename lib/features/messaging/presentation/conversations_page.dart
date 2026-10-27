import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
import '../data/temporary_contacts.dart';
import '../domain/message_models.dart';
import 'chat_page.dart';
import 'message_time.dart';
import 'messaging_widgets.dart';
import 'contact_picker.dart';

enum _Filter { all, mentors, mentees }

/// The Message tab: list of conversations with search and filters.
class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Conversation c, int? myId) {
    if (_filter == _Filter.all) return true;
    final wanted = _filter == _Filter.mentors ? 'mentor' : 'mentee';
    return c.others(myId).any((p) => p.role.toLowerCase().contains(wanted));
  }

  Future<void> _openChat(Conversation c) async {
        await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ChatPage(conversationId: c.id)),
    );
    // Refresh unread badges and previews after coming back.
    ref.invalidate(conversationsProvider);
  }

    void _newMessage() => startNewMessage(context, ref);

  @override
  Widget build(BuildContext context) {
    final idAsync = ref.watch(currentUserIdProvider);
    final myId = idAsync.isLoading ? null : idAsync.value;
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'conversations_fab',
        onPressed: _newMessage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Messages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : Colors.transparent,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : Colors.transparent,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  _chip('All', _Filter.all),
                  const SizedBox(width: 8),
                  _chip('Mentors', _Filter.mentors),
                  const SizedBox(width: 8),
                  _chip('Mentees', _Filter.mentees),
                ],
              ),
            ),
            Expanded(
              child: conversations.when(
                skipLoadingOnReload: true,
                skipError: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => MessagingErrorView(
                  message: messagingErrorText(e),
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
                data: (all) {
                  final q = _query.trim().toLowerCase();
                  final shown = all.where((c) {
                    if (!_matchesFilter(c, myId)) return false;
                    if (q.isEmpty) return true;
                    return c.title(myId).toLowerCase().contains(q) ||
                        (c.lastMessage?.content ?? '')
                            .toLowerCase()
                            .contains(q);
                  }).toList();

                  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
                  shown.sort((a, b) => (b.lastMessageAt ?? epoch)
                      .compareTo(a.lastMessageAt ?? epoch));

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(conversationsProvider);
                      ref.invalidate(contactsApiProvider);
                      await ref.read(conversationsProvider.future).catchError((_) => <Conversation>[]);
                    },
                    child: shown.isEmpty
                        ? _buildEmptyOrDirectContacts(context, ref)
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 96),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _ConversationTile(
                              conversation: shown[i],
                              myId: myId,
                              onTap: () => _openChat(shown[i]),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final selected = _filter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setState(() => _filter = value),
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrDirectContacts(BuildContext context, WidgetRef ref) {
    final mentors = ref.watch(mentorContactsProvider);
    final mentees = ref.watch(menteeContactsProvider);
    final assigned = <MessageUser>[...mentors, ...mentees];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_query.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(
              'No conversations matching "$_query"',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    if (assigned.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2563EB) : Colors.blue.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_chat_unread_outlined, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                      Text(
                        'Start a conversation with your assigned mentorship partner below.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF93C5FD) : Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final person in assigned)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    UserAvatar(user: person, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                          Text(
                            person.role.toLowerCase() == 'mentor'
                                ? 'Assigned Mentor'
                                : 'Assigned Mentee',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Message',
                      onPressed: () => openChatWith(context, ref, person),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.chat_bubble_outline,
          size: 56,
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            noContactsMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: AppButton(
            label: 'Start New Message',
            onPressed: _newMessage,
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  final Conversation conversation;
  final int? myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final others = conversation.others(myId);
    final isGroup = conversation.type != 'direct' || others.length > 1;
    final avatarUser = isGroup || others.isEmpty ? null : others.first;
    final preview = conversation.lastMessage?.content ?? '';
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: isDark ? AppColors.darkSurface : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(user: avatarUser, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title(myId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            color: hasUnread
                                ? AppColors.pageIndicator
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.isEmpty ? 'No messages yet' : preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
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