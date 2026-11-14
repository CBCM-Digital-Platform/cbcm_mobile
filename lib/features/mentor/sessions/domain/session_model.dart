class SessionModel {
  const SessionModel({
    required this.id,
    required this.assignmentId,
    required this.mentorId,
    required this.menteeId,
    required this.sessionType,
    required this.mode,
    required this.status,
    required this.scheduledStartTime,
    this.durationMinutes = 45,
    this.location,
    this.sessionGoals,
    this.menteeName,
    this.mentorName,
  });

  final int id;
  final int assignmentId;
  final int mentorId;
  final int menteeId;
  final String sessionType;
  final String mode; // 'virtual', 'in_person', 'hybrid'
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final DateTime scheduledStartTime;
  final int durationMinutes;
  final String? location;
  final String? sessionGoals;
  final String? menteeName;
  final String? mentorName;

  bool get isVirtual => mode.toLowerCase() == 'virtual';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['scheduled_at'] ?? json['scheduled_start_time'] ?? json['scheduledStartTime'];
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString()) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    String? mName;
    if (json['mentee'] is Map) {
      final m = json['mentee'] as Map;
      mName = (m['full_name'] ?? m['fullName'] ?? m['name'])?.toString();
    } else if (json['mentee_name'] != null) {
      mName = json['mentee_name'].toString();
    }

    String? mentName;
    if (json['mentor'] is Map) {
      final m = json['mentor'] as Map;
      mentName = (m['full_name'] ?? m['fullName'] ?? m['name'])?.toString();
    }

    return SessionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      assignmentId: (json['assignment_id'] as num?)?.toInt() ?? 0,
      mentorId: (json['mentor_id'] as num?)?.toInt() ?? 0,
      menteeId: (json['mentee_id'] as num?)?.toInt() ?? 0,
      sessionType: (json['session_type'] ?? json['sessionType'] ?? '1:1 Mentoring').toString(),
      mode: (json['mode'] ?? 'virtual').toString(),
      status: (json['status'] ?? 'scheduled').toString(),
      scheduledStartTime: parsedTime,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
      location: json['location']?.toString(),
      sessionGoals: (json['session_goals'] ?? json['notes'] ?? json['topic'])?.toString(),
      menteeName: mName,
      mentorName: mentName,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignment_id': assignmentId,
        'session_type': sessionType,
        'mode': mode,
        'scheduled_start_time': scheduledStartTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'location': location,
        'session_goals': sessionGoals,
        'status': status,
      };
}

class JitsiJoinToken {
  const JitsiJoinToken({
    required this.domain,
    required this.room,
    required this.token,
    this.expiresAt,
    this.directUrl,
  });

  final String domain;
  final String room;
  final String token;
  final String? expiresAt;
  final String? directUrl;

  String get meetingUrl {
    if (directUrl != null && directUrl!.isNotEmpty) {
      return directUrl!;
    }
    final cleanDomain = (domain.isEmpty ? 'meet.jit.si' : domain)
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/+$'), '');
    final cleanRoom = room.startsWith('/') ? room.substring(1) : room;
    if (token.isNotEmpty) {
      return 'https://$cleanDomain/$cleanRoom?jwt=$token';
    }
    return 'https://$cleanDomain/$cleanRoom';
  }

  factory JitsiJoinToken.fromJson(Map<String, dynamic> json, {int? sessionId}) {
    // 1. Look for direct full URL
    final direct = json['meeting_url'] ??
        json['meetingUrl'] ??
        json['url'] ??
        json['join_url'] ??
        json['jitsi_url'] ??
        json['link'];

    String domain = (json['domain'] ??
            json['jitsi_domain'] ??
            json['server'] ??
            json['host'] ??
            '')
        .toString()
        .trim();

    String room = (json['room'] ??
            json['room_name'] ??
            json['roomName'] ??
            json['channel'] ??
            json['session_room'] ??
            '')
        .toString()
        .trim();

    String token = (json['token'] ??
            json['jwt'] ??
            json['jwt_token'] ??
            json['access_token'] ??
            '')
        .toString()
        .trim();

    String? directUrl = direct?.toString().trim();
    if (directUrl != null && directUrl.isNotEmpty) {
      final uri = Uri.tryParse(directUrl);
      if (uri != null) {
        if (domain.isEmpty && uri.host.isNotEmpty) {
          domain = uri.host;
        }
        if (room.isEmpty && uri.pathSegments.isNotEmpty) {
          room = uri.pathSegments.first;
        }
        if (token.isEmpty && uri.queryParameters.containsKey('jwt')) {
          token = uri.queryParameters['jwt']!;
        }
      }
    }

    if (domain.isEmpty) {
      domain = 'meet.jit.si';
    }

    if (room.isEmpty && sessionId != null) {
      room = 'cbcm-session-$sessionId';
    }

    return JitsiJoinToken(
      domain: domain,
      room: room,
      token: token,
      expiresAt: (json['expires_at'] ?? json['expiresAt'])?.toString(),
      directUrl: directUrl,
    );
  }
}
