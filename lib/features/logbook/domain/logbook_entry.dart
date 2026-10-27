import 'package:flutter/material.dart';

/// Represents a clinical logbook entry recorded by a mentor or mentee.
class LogbookEntry {
  const LogbookEntry({
    required this.id,
    this.menteeId,
    this.mentorId,
    this.cycleId,
    this.thematicAreaId,
    required this.procedureName,
    this.category,
    this.patientIdentifier,
    this.datePerformed,
    this.role = 'performed',
    this.supervisionLevel = 'direct',
    this.outcome = 'successful',
    this.notes,
    this.complications,
    this.mentorFeedback,
    this.status = 'approved',
    this.createdAt,
  });

  final int id;
  final int? menteeId;
  final int? mentorId;
  final int? cycleId;
  final int? thematicAreaId;
  final String procedureName;
  final String? category;
  final String? patientIdentifier;
  final DateTime? datePerformed;
  final String role; // performed, assisted, observed
  final String supervisionLevel; // direct, indirect, independent
  final String outcome; // successful, partially_successful, unsuccessful, complicated
  final String? notes;
  final String? complications;
  final String? mentorFeedback;
  final String status; // draft, submitted, approved, revision_requested
  final DateTime? createdAt;

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final id = (json['id'] as num?)?.toInt() ?? 0;
    final menteeId = (json['mentee_id'] ?? json['menteeId']) as num?;
    final mentorId = (json['mentor_id'] ?? json['mentorId']) as num?;
    final cycleId = (json['cycle_id'] ?? json['cycleId']) as num?;
    final thematicAreaId =
        (json['thematic_area_id'] ?? json['thematicAreaId']) as num?;

    return LogbookEntry(
      id: id,
      menteeId: menteeId?.toInt(),
      mentorId: mentorId?.toInt(),
      cycleId: cycleId?.toInt(),
      thematicAreaId: thematicAreaId?.toInt(),
      procedureName: (json['procedure_name'] ??
              json['procedureName'] ??
              json['title'] ??
              'Clinical Procedure')
          .toString(),
      category: json['category']?.toString(),
      patientIdentifier:
          (json['patient_identifier'] ?? json['patientIdentifier'])?.toString(),
      datePerformed: parseDate(json['date_performed'] ?? json['datePerformed']),
      role: (json['role'] ?? 'performed').toString().toLowerCase(),
      supervisionLevel: (json['supervision_level'] ??
              json['supervisionLevel'] ??
              'direct')
          .toString()
          .toLowerCase(),
      outcome: (json['outcome'] ?? 'successful').toString().toLowerCase(),
      notes: (json['notes'] ?? json['clinical_notes'] ?? json['clinicalNotes'])
          ?.toString(),
      complications: json['complications']?.toString(),
      mentorFeedback:
          (json['mentor_feedback'] ?? json['mentorFeedback'])?.toString(),
      status: (json['status'] ?? 'approved').toString().toLowerCase(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  String get displayRole {
    switch (role) {
      case 'assisted':
        return 'Assisted';
      case 'observed':
        return 'Observed';
      case 'performed':
      default:
        return 'Performed';
    }
  }

  String get displaySupervision {
    switch (supervisionLevel) {
      case 'indirect':
        return 'Indirect';
      case 'independent':
        return 'Independent';
      case 'direct':
      default:
        return 'Direct';
    }
  }

  String get displayOutcome {
    switch (outcome) {
      case 'partially_successful':
        return 'Partially Successful';
      case 'unsuccessful':
        return 'Unsuccessful';
      case 'complicated':
        return 'Complicated';
      case 'successful':
      default:
        return 'Successful';
    }
  }

  Color outcomeColor(BuildContext context) {
    switch (outcome) {
      case 'complicated':
      case 'unsuccessful':
        return Colors.red.shade700;
      case 'partially_successful':
        return Colors.amber.shade800;
      case 'successful':
      default:
        return const Color(0xFF16A34A);
    }
  }
}

/// Request payload to create a new logbook entry.
class CreateLogbookRequest {
  const CreateLogbookRequest({
    required this.menteeId,
    required this.cycleId,
    required this.thematicAreaId,
    required this.procedureName,
    this.category = 'Clinical Procedure',
    this.patientIdentifier,
    required this.datePerformed,
    this.role = 'performed',
    this.supervisionLevel = 'direct',
    this.outcome = 'successful',
    this.notes,
    this.mentorFeedback,
  });

  final int menteeId;
  final int cycleId;
  final int thematicAreaId;
  final String procedureName;
  final String category;
  final String? patientIdentifier;
  final DateTime datePerformed;
  final String role;
  final String supervisionLevel;
  final String outcome;
  final String? notes;
  final String? mentorFeedback;

  Map<String, dynamic> toJson() {
    final d = datePerformed;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'mentee_id': menteeId,
      'cycle_id': cycleId,
      'thematic_area_id': thematicAreaId,
      'procedure_name': procedureName,
      'category': category,
      if (patientIdentifier != null && patientIdentifier!.isNotEmpty)
        'patient_identifier': patientIdentifier,
      'date_performed': dateStr,
      'role': role,
      'supervision_level': supervisionLevel,
      'outcome': outcome,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (mentorFeedback != null && mentorFeedback!.isNotEmpty)
        'mentor_feedback': mentorFeedback,
    };
  }
}
