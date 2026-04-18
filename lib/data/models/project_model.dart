/// Proje türü
enum ProjectType {
  inClass,      // Ders içi proje
  semester,     // Dönem projesi
  social,       // Sosyal sorumluluk
  club,         // Kulüp / etkinlik
}

/// Proje durumu
enum ProjectStatus {
  draft,        // Taslak
  inProgress,   // Devam Ediyor
  completed,    // Tamamlandı
  archived,     // Arşivlendi
}

/// Öğrenci proje iş durumu
enum ParticipantWorkStatus {
  notStarted,
  inProgress,
  completed,
}

/// Proje görevi (öğrenci bazlı)
class ProjectTask {
  final String id;
  final String title;
  final bool isCompleted;

  const ProjectTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory ProjectTask.fromJson(Map<String, dynamic> j) => ProjectTask(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    isCompleted: j['isCompleted'] as bool? ?? false,
  );
}

/// Projeye katılan öğrenci
class ProjectParticipant {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final ParticipantWorkStatus workStatus;
  final String notes;
  final List<ProjectTask> tasks;

  const ProjectParticipant({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.classId = '',
    this.workStatus = ParticipantWorkStatus.notStarted,
    this.notes = '',
    this.tasks = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'classId': classId,
    'workStatus': workStatus.name,
    'notes': notes,
    'tasks': tasks.map((e) => e.toJson()).toList(),
  };

  factory ProjectParticipant.fromJson(Map<String, dynamic> j) => ProjectParticipant(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    studentName: j['studentName'] as String? ?? '',
    classId: j['classId'] as String? ?? '',
    workStatus: ParticipantWorkStatus.values.firstWhere((e) => e.name == j['workStatus'], orElse: () => ParticipantWorkStatus.notStarted),
    notes: j['notes'] as String? ?? '',
    tasks: (j['tasks'] as List<dynamic>?)?.map((e) => ProjectTask.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}

/// Proje adımı
class ProjectStep {
  final String id;
  final String title;
  final String description;
  final String estimatedDuration;

  const ProjectStep({
    required this.id,
    required this.title,
    this.description = '',
    this.estimatedDuration = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'estimatedDuration': estimatedDuration,
  };

  factory ProjectStep.fromJson(Map<String, dynamic> j) => ProjectStep(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    estimatedDuration: j['estimatedDuration'] as String? ?? '',
  );
}

/// Proje modeli
class ProjectModel {
  final String id;
  final String name;
  final ProjectType type;
  final String subject;
  final String classLevel;
  final DateTime startDate;
  final DateTime endDate;
  final String purpose;
  final String outcomes;
  final String skills;
  final String shortDescription;
  final String scope;
  final String teacherNotes;
  final List<ProjectStep> steps;
  final String materials;
  final String contentCriteria;
  final String participationCriteria;
  final String presentationCriteria;
  final String timeManagementCriteria;
  final String processNotes;
  final String observations;
  final String developmentNotes;
  final ProjectStatus status;
  final DateTime createdAt;
  final List<ProjectParticipant> participants;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.type,
    this.subject = '',
    this.classLevel = '',
    required this.startDate,
    required this.endDate,
    this.purpose = '',
    this.outcomes = '',
    this.skills = '',
    this.shortDescription = '',
    this.scope = '',
    this.teacherNotes = '',
    this.steps = const [],
    this.materials = '',
    this.contentCriteria = '',
    this.participationCriteria = '',
    this.presentationCriteria = '',
    this.timeManagementCriteria = '',
    this.processNotes = '',
    this.observations = '',
    this.developmentNotes = '',
    this.status = ProjectStatus.draft,
    required this.createdAt,
    this.participants = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'subject': subject,
    'classLevel': classLevel,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'purpose': purpose,
    'outcomes': outcomes,
    'skills': skills,
    'shortDescription': shortDescription,
    'scope': scope,
    'teacherNotes': teacherNotes,
    'steps': steps.map((e) => e.toJson()).toList(),
    'materials': materials,
    'contentCriteria': contentCriteria,
    'participationCriteria': participationCriteria,
    'presentationCriteria': presentationCriteria,
    'timeManagementCriteria': timeManagementCriteria,
    'processNotes': processNotes,
    'observations': observations,
    'developmentNotes': developmentNotes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'participants': participants.map((e) => e.toJson()).toList(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> j) => ProjectModel(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    type: ProjectType.values.firstWhere((e) => e.name == j['type'], orElse: () => ProjectType.inClass),
    subject: j['subject'] as String? ?? '',
    classLevel: j['classLevel'] as String? ?? '',
    startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(j['endDate'] as String? ?? '') ?? DateTime.now(),
    purpose: j['purpose'] as String? ?? '',
    outcomes: j['outcomes'] as String? ?? '',
    skills: j['skills'] as String? ?? '',
    shortDescription: j['shortDescription'] as String? ?? '',
    scope: j['scope'] as String? ?? '',
    teacherNotes: j['teacherNotes'] as String? ?? '',
    steps: (j['steps'] as List<dynamic>?)?.map((e) => ProjectStep.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    materials: j['materials'] as String? ?? '',
    contentCriteria: j['contentCriteria'] as String? ?? '',
    participationCriteria: j['participationCriteria'] as String? ?? '',
    presentationCriteria: j['presentationCriteria'] as String? ?? '',
    timeManagementCriteria: j['timeManagementCriteria'] as String? ?? '',
    processNotes: j['processNotes'] as String? ?? '',
    observations: j['observations'] as String? ?? '',
    developmentNotes: j['developmentNotes'] as String? ?? '',
    status: ProjectStatus.values.firstWhere((e) => e.name == j['status'], orElse: () => ProjectStatus.draft),
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    participants: (j['participants'] as List<dynamic>?)?.map((e) => ProjectParticipant.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}
