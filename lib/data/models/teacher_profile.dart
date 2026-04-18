/// Öğretmen profil bilgisi
class TeacherProfile {
  final String teacherName;
  final String schoolName;
  final List<String> classesTaught;
  final String? guidanceClass;
  final String? branch;
  final String? academicYear;

  const TeacherProfile({
    required this.teacherName,
    required this.schoolName,
    required this.classesTaught,
    this.guidanceClass,
    this.branch,
    this.academicYear,
  });

  Map<String, dynamic> toJson() => {
        'teacherName': teacherName,
        'schoolName': schoolName,
        'classesTaught': classesTaught,
        'guidanceClass': guidanceClass,
        'branch': branch,
        'academicYear': academicYear,
      };

  factory TeacherProfile.fromJson(Map<String, dynamic> json) => TeacherProfile(
        teacherName: json['teacherName'] as String,
        schoolName: json['schoolName'] as String,
        classesTaught: (json['classesTaught'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        guidanceClass: json['guidanceClass'] as String?,
        branch: json['branch'] as String?,
        academicYear: json['academicYear'] as String?,
      );
}
