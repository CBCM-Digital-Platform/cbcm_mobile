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
  });

  final String domain;
  final String room;
  final String token;
  final String? expiresAt;

  String get meetingUrl {
    final cleanDomain = domain.replaceAll(RegExp(r'^https?://'), '');
    if (token.isNotEmpty) {
      return 'https://$cleanDomain/$room?jwt=$token';
    }
    return 'https://$cleanDomain/$room';
  }

  factory JitsiJoinToken.fromJson(Map<String, dynamic> json) {
    return JitsiJoinToken(
      domain: (json['domain'] ?? '').toString(),
      room: (json['room'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}
