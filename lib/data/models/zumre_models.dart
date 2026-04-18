/// Zümre Çalışmalarım modülü veri modelleri

/// 1) Zümre Tanımı
class ZumreDefinition {
  final String id;
  final String name;
  final String branch;
  final String academicYear;
  final String schoolType;
  final String departmentHead;

  const ZumreDefinition({
    required this.id,
    required this.name,
    required this.branch,
    required this.academicYear,
    this.schoolType = '',
    this.departmentHead = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'branch': branch,
        'academicYear': academicYear,
        'schoolType': schoolType,
        'departmentHead': departmentHead,
      };

  factory ZumreDefinition.fromJson(Map<String, dynamic> j) => ZumreDefinition(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        branch: j['branch'] as String? ?? '',
        academicYear: j['academicYear'] as String? ?? '',
        schoolType: j['schoolType'] as String? ?? '',
        departmentHead: j['departmentHead'] as String? ?? '',
      );
}

/// 2) Toplantı Takibi
class ZumreMeeting {
  final String id;
  final DateTime meetingDate;
  final String meetingType; // dönem başı / dönem sonu / ara toplantı
  final String agendaItems;
  final String decisions;
  final String teacherTasks;
  final DateTime? nextMeetingDate;

  const ZumreMeeting({
    required this.id,
    required this.meetingDate,
    this.meetingType = 'ara',
    this.agendaItems = '',
    this.decisions = '',
    this.teacherTasks = '',
    this.nextMeetingDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'meetingDate': meetingDate.toIso8601String(),
        'meetingType': meetingType,
        'agendaItems': agendaItems,
        'decisions': decisions,
        'teacherTasks': teacherTasks,
        'nextMeetingDate': nextMeetingDate?.toIso8601String(),
      };

  factory ZumreMeeting.fromJson(Map<String, dynamic> j) => ZumreMeeting(
        id: j['id'] as String,
        meetingDate: DateTime.tryParse(j['meetingDate'] as String? ?? '') ?? DateTime.now(),
        meetingType: j['meetingType'] as String? ?? 'ara',
        agendaItems: j['agendaItems'] as String? ?? '',
        decisions: j['decisions'] as String? ?? '',
        teacherTasks: j['teacherTasks'] as String? ?? '',
        nextMeetingDate: j['nextMeetingDate'] != null ? DateTime.tryParse(j['nextMeetingDate'] as String) : null,
      );
}

/// 3) Görev & Sorumluluklarım
class ZumreTask {
  final String id;
  final String title;
  final String description;
  final String? relatedMeetingId;
  /// ADDITIVE: link to a decision
  final String? relatedDecisionId;
  final DateTime? dueDate;
  final String status; // beklemede / devam_ediyor / tamamlandı

  const ZumreTask({
    required this.id,
    required this.title,
    this.description = '',
    this.relatedMeetingId,
    this.relatedDecisionId,
    this.dueDate,
    this.status = 'beklemede',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'relatedMeetingId': relatedMeetingId,
        'relatedDecisionId': relatedDecisionId,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
      };

  factory ZumreTask.fromJson(Map<String, dynamic> j) => ZumreTask(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        relatedMeetingId: j['relatedMeetingId'] as String?,
        relatedDecisionId: j['relatedDecisionId'] as String?,
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'] as String) : null,
        status: j['status'] as String? ?? 'beklemede',
      );
}

/// 4) Kendi Katkılarım
class ZumreContribution {
  final String id;
  final String contributionType; // plan, materyal, öneri vb.
  final String description;
  final DateTime date;
  final String relatedTopicOrMeeting;

  const ZumreContribution({
    required this.id,
    required this.contributionType,
    this.description = '',
    required this.date,
    this.relatedTopicOrMeeting = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contributionType': contributionType,
        'description': description,
        'date': date.toIso8601String(),
        'relatedTopicOrMeeting': relatedTopicOrMeeting,
      };

  factory ZumreContribution.fromJson(Map<String, dynamic> j) => ZumreContribution(
        id: j['id'] as String,
        contributionType: j['contributionType'] as String? ?? '',
        description: j['description'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        relatedTopicOrMeeting: j['relatedTopicOrMeeting'] as String? ?? '',
      );
}

/// 5) Karar Takibi (Kişisel)
class ZumreDecision {
  final String id;
  final String decisionSummary;
  final String teacherRelevantPart;
  final String implementationStatus;
  final String personalNotes;

  const ZumreDecision({
    required this.id,
    this.decisionSummary = '',
    this.teacherRelevantPart = '',
    this.implementationStatus = '',
    this.personalNotes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'decisionSummary': decisionSummary,
        'teacherRelevantPart': teacherRelevantPart,
        'implementationStatus': implementationStatus,
        'personalNotes': personalNotes,
      };

  factory ZumreDecision.fromJson(Map<String, dynamic> j) => ZumreDecision(
        id: j['id'] as String,
        decisionSummary: j['decisionSummary'] as String? ?? '',
        teacherRelevantPart: j['teacherRelevantPart'] as String? ?? '',
        implementationStatus: j['implementationStatus'] as String? ?? '',
        personalNotes: j['personalNotes'] as String? ?? '',
      );
}

/// 6) Notlar & Gözlemler
class ZumreNote {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? relatedMeetingId;

  const ZumreNote({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.relatedMeetingId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'relatedMeetingId': relatedMeetingId,
      };

  factory ZumreNote.fromJson(Map<String, dynamic> j) => ZumreNote(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        relatedMeetingId: j['relatedMeetingId'] as String?,
      );
}
