import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Represents a clinical logbook entry recorded by a mentee and reviewed by a mentor.
class LogbookEntry {
  const LogbookEntry({
    required this.id,
    this.menteeId,
    this.menteeName,
    this.mentorId,
    this.cycleId,
    this.thematicAreaId,
    this.thematicAreaName,
    required this.procedureName,
    this.category,
    this.patientIdentifier,
    this.datePerformed,
    this.role = 'performed',
    this.supervisionLevel = 'direct',
    this.outcome = 'successful',
    this.notes,
    this.hours,
    this.complications,
    this.mentorFeedback,
    this.revisionReason,
    this.status = 'draft',
    this.createdAt,
    this.submittedAt,
    this.approvedAt,
  });

  final int id;
  final int? menteeId;
  final String? menteeName;
  final int? mentorId;
  final int? cycleId;
  final int? thematicAreaId;
  final String? thematicAreaName;
  final String procedureName;
  final String? category;
  final String? patientIdentifier;
  final DateTime? datePerformed;
  final String role; // performed, assisted, observed
  final String supervisionLevel; // direct, indirect, independent
  final String outcome; // successful, partially_successful, unsuccessful, complicated
  final String? notes;
  final double? hours;
  final String? complications;
  final String? mentorFeedback;
  final String? revisionReason;
  final String status; // draft, submitted, approved, revision_requested, needs_revision, rejected, cancelled
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;

  bool get isApproved => status == 'approved';
  bool get isSubmitted => status == 'submitted';
  bool get isRevisionRequested =>
      status == 'revision_requested' || status == 'needs_revision';
  bool get isNeedsRevision => isRevisionRequested;
  bool get isDraft => status == 'draft';

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final id = (json['id'] as num?)?.toInt() ?? 0;
    final menteeObj = json['mentee'] is Map ? json['mentee'] as Map : null;
    final menteeId = (menteeObj?['id'] ?? json['mentee_id'] ?? json['menteeId']) as num?;
    final menteeName = (menteeObj?['full_name'] ??
            menteeObj?['fullName'] ??
            menteeObj?['name'] ??
            json['mentee_name'] ??
            json['menteeName'])
        ?.toString();

    final mentorId = (json['mentor_id'] ?? json['mentorId']) as num?;
    final cycleId = (json['cycle_id'] ?? json['cycleId']) as num?;

    final taObj = json['thematic_area'] is Map ? json['thematic_area'] as Map : null;
    final thematicAreaId = (taObj?['id'] ??
        json['thematic_area_id'] ??
        json['thematicAreaId']) as num?;
    final thematicAreaName = (taObj?['name'] ??
            taObj?['title'] ??
            json['thematic_area_name'] ??
            json['thematicAreaName'])
        ?.toString();

    final rawHours = json['hours'] as num?;

    final mentorFeedback =
        (json['mentor_feedback'] ?? json['mentorFeedback'])?.toString();
    final revisionReason = (json['revision_reason'] ??
            json['revisionReason'] ??
            json['mentor_feedback'])
        ?.toString();

    return LogbookEntry(
      id: id,
      menteeId: menteeId?.toInt(),
      menteeName: menteeName,
      mentorId: mentorId?.toInt(),
      cycleId: cycleId?.toInt(),
      thematicAreaId: thematicAreaId?.toInt(),
      thematicAreaName: thematicAreaName,
      procedureName: (json['procedure_name'] ??
              json['procedureName'] ??
              json['procedure_type'] ??
              json['procedureType'] ??
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
      notes: (json['notes'] ??
              json['clinical_notes'] ??
              json['clinicalNotes'])
          ?.toString(),
      hours: rawHours?.toDouble(),
      complications: json['complications']?.toString(),
      mentorFeedback: mentorFeedback,
      revisionReason: revisionReason,
      status: (json['status'] ?? 'draft').toString().toLowerCase(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      submittedAt: parseDate(json['submitted_at'] ?? json['submittedAt']),
      approvedAt: parseDate(json['approved_at'] ?? json['approvedAt']),
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

  String get displayStatus {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'submitted':
        return 'Pending Review';
      case 'revision_requested':
      case 'needs_revision':
        return 'Revision Requested';
      case 'draft':
        return 'Draft';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color statusColor(BuildContext context) {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'submitted':
        return AppColors.primary;
      case 'revision_requested':
      case 'needs_revision':
        return const Color(0xFFD4A017); // Golden Yellow accent
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade700;
      case 'draft':
      default:
        return Colors.grey.shade600;
    }
  }

  Color outcomeColor(BuildContext context) {
    switch (outcome) {
      case 'complicated':
      case 'unsuccessful':
        return Colors.red.shade700;
      case 'partially_successful':
        return AppColors.warning;
      case 'successful':
      default:
        return const Color(0xFF16A34A);
    }
  }

  /// Calculates a delta map containing ONLY fields that have changed compared to this entry.
  Map<String, dynamic> buildPatchDelta({
    String? newProcedureName,
    int? newThematicAreaId,
    double? newHours,
    String? newOutcome,
    String? newRole,
    String? newSupervisionLevel,
    String? newPatientIdentifier,
    DateTime? newDatePerformed,
    String? newNotes,
    String? newComplications,
  }) {
    final delta = <String, dynamic>{};

    if (newProcedureName != null &&
        newProcedureName.trim() != procedureName.trim()) {
      delta['procedure_name'] = newProcedureName.trim();
      delta['procedure_type'] = newProcedureName.trim();
    }

    if (newThematicAreaId != null && newThematicAreaId != thematicAreaId) {
      delta['thematic_area_id'] = newThematicAreaId;
    }

    if (newHours != null && newHours != hours) {
      delta['hours'] = newHours;
    }

    if (newOutcome != null && newOutcome != outcome) {
      delta['outcome'] = newOutcome;
    }

    if (newRole != null && newRole != role) {
      delta['role'] = newRole;
    }

    if (newSupervisionLevel != null &&
        newSupervisionLevel != supervisionLevel) {
      delta['supervision_level'] = newSupervisionLevel;
    }

    if (newPatientIdentifier != null &&
        newPatientIdentifier.trim() != (patientIdentifier ?? '').trim()) {
      delta['patient_identifier'] = newPatientIdentifier.trim();
    }

    if (newDatePerformed != null &&
        (datePerformed == null ||
            newDatePerformed.year != datePerformed!.year ||
            newDatePerformed.month != datePerformed!.month ||
            newDatePerformed.day != datePerformed!.day)) {
      final d = newDatePerformed;
      delta['date_performed'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    if (newNotes != null && newNotes.trim() != (notes ?? '').trim()) {
      delta['clinical_notes'] = newNotes.trim();
      delta['notes'] = newNotes.trim();
    }

    if (newComplications != null &&
        newComplications.trim() != (complications ?? '').trim()) {
      delta['complications'] = newComplications.trim();
    }

    return delta;
  }
}

/// Request payload to create a new logbook entry by a mentee.
class CreateLogbookRequest {
  const CreateLogbookRequest({
    required this.menteeId,
    this.cycleId,
    required this.thematicAreaId,
    required this.procedureName,
    this.category = 'Clinical Procedure',
    this.patientIdentifier,
    required this.datePerformed,
    this.role = 'performed',
    this.supervisionLevel = 'direct',
    this.outcome = 'successful',
    this.hours = 1.0,
    this.notes,
    this.submitImmediately = true,
  });

  final int menteeId;
  final int? cycleId;
  final int thematicAreaId;
  final String procedureName;
  final String category;
  final String? patientIdentifier;
  final DateTime datePerformed;
  final String role;
  final String supervisionLevel;
  final String outcome;
  final double hours;
  final String? notes;
  final bool submitImmediately;

  Map<String, dynamic> toJson() {
    final d = datePerformed;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'mentee_id': menteeId,
      if (cycleId != null) 'cycle_id': cycleId,
      'thematic_area_id': thematicAreaId,
      'procedure_type': procedureName,
      'procedure_name': procedureName,
      'category': category,
      if (patientIdentifier != null && patientIdentifier!.isNotEmpty)
        'patient_identifier': patientIdentifier,
      'date_performed': dateStr,
      'hours': hours,
      'role': role,
      'supervision_level': supervisionLevel,
      'outcome': outcome,
      if (notes != null && notes!.isNotEmpty) ...{
        'clinical_notes': notes,
        'notes': notes,
      },
    };
  }
}
