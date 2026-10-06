import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/curriculum_repository.dart';
import 'mock_curriculum_repository.dart';

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return MockCurriculumRepository();
});