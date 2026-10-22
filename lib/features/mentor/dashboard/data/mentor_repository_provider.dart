import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/mentor_repository.dart';
import 'dio_mentor_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DioMentorRepository(dio);
});