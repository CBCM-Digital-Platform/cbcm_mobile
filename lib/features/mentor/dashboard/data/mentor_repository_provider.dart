import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mentor_repository.dart';
import 'mock_mentor_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>((ref) {
  return MockMentorRepository();
});