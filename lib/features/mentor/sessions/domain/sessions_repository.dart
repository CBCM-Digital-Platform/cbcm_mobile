import 'session_model.dart';

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

  Future<List<String>> getAvailableTimes({String? date, int? mentorId});

  Future<void> updateSessionStatus(int sessionId, String status);
}
