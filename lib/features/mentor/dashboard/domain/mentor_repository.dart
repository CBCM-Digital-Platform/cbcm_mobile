import 'mentor_summary.dart';

abstract class MentorRepository {
  /// Calls a real mentor-dashboard summary endpoint once confirmed.
  Future<MentorSummary> getDashboardSummary(String mentorId);
}