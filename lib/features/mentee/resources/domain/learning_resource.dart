enum ResourceType { pdf, video, audio, other }

class LearningResource {
  const LearningResource({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.sizeBytes,
    this.description = '',
    this.downloadUrl,
    this.isStarred = false,
  });

  final String id;
  final String title;
  final ResourceType type;
  final String category; // e.g. a thematic area
  final int sizeBytes;
  final String description;

  /// Where the file can be downloaded from. null = not available yet.
  final String? downloadUrl;
  final bool isStarred;

  bool get isDownloadable => downloadUrl != null;

  LearningResource copyWith({bool? isStarred}) => LearningResource(
        id: id,
        title: title,
        type: type,
        category: category,
        sizeBytes: sizeBytes,
        description: description,
        downloadUrl: downloadUrl,
        isStarred: isStarred ?? this.isStarred,
      );

  String get fileExtension => switch (type) {
        ResourceType.pdf => 'pdf',
        ResourceType.video => 'mp4',
        ResourceType.audio => 'mp3',
        ResourceType.other => 'bin',
      };

  String get sizeLabel {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}