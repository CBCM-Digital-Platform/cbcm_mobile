import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
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
    final myId = ref.watch(currentUserIdProvider).value;
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
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
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                      await ref.read(conversationsProvider.future);
                    },
                    child: shown.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No conversations yet.')),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 96),
                            itemCount: shown.length,
                            separatorBuilder: (_, __) =>
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _filter = value),
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
    final others = conversation.others(myId);
    final isGroup = conversation.type != 'direct' || others.length > 1;
    final avatarUser = isGroup || others.isEmpty ? null : others.first;
    final preview = conversation.lastMessage?.content ?? '';
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listTime(conversation.lastMessageAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
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
                              color: Colors.grey.shade700,
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