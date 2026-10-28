class AssessmentCriterionScore {
  const AssessmentCriterionScore({
    this.id,
    required this.criterion,
    required this.score,
  });

  final int? id;
  final String criterion;
  final double score;

  factory AssessmentCriterionScore.fromJson(Map<String, dynamic> json) {
    return AssessmentCriterionScore(
      id: (json['id'] as num?)?.toInt(),
      criterion: (json['criterion'] ?? '').toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'criterion': criterion,
        'score': score,
      };
}

class AssessmentChecklistItem {
  const AssessmentChecklistItem({
    this.id,
    required this.item,
    required this.checked,
  });

  final int? id;
  final String item;
  final bool checked;

  factory AssessmentChecklistItem.fromJson(Map<String, dynamic> json) {
    return AssessmentChecklistItem(
      id: (json['id'] as num?)?.toInt(),
      item: (json['item'] ?? '').toString(),
      checked: json['checked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'checked': checked,
      };
}

class Assessment {
  const Assessment({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    required this.mentorId,
    this.mentorName,
    required this.facilityId,
    required this.cycleId,
    this.thematicAreaId,
    required this.area,
    required this.status,
    required this.prerequisitesMet,
    this.theoryScore,
    this.theoryPassed,
    this.aggregateScore,
    required this.criteriaScores,
    required this.checklistItems,
    required this.feedback,
    required this.createdAt,
    this.finalizedAt,
  });

  final int id;
  final int menteeId;
  final String menteeName;
  final int mentorId;
  final String? mentorName;
  final int facilityId;
  final int cycleId;
  final int? thematicAreaId;
  final String area;
  final String status; // 'draft', 'in_review', 'finalized', 'reviewed'
  final bool prerequisitesMet;
  final double? theoryScore;
  final bool? theoryPassed;
  final double? aggregateScore;
  final List<AssessmentCriterionScore> criteriaScores;
  final List<AssessmentChecklistItem> checklistItems;
  final String feedback;
  final DateTime createdAt;
  final DateTime? finalizedAt;

  bool get isFinalized => status == 'finalized' || status == 'reviewed';
  bool get isInReview => status == 'in_review';
  bool get isDraft => status == 'draft';

  double get displayScore {
    if (aggregateScore != null) return aggregateScore!;
    if (criteriaScores.isNotEmpty) {
      final total = criteriaScores.fold<double>(0.0, (s, c) => s + c.score);
      return total / criteriaScores.length;
    }
    return 0.0;
  }

  Map<String, int> get criteriaMap => {
        for (final c in criteriaScores) c.criterion: c.score.round(),
      };

  Map<String, bool> get checklistMap => {
        for (final item in checklistItems) item.item: item.checked,
      };

  factory Assessment.fromJson(Map<String, dynamic> json) {
    // mentee name extraction
    String mentee = '';
    if (json['mentee'] is Map) {
      mentee = (json['mentee']['full_name'] ?? json['mentee']['name'] ?? '').toString();
    }
    if (mentee.isEmpty) {
      mentee = (json['mentee_name'] ?? json['menteeName'] ?? 'Mentee #').toString();
    }

    // mentor name extraction
    String mentor = '';
    if (json['mentor'] is Map) {
      mentor = (json['mentor']['full_name'] ?? json['mentor']['name'] ?? '').toString();
    }
    if (mentor.isEmpty && json['mentor_name'] != null) {
      mentor = json['mentor_name'].toString();
    }

    // thematic area extraction
    String areaName = '';
    if (json['thematic_area'] is Map) {
      areaName = (json['thematic_area']['name'] ?? '').toString();
    }
    if (areaName.isEmpty) {
      areaName = (json['area'] ?? json['thematic_area_name'] ?? 'Clinical Competency').toString();
    }

    // criteria scores
    final rawCriteria = json['criteria_scores'] ?? json['criteriaScores'];
    final criteria = <AssessmentCriterionScore>[];
    if (rawCriteria is List) {
      for (final c in rawCriteria) {
        if (c is Map) {
          criteria.add(AssessmentCriterionScore.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    } else if (json['criteria'] is Map) {
      final m = json['criteria'] as Map;
      m.forEach((k, v) {
        criteria.add(AssessmentCriterionScore(
          criterion: k.toString(),
          score: (v as num?)?.toDouble() ?? 0.0,
        ));
      });
    }

    // checklist items
    final rawChecklist = json['checklist_items'] ?? json['checklistItems'];
    final checklist = <AssessmentChecklistItem>[];
    if (rawChecklist is List) {
      for (final item in rawChecklist) {
        if (item is Map) {
          checklist.add(AssessmentChecklistItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (json['checklist'] is Map) {
      final m = json['checklist'] as Map;
      m.forEach((k, v) {
        checklist.add(AssessmentChecklistItem(
          item: k.toString(),
          checked: v == true,
        ));
      });
    }

    DateTime parsedCreated;
    try {
      parsedCreated = DateTime.parse(json['created_at'] ?? json['createdAt'] ?? '');
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    DateTime? parsedFinalized;
    if (json['finalized_at'] != null) {
      try {
        parsedFinalized = DateTime.parse(json['finalized_at'].toString());
      } catch (_) {}
    }

    return Assessment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      menteeId: (json['mentee_id'] ?? json['menteeId'] as num?)?.toInt() ?? 0,
      menteeName: mentee,
      mentorId: (json['mentor_id'] ?? json['mentorId'] as num?)?.toInt() ?? 0,
      mentorName: mentor.isNotEmpty ? mentor : null,
      facilityId: (json['facility_id'] ?? json['facilityId'] as num?)?.toInt() ?? 1,
      cycleId: (json['cycle_id'] ?? json['cycleId'] as num?)?.toInt() ?? 1,
      thematicAreaId: (json['thematic_area_id'] ?? json['thematicAreaId'] as num?)?.toInt(),
      area: areaName,
      status: (json['status'] ?? 'draft').toString().toLowerCase(),
      prerequisitesMet: json['prerequisites_met'] == true || json['prerequisitesMet'] == true,
      theoryScore: (json['theory_score'] ?? json['theoryScore'] as num?)?.toDouble(),
      theoryPassed: json['theory_passed'] == true || json['theoryPassed'] == true,
      aggregateScore: (json['aggregate_score'] ?? json['aggregateScore'] ?? json['score'] as num?)?.toDouble(),
      criteriaScores: criteria,
      checklistItems: checklist,
      feedback: (json['feedback'] ?? '').toString(),
      createdAt: parsedCreated,
      finalizedAt: parsedFinalized,
    );
  }
}

class CreateAssessmentRequest {
  const CreateAssessmentRequest({
    required this.menteeId,
    required this.mentorId,
    required this.facilityId,
    required this.cycleId,
    this.thematicAreaId,
    this.prerequisitesMet = true,
  });

  final int menteeId;
  final int mentorId;
  final int facilityId;
  final int cycleId;
  final int? thematicAreaId;
  final bool prerequisitesMet;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'mentee_id': menteeId,
      'mentor_id': mentorId,
      'facility_id': facilityId,
      'cycle_id': cycleId,
      'prerequisites_met': prerequisitesMet,
    };
    if (thematicAreaId != null && thematicAreaId! > 0) {
      map['thematic_area_id'] = thematicAreaId;
    }
    return map;
  }
}
