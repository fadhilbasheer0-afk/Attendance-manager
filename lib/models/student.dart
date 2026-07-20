import 'app_role.dart';

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.mobile,
    required this.institutionId,
    required this.branchId,
    required this.className,
    required this.medium,
    required this.role,
    this.photoUrl = '',
  });

  final String id;
  final String name;
  final String admissionNumber;
  final String mobile;
  final String institutionId;
  final String branchId;
  final String className;
  final String medium;
  final AppRole role;
  final String photoUrl;

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      admissionNumber: (data['admissionNumber'] as String?)?.trim() ?? '',
      mobile: (data['mobile'] as String?)?.trim() ?? '',
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['branchId'] as String?)?.trim() ?? '',
      className: (data['className'] as String?)?.trim() ?? '',
      medium: (data['medium'] as String?)?.trim() ?? '',
      role: appRoleFromString(data['role'] as String?) ?? AppRole.student,
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'admissionNumber': admissionNumber,
        'mobile': mobile,
        'institutionId': institutionId,
        'branchId': branchId,
        'className': className,
        'medium': medium,
        'role': role.firestoreValue,
        'photoUrl': photoUrl,
      };
}
