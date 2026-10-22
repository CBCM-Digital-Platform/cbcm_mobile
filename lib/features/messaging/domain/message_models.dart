DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// The backend uses snake_case in some places and camelCase in others,
/// so every field accepts both spellings. Returns the first key present.
dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json[k] != null) return json[k];
  }
  return null;
}

int _int(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.map(_map).whereType<Map<String, dynamic>>().toList()
    : const [];

class MessageUser {
  const MessageUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  final int id;
  final String fullName;
  final String role;
  final String? avatarUrl;

  factory MessageUser.fromJson(Map<String, dynamic> raw) {
    // Some responses wrap the person: {"user_id": 6, "user": {...}}.
    final json = _map(raw['user']) ?? raw;
    return MessageUser(
      id: _int(_pick(json, ['id', 'userId', 'user_id']) ??
          _pick(raw, ['userId', 'user_id'])),
      fullName:
          _pick(json, ['fullName', 'full_name', 'name'])?.toString() ??
              'Unknown',
      role: _pick(json, ['role'])?.toString() ?? '',
      avatarUrl: _pick(json, ['avatarUrl', 'avatar_url'])?.toString(),
    );
  }

  /// "Emily Chen" -> "EC"
  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.storageKey,
    required this.mimeType,
    required this.sizeBytes,
  });

  final int id;
  final String storageKey;
  final String mimeType;
  final int sizeBytes;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        id: _int(_pick(json, ['id'])),
        storageKey:
            _pick(json, ['storageKey', 'storage_key'])?.toString() ?? '',
        mimeType: _pick(json, ['mimeType', 'mime_type'])?.toString() ?? '',
        sizeBytes: _int(_pick(json, ['sizeBytes', 'size_bytes'])),
      );

  /// Last part of the storage key, used as the displayed file name.
  String get fileName {
    final cleaned = storageKey.replaceAll('\\', '/');
    final name = cleaned.split('/').last;
    return name.isEmpty ? 'Attachment' : name;
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.sender,
    this.attachment,
    this.readByUserIds = const [],
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final MessageUser? sender;
  final MessageAttachment? attachment;
  final List<int> readByUserIds;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = _map(json['sender']);
    final attachment = _map(json['attachment']);
    return ChatMessage(
      id: _int(json['id']),
      conversationId:
          _int(_pick(json, ['conversationId', 'conversation_id'])),
      senderId:
          _int(_pick(json, ['senderId', 'sender_id']) ?? sender?['id']),
      content: _pick(json, ['content'])?.toString() ?? '',
      sentAt: _parseDate(_pick(
              json, ['sentAt', 'sent_at', 'createdAt', 'created_at'])) ??
          DateTime.now(),
      sender: sender == null ? null : MessageUser.fromJson(sender),
      attachment:
          attachment == null ? null : MessageAttachment.fromJson(attachment),
      readByUserIds: _maps(json['reads'])
          .map((r) => _int(_pick(r, ['userId', 'user_id'])))
          .toList(),
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.participants,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageAt,
    this.messages = const [],
  });

  final int id;
  final String type; // "direct" or a group type
  final List<MessageUser> participants;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Only filled by the "load a conversation" endpoint, oldest first.
  final List<ChatMessage> messages;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = _map(_pick(json, ['lastMessage', 'last_message']));
    final lastMessage = last == null ? null : ChatMessage.fromJson(last);
    return Conversation(
      id: _int(json['id']),
      type: _pick(json, ['type'])?.toString() ?? 'direct',
      participants:
          _maps(json['participants']).map(MessageUser.fromJson).toList(),
      lastMessage: lastMessage,
      lastMessageAt:
          _parseDate(_pick(json, ['lastMessageAt', 'last_message_at'])) ??
              lastMessage?.sentAt,
      unreadCount: _int(_pick(json, ['unreadCount', 'unread_count'])),
      messages: _maps(json['messages']).map(ChatMessage.fromJson).toList(),
    );
  }

  /// Everyone except the signed-in user.
  List<MessageUser> others(int? myId) {
    final list = participants.where((p) => p.id != myId).toList();
    return list.isEmpty ? participants : list;
  }

  String title(int? myId) {
    final names = others(myId).map((p) => p.fullName).toList();
    return names.isEmpty ? 'Conversation' : names.join(', ');
  }
}