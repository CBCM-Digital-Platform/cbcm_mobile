class Certificate {
  const Certificate({
    required this.id,
    required this.menteeId,
    required this.cycleId,
    required this.thematicAreaId,
    this.templateId,
    required this.menteeName,
    required this.status,
    this.pdfUrl,
    this.issuedBy,
    this.issuedByName,
    required this.thematicAreaName,
    required this.cycleName,
    required this.issuedAt,
    this.version = 1,
  });

  final int id;
  final int menteeId;
  final int cycleId;
  final int thematicAreaId;
  final int? templateId;
  final String menteeName;
  final String status; // 'issued', 'revoked'
  final String? pdfUrl;
  final int? issuedBy;
  final String? issuedByName;
  final String thematicAreaName;
  final String cycleName;
  final DateTime issuedAt;
  final int version;

  bool get isIssued => status.toLowerCase() == 'issued';
  bool get isRevoked => status.toLowerCase() == 'revoked';

  factory Certificate.fromJson(Map<String, dynamic> json) {
    String name = (json['mentee_name_snapshot'] ?? '').toString();
    if (name.isEmpty && json['mentee'] is Map) {
      name = (json['mentee']['full_name'] ?? json['mentee']['name'] ?? '').toString();
    }
    if (name.isEmpty) name = 'Mentee #${json['mentee_id']}';

    String area = '';
    if (json['thematicArea'] is Map) {
      area = (json['thematicArea']['name'] ?? json['thematicArea']['code'] ?? '').toString();
    } else if (json['thematic_area'] is Map) {
      area = (json['thematic_area']['name'] ?? json['thematic_area']['code'] ?? '').toString();
    }
    if (area.isEmpty) area = (json['thematic_area_name'] ?? 'Clinical Competency').toString();

    String cycle = '';
    if (json['cycle'] is Map) {
      cycle = (json['cycle']['name'] ?? '').toString();
    }
    if (cycle.isEmpty) cycle = (json['cycle_name'] ?? 'Cycle #${json['cycle_id']}').toString();

    String? issuer;
    if (json['issuedBy'] is Map) {
      issuer = (json['issuedBy']['full_name'] ?? json['issuedBy']['name'] ?? '').toString();
    }

    DateTime parsedIssued;
    try {
      parsedIssued = DateTime.parse(json['issued_at'] ?? json['issuedAt'] ?? '');
    } catch (_) {
      parsedIssued = DateTime.now();
    }

    return Certificate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      menteeId: (json['mentee_id'] ?? json['menteeId'] as num?)?.toInt() ?? 0,
      cycleId: (json['cycle_id'] ?? json['cycleId'] as num?)?.toInt() ?? 0,
      thematicAreaId: (json['thematic_area_id'] ?? json['thematicAreaId'] as num?)?.toInt() ?? 0,
      templateId: (json['template_id'] ?? json['templateId'] as num?)?.toInt(),
      menteeName: name,
      status: (json['status'] ?? 'issued').toString().toLowerCase(),
      pdfUrl: json['pdf_url']?.toString(),
      issuedBy: (json['issued_by'] ?? json['issuedBy']?['id'] as num?)?.toInt(),
      issuedByName: issuer,
      thematicAreaName: area,
      cycleName: cycle,
      issuedAt: parsedIssued,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class CertificateEligibility {
  const CertificateEligibility({
    required this.isEligible,
    this.theoryPassed = false,
    this.practicalPassed = false,
    this.hasFinalizedAssessment = false,
    this.hasExistingCertificate = false,
    this.message,
    this.assessmentId,
  });

  final bool isEligible;
  final bool theoryPassed;
  final bool practicalPassed;
  final bool hasFinalizedAssessment;
  final bool hasExistingCertificate;
  final String? message;
  final int? assessmentId;

  factory CertificateEligibility.fromJson(Map<String, dynamic> json) {
    return CertificateEligibility(
      isEligible: json['eligible'] == true || json['is_eligible'] == true || json['isEligible'] == true,
      theoryPassed: json['theory_passed'] == true || json['theoryPassed'] == true,
      practicalPassed: json['practical_passed'] == true || json['practicalPassed'] == true,
      hasFinalizedAssessment: json['has_finalized_assessment'] == true || json['hasFinalizedAssessment'] == true,
      hasExistingCertificate: json['has_existing_certificate'] == true || json['hasExistingCertificate'] == true,
      message: json['message']?.toString(),
      assessmentId: (json['assessment_id'] ?? json['assessmentId'] as num?)?.toInt(),
    );
  }
}
