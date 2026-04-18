/// Rehberlik sınıfı öğrenci modeli
class GuidanceStudent {
  final String id;
  final String lastName;
  final String firstName;
  final String studentNumber;
  final String classId;
  final String email;
  final String phone;
  final String nationality;
  final String gender;
  final String address;
  final String motherName;
  final String motherPhone;
  final String motherEmail;
  final String fatherName;
  final String fatherPhone;
  final String fatherEmail;
  final DateTime createdAt;

  const GuidanceStudent({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.studentNumber,
    required this.classId,
    this.email = '',
    this.phone = '',
    this.nationality = '',
    this.gender = '',
    this.address = '',
    this.motherName = '',
    this.motherPhone = '',
    this.motherEmail = '',
    this.fatherName = '',
    this.fatherPhone = '',
    this.fatherEmail = '',
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastName': lastName,
        'firstName': firstName,
        'studentNumber': studentNumber,
        'classId': classId,
        'email': email,
        'phone': phone,
        'nationality': nationality,
        'gender': gender,
        'address': address,
        'motherName': motherName,
        'motherPhone': motherPhone,
        'motherEmail': motherEmail,
        'fatherName': fatherName,
        'fatherPhone': fatherPhone,
        'fatherEmail': fatherEmail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GuidanceStudent.fromJson(Map<String, dynamic> json) {
    // Geriye dönük uyumluluk: eski name, parentName, parentPhone
    final name = json['name'] as String? ?? '';
    final parts = name.split(' ');
    final firstName = json['firstName'] as String? ?? (parts.isNotEmpty ? parts.first : '');
    final lastName = json['lastName'] as String? ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');
    final parentName = json['parentName'] as String? ?? '';
    final parentPhone = json['parentPhone'] as String? ?? '';

    return GuidanceStudent(
      id: json['id'] as String,
      lastName: json['lastName'] as String? ?? lastName,
      firstName: json['firstName'] as String? ?? firstName,
      studentNumber: json['studentNumber'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      address: json['address'] as String? ?? '',
      motherName: json['motherName'] as String? ?? parentName,
      motherPhone: json['motherPhone'] as String? ?? parentPhone,
      motherEmail: json['motherEmail'] as String? ?? '',
      fatherName: json['fatherName'] as String? ?? '',
      fatherPhone: json['fatherPhone'] as String? ?? '',
      fatherEmail: json['fatherEmail'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  GuidanceStudent copyWith({
    String? id,
    String? lastName,
    String? firstName,
    String? studentNumber,
    String? classId,
    String? email,
    String? phone,
    String? nationality,
    String? gender,
    String? address,
    String? motherName,
    String? motherPhone,
    String? motherEmail,
    String? fatherName,
    String? fatherPhone,
    String? fatherEmail,
    DateTime? createdAt,
  }) =>
      GuidanceStudent(
        id: id ?? this.id,
        lastName: lastName ?? this.lastName,
        firstName: firstName ?? this.firstName,
        studentNumber: studentNumber ?? this.studentNumber,
        classId: classId ?? this.classId,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        nationality: nationality ?? this.nationality,
        gender: gender ?? this.gender,
        address: address ?? this.address,
        motherName: motherName ?? this.motherName,
        motherPhone: motherPhone ?? this.motherPhone,
        motherEmail: motherEmail ?? this.motherEmail,
        fatherName: fatherName ?? this.fatherName,
        fatherPhone: fatherPhone ?? this.fatherPhone,
        fatherEmail: fatherEmail ?? this.fatherEmail,
        createdAt: createdAt ?? this.createdAt,
      );
}
