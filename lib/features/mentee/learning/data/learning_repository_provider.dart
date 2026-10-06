import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/learning_repository.dart';
import 'mock_learning_repository.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return MockLearningRepository();
});