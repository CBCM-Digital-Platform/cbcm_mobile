import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../data/messaging_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/message_models.dart';
import 'message_time.dart';
import 'messaging_widgets.dart';

/// One conversation. Refreshes every 15 seconds while it is open.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _poll;
  bool _sending = false;
  bool _markingRead = false;
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.invalidate(conversationProvider(widget.conversationId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    _markingRead = true;
    try {
      await ref.read(messagingRepositoryProvider).markRead(widget.conversationId);
      if (mounted) ref.invalidate(conversationsProvider);
    } catch (_) {
      // Not critical. It will be retried on the next refresh.
    } finally {
      _markingRead = false;
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(messagingRepositoryProvider)
          .sendMessage(widget.conversationId, text);
      if (!mounted) return;
      _inputController.clear();
      ref.invalidate(conversationProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messagingErrorText(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider).value;
    final async = ref.watch(conversationProvider(widget.conversationId));

    ref.listen<AsyncValue<Conversation>>(
      conversationProvider(widget.conversationId),
      (previous, next) {
        final c = next.value;
        if (c == null) return;
        if (c.unreadCount > 0) _markRead();
        if (c.messages.length != _lastMessageCount) {
          _lastMessageCount = c.messages.length;
          _scrollToBottom();
        }
      },
    );

    final conversation = async.value;
    final others = conversation?.others(myId) ?? const <MessageUser>[];
    final isGroup =
        conversation != null && (conversation.type != 'direct' || others.length > 1);
    final avatarUser = isGroup || others.isEmpty ? null : others.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: avatarUser, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.title(myId) ?? 'Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (!isGroup && others.isNotEmpty && others.first.role.isNotEmpty)
                    Text(
                      others.first.role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              skipError: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MessagingErrorView(
                message: messagingErrorText(e),
                onRetry: () =>
                    ref.invalidate(conversationProvider(widget.conversationId)),
              ),
              data: (c) => _MessageList(
                messages: c.messages,
                myId: myId,
                controller: _scrollController,
              ),
            ),
          ),
          _InputBar(
            controller: _inputController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.myId,
    required this.controller,
  });

  final List<ChatMessage> messages;
  final int? myId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet. Say hello!'));
    }

    // In a 1:1 direct conversation, find the timestamp of the latest message from the other person
    DateTime? lastOtherSentAt;
    for (final m in messages) {
      if (m.senderId != myId) {
        if (lastOtherSentAt == null || m.sentAt.isAfter(lastOtherSentAt)) {
          lastOtherSentAt = m.sentAt;
        }
      }
    }

    final children = <Widget>[];
    DateTime? previous;
    for (final m in messages) {
      if (previous == null || !isSameDay(previous, m.sentAt)) {
        children.add(_DateChip(label: dayLabel(m.sentAt)));
      }
      previous = m.sentAt;

      final mine = m.senderId == myId;
      // In a 1:1 chat, if the recipient replied after this message was sent, or if backend reports read, it is seen!
      final read = mine &&
          (m.isReadByOthers(myId) ||
              (lastOtherSentAt != null && !m.sentAt.isAfter(lastOtherSentAt)));
      children.add(_Bubble(message: m, mine: mine, read: read));
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: children,
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.read,
  });

  final ChatMessage message;
  final bool mine;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    final attachment = message.attachment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mine
                      ? AppColors.primary
                      : (isDark ? AppColors.darkElevatedSurface : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(mine ? 16 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 16),
                  ),
                  border: mine
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: mine
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : const Color(0xFF1E221E)),
                    height: 1.35,
                  ),
                ),
              ),
            ),
          if (attachment != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _AttachmentTile(attachment: attachment),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clockTime(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                ),
              ),
              if (mine) ...[
                const SizedBox(width: 5),
                if (read) ...[
                  const Icon(
                    Icons.done_all,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'Seen',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.done,
                    size: 16,
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Sent',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});
  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.insert_drive_file_outlined,
                color: Colors.amber.shade800),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  attachment.sizeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // TODO: make this download once the file-download endpoint is known.
          const SizedBox(width: 10),
          Icon(
            Icons.download_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attachments are coming soon.'),
                  ),
                ),
                icon: Icon(
                  Icons.attach_file,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : Colors.transparent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: sending ? null : onSend,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
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

