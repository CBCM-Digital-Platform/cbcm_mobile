enum ModuleStatus { notStarted, inProgress, completed }

class LearningModule {
  const LearningModule({
    required this.id,
    required this.title,
    required this.thematicArea,
    required this.protocolSummary,
    required this.status,
  });

  final String id;
  final String title;
  final String thematicArea;
  final String protocolSummary;
  final ModuleStatus status;
}
