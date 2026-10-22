/// One notification for the signed-in user. The backend may name fields in
/// snake_case or camelCase, so both spellings are accepted.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String? referenceType;
  final int? referenceId;

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (j[k] != null) return j[k];
      }
      return null;
    }

    int toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

    final readValue = pick(['isRead', 'is_read', 'read']);
    final isRead = readValue is bool
        ? readValue
        : (readValue is num ? readValue != 0 : readValue?.toString() == 'true');

    final created = pick(['createdAt', 'created_at', 'sentAt', 'sent_at']);
    final refId = pick(['referenceId', 'reference_id']);

    return AppNotification(
      id: toInt(pick(['id'])),
      type: pick(['type'])?.toString() ?? '',
      title: pick(['title'])?.toString() ?? '',
      body: pick(['body', 'message'])?.toString() ?? '',
      isRead: isRead,
      createdAt:
          created is String ? DateTime.tryParse(created)?.toLocal() : null,
      referenceType: pick(['referenceType', 'reference_type'])?.toString(),
      referenceId: refId == null ? null : toInt(refId),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        referenceType: referenceType,
        referenceId: referenceId,
      );
}
