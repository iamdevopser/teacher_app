import '../models/teacher_profile.dart';
import '../models/reminder.dart';
import '../models/course.dart';
import '../models/course_models.dart';
import '../models/guidance_student.dart';
import '../models/guidance_models.dart';
import '../models/assessment.dart';
import '../models/attendance_record.dart';
import '../models/lesson_planner_models.dart';
import '../models/project_model.dart';
import '../models/zumre_models.dart';
import '../repositories/app_repository.dart';

/// Tanıtım videosu için tüm menülere en az bir örnek veri ekler.
class DemoDataService {
  static Future<void> loadDemoData(AppRepository repo) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // 1) Öğretmen profili (yoksa)
    if (repo.getTeacherProfile() == null) {
      await repo.saveTeacherProfile(const TeacherProfile(
        teacherName: 'Demo Öğretmen',
        schoolName: 'Demo Okulu',
        classesTaught: ['5A', '6B'],
        guidanceClass: '5A',
        academicYear: '2024-2025',
      ));
    }

    // 2) Hatırlatıcı
    if (repo.getReminders().isEmpty) {
      await repo.addReminder(Reminder(
        id: AppRepository.generateId(),
        type: ReminderType.meeting,
        title: 'Veli toplantısı',
        description: '5A sınıfı veli toplantısı',
        dateTime: now.add(const Duration(days: 2)),
        classId: '5A',
        notified: false,
        createdAt: now,
      ));
    }

    // 3) Kurs (yapı + aktivite/oyun/quiz)
    if (repo.getCourses().isEmpty) {
      final courseId = AppRepository.generateId();
      final topicId = AppRepository.generateId();
      final contentId = AppRepository.generateId();
      final course = Course(
        id: courseId,
        name: 'HARMONİ 1',
        subject: 'Müzik',
        category: 'Müzik',
        classId: '5A',
        teacherName: 'Demo Öğretmen',
        purpose: 'Temel müzik ve ritim becerileri.',
        weeklyHours: 2,
        totalWeeks: 36,
        status: CourseStatus.active,
        outcomes: [
          CourseOutcome(id: AppRepository.generateId(), text: 'Ritim ve melodi kavramlarını uygular.', type: 'general'),
        ],
        structure: [
          CourseStructureItem(
            id: AppRepository.generateId(),
            title: 'ÜNİTE 1 : TANIŞMA VE SELAMLAŞMA',
            description: 'Temel kavramlar',
            estimatedMinutes: 240,
            orderIndex: 0,
            orderNo: 1,
            children: [
              CourseStructureItem(
                id: topicId,
                title: 'Ritim nedir?',
                orderIndex: 0,
                orderNo: 1,
                contents: [
                  LessonContentItem(id: contentId, type: 'pdf', title: 'Sunum', data: null),
                ],
              ),
            ],
          ),
        ],
        postLessonActivities: [
          {
            'type': 'activity',
            'name': 'Ritim çalışması',
            'instructions': 'Öğrenciler gruplar halinde basit ritimler oluşturur.',
            'instructionItems': [],
          },
          {
            'type': 'game',
            'name': 'Müzik eşleştirme',
            'gameRules': 'Kartları eşleştirerek müzik terimlerini öğrenin.',
            'instructionItems': [],
          },
          {
            'type': 'quiz',
            'name': 'Ünite değerlendirme',
            'quizType': 'multipleChoice',
            'instructionItems': [],
          },
        ],
        createdAt: now,
        updatedAt: now,
      );
      await repo.addCourse(course);
      repo.setLastSelectedCourseId(courseId);
    }

    // 4) Rehberlik öğrencileri
    List<GuidanceStudent> guidanceStudents = repo.getGuidanceStudents();
    if (guidanceStudents.isEmpty) {
      final s1Id = AppRepository.generateId();
      final s2Id = AppRepository.generateId();
      await repo.addGuidanceStudent(GuidanceStudent(
        id: s1Id,
        firstName: 'Ayşe',
        lastName: 'Yılmaz',
        studentNumber: '101',
        classId: '5A',
        createdAt: now,
      ));
      await repo.addGuidanceStudent(GuidanceStudent(
        id: s2Id,
        firstName: 'Mehmet',
        lastName: 'Kaya',
        studentNumber: '102',
        classId: '5A',
        createdAt: now,
      ));
      guidanceStudents = repo.getGuidanceStudents();
    }
    final firstStudentId = guidanceStudents.first.id;
    final firstStudentName = guidanceStudents.first.fullName;

    // 5) Değerlendirme
    if (repo.getAssessmentsByClass('5A').isEmpty) {
      await repo.addAssessment(Assessment(
        id: AppRepository.generateId(),
        studentId: firstStudentId,
        classId: '5A',
        subject: 'Müzik',
        title: '1. Dönem sınavı',
        score: 85,
        comments: 'İyi',
        date: now,
        createdAt: now,
      ));
    }

    // 6) Devamsızlık
    final attendanceList = repo.getAttendanceByStudentId(firstStudentId);
    if (attendanceList.isEmpty) {
      await repo.saveAttendance(AttendanceRecord(
        id: AppRepository.generateId(),
        studentId: firstStudentId,
        classId: '5A',
        date: now,
        status: AttendanceStatus.present,
        createdAt: now,
      ));
    }

    // 7) Günlük görevler
    final allTasks = repo.getDailyTasks();
    final todayTasks = allTasks.where((t) => (t['date'] as String? ?? '').startsWith(todayStr)).toList();
    if (todayTasks.isEmpty) {
      await repo.saveDailyTasks([
        ...allTasks,
        {'id': '${now.millisecondsSinceEpoch}', 'text': 'Ders planını kontrol et', 'done': false, 'date': todayStr},
        {'id': '${now.millisecondsSinceEpoch + 1}', 'text': 'Sınav kağıtlarını hazırla', 'done': false, 'date': todayStr},
      ]);
    }

    // 8) Günlük ders notu
    final notes = repo.getDailyLessonNotesByDate(now);
    if (notes.isEmpty) {
      await repo.addDailyLessonNote({
        'id': '${now.millisecondsSinceEpoch}',
        'text': '5A ile ritim çalışması verimli geçti. Yarın quiz yapılacak.',
        'date': todayStr,
        'createdAt': now.toIso8601String(),
      });
    }

    // 9) Haftalık program (birkaç hücre)
    final schedule = repo.getWeeklySchedule();
    if (schedule.isEmpty) {
      await repo.saveWeeklyScheduleCell(0, 0, '5A'); // Pazartesi 1. ders
      await repo.saveWeeklyScheduleCell(0, 1, '5A');
      await repo.saveWeeklyScheduleCell(2, 0, '5A'); // Çarşamba 1. ders
    }

    // 10) Yıllık plan
    if (repo.getAnnualPlan().isEmpty) {
      await repo.addAnnualPlanRow(AnnualPlanRow(
        id: AppRepository.generateId(),
        rowNo: 1,
        weekNo: 1,
        lessonNo: 1,
        date: now,
        classId: '5A',
        topic: 'Giriş ve tanışma',
        outcome: 'Ders kurallarını bilir.',
        homework: 'Ritim çalışması',
      ));
    }

    // 11) Günlük ders planı
    if (repo.getDailyLessonPlansByDate(now).isEmpty) {
      await repo.addDailyLessonPlan(DailyLessonPlan(
        id: AppRepository.generateId(),
        subjectName: 'Müzik',
        classId: '5A',
        teacherName: 'Demo Öğretmen',
        date: now,
        weekNo: 1,
        lessonNo: 1,
        lessonHour: '1',
        topic: 'Ritim nedir?',
        outcome: 'Temel ritim kavramı.',
        intro: 'Müzikle selamlaşma.',
        development: 'Ritim örnekleri.',
        evaluation: 'Sorular.',
        method: 'Anlatım, uygulama',
        material: 'Sunum',
        lessonNote: '',
        completed: false,
        needsMakeup: false,
        isPlanned: true,
        createdAt: now,
        filePath: null,
      ));
    }

    // 12) Ders dökümanı
    if (repo.getLessonDocuments().isEmpty) {
      await repo.addLessonDocument(LessonDocument(
        id: AppRepository.generateId(),
        classId: '5A',
        name: 'Ritim sunumu',
        format: 'PDF',
        pathOrUrl: null,
      ));
    }

    // 13) Proje
    if (repo.getProjects().isEmpty) {
      await repo.addProject(ProjectModel(
        id: AppRepository.generateId(),
        name: 'Dönem sonu konser projesi',
        type: ProjectType.inClass,
        subject: 'Müzik',
        classLevel: '5',
        startDate: now,
        endDate: now.add(const Duration(days: 60)),
        shortDescription: '5A sınıfı ritim gösterisi',
        status: ProjectStatus.inProgress,
        createdAt: now,
        participants: guidanceStudents.map((s) => ProjectParticipant(
          id: AppRepository.generateId(),
          studentId: s.id,
          studentName: s.fullName,
          classId: s.classId,
        )).toList(),
      ));
    }

    // 14) Zümre
    if (repo.getZumreDefinitions().isEmpty) {
      final defId = AppRepository.generateId();
      await repo.addZumreDefinition(ZumreDefinition(
        id: defId,
        name: 'Müzik Zümresi',
        branch: 'Müzik',
        academicYear: '2024-2025',
        schoolType: 'Ortaokul',
        departmentHead: 'Demo Öğretmen',
      ));
    }
    if (repo.getZumreMeetings().isEmpty) {
      final meetId = AppRepository.generateId();
      await repo.addZumreMeeting(ZumreMeeting(
        id: meetId,
        meetingDate: now,
        meetingType: 'donem_basi',
        agendaItems: 'Yıllık plan, ders dağılımı',
        decisions: 'Müfredat uyumu onaylandı.',
        teacherTasks: 'Ünite planlarını paylaş',
        nextMeetingDate: now.add(const Duration(days: 30)),
      ));
    }
    if (repo.getZumreTasks().isEmpty) {
      await repo.addZumreTask(ZumreTask(
        id: AppRepository.generateId(),
        title: '1. ünite materyallerini hazırla',
        description: 'Slayt ve çalışma kağıtları',
        relatedMeetingId: repo.getZumreMeetings().isNotEmpty ? repo.getZumreMeetings().first.id : null,
        dueDate: now.add(const Duration(days: 14)),
        status: 'beklemede',
      ));
    }
    if (repo.getZumreContributions().isEmpty) {
      await repo.addZumreContribution(ZumreContribution(
        id: AppRepository.generateId(),
        contributionType: 'plan',
        description: 'Ritim ünitesi yıllık plan önerisi',
        date: now,
        relatedTopicOrMeeting: '1. toplantı',
      ));
    }
    if (repo.getZumreDecisions().isEmpty) {
      await repo.addZumreDecision(ZumreDecision(
        id: AppRepository.generateId(),
        decisionSummary: 'Ortak sınav tarihleri belirlendi.',
        teacherRelevantPart: '5A sınavı 15. hafta',
        implementationStatus: 'Planlandı',
        personalNotes: '',
      ));
    }
    if (repo.getZumreNotes().isEmpty) {
      await repo.addZumreNote(ZumreNote(
        id: AppRepository.generateId(),
        title: 'Zümre notu',
        description: 'Ritim materyalleri paylaşıldı.',
        date: now,
        relatedMeetingId: repo.getZumreMeetings().isNotEmpty ? repo.getZumreMeetings().first.id : null,
      ));
    }

    // 15) Öğrenci problemi
    if (repo.getStudentProblems().isEmpty) {
      await repo.addStudentProblem(StudentProblem(
        id: AppRepository.generateId(),
        studentId: firstStudentId,
        studentName: firstStudentName,
        type: StudentProblemType.attendance,
        description: 'Birkaç devamsızlık var.',
        date: now,
        createdAt: now,
        severity: 'medium',
        resolutionStatus: 'open',
      ));
    }

    // 16) Rehberlik aktivitesi
    if (repo.getGuidanceActivities().isEmpty) {
      await repo.addGuidanceActivity(GuidanceActivity(
        id: AppRepository.generateId(),
        activityName: 'Sınıf içi motivasyon etkinliği',
        participantIds: guidanceStudents.map((s) => s.id).toList(),
        participantCount: guidanceStudents.length,
        evaluationNote: 'Olumlu geçti.',
        date: now,
        createdAt: now,
        isInSchool: true,
      ));
    }

    // 17) Rehberlik görüşmesi
    if (repo.getGuidanceMeetings().isEmpty) {
      await repo.addGuidanceMeeting(GuidanceMeeting(
        id: AppRepository.generateId(),
        meetingTitle: 'Veli görüşmesi',
        participantIds: [firstStudentId],
        participantCount: 1,
        evaluationNote: 'Aile ile işbirliği kararlaştırıldı.',
        date: now,
        createdAt: now,
        isIndividual: true,
      ));
    }
  }
}
