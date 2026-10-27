class UserGuideItem {
  const UserGuideItem({
    required this.id,
    required this.title,
    required this.content,
    this.attachmentFileId,
    this.targetAudience,
    this.facilityId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String content;
  final int? attachmentFileId;
  final String? targetAudience;
  final int? facilityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUrl {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  factory UserGuideItem.fromJson(Map<String, dynamic> json) {
    return UserGuideItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      attachmentFileId: (json['attachment_file_id'] as num?)?.toInt(),
      targetAudience: json['target_audience'] as String?,
      facilityId: (json['facility_id'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
