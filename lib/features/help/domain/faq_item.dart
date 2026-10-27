class FaqItem {
  const FaqItem({
    required this.id,
    this.category,
    required this.question,
    required this.answer,
    this.targetAudience,
    this.facilityId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String? category;
  final String question;
  final String answer;
  final String? targetAudience;
  final int? facilityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String?,
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
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
