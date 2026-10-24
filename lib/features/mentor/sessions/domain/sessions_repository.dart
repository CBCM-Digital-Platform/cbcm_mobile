import 'session_model.dart';

/// A start time on a given day, in the phone's local time.
class TimeSlot {
  const TimeSlot({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// "09:30 AM"
  String get label {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => minutesOfDay;
}

/// The free start times for one day.
class AvailableTimes {
  const AvailableTimes({required this.slots, required this.checked});

  final List<TimeSlot> slots;

  /// False when the server's answer could not be read or the request
  /// failed. The slots are then empty and the screen shows a standard list.
  final bool checked;
}

abstract class SessionsRepository {
  Future<List<SessionModel>> getSessions({
    int? mentorId,
    int? menteeId,
    String? status,
    String? mode,
  });

  Future<SessionModel> getSessionDetails(int sessionId);

  Future<SessionModel> createSession(Map<String, dynamic> sessionData);

  Future<JitsiJoinToken> getJoinToken(int sessionId);

  /// GET /sessions/available-times
  Future<AvailableTimes> getAvailableTimes({
    required int assignmentId,
    required DateTime date,
    int durationMinutes = 45,
  });

  Future<void> updateSessionStatus(int sessionId, String status);
}