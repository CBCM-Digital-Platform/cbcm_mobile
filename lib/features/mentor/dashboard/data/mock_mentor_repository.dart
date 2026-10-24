import '../domain/mentor_repository.dart';
import '../domain/mentor_summary.dart';

/// MOCKED. Replace once the backend confirms a mentor-dashboard endpoint.
class MockMentorRepository implements MentorRepository {
  @override
  Future<MentorSummary> getDashboardSummary(String mentorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const MentorSummary(
      totalMentees: 14,
      activeSessions: 3,
      logbooksPending: 7,
      todaySchedule: [
        ScheduleItem(
          time: '09:00 AM',
          title: 'Emily Chen',
          subtitle: 'First-year Review • Ward B',
          action: SessionAction.start,
        ),
        ScheduleItem(
          time: '11:30 AM',
          title: 'James Miller',
          subtitle: 'Skills Assessment • Labor & Delivery',
          action: SessionAction.details,
        ),
        ScheduleItem(
          time: '02:00 PM',
          title: 'Group Seminar',
          subtitle: 'Postnatal Care Updates • Room 402',
          action: SessionAction.details,
          isGroup: true,
        ),
      ],
      recentActivity: [
        ActivityItem(
          icon: ActivityIconType.logbookSubmitted,
          description: 'Le submitted the Clinical Case Study: Pre-eclampsia.',
          timeAgo: '2 hours ago',
          tag: 'Module: Maternal Health',
        ),
        ActivityItem(
          icon: ActivityIconType.clarificationRequested,
          description: 'Le requested clarification on a clinical protocol.',
          timeAgo: '4 hours ago',
        ),
        ActivityItem(
          icon: ActivityIconType.approved,
          description: "You evaluated Le's Quiz on Neonatal Resuscitation.",
          timeAgo: 'Yesterday',
        ),
      ],
    );
  }
}