import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/curriculum_repository.dart';
import 'dio_curriculum_repository.dart';

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return DioCurriculumRepository(ref.watch(dioProvider));
});
