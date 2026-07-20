import 'app_role.dart';

class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    required this.mobile,
    required this.institutionId,
    required this.branchId,
    required this.role,
    this.photoUrl = '',
  });

  final String id;
  final String name;
  final String mobile;
  final String institutionId;
  final String branchId;
  final AppRole role;
  final String photoUrl;

  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    return Teacher(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      mobile: (data['mobile'] as String?)?.trim() ?? '',
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['branchId'] as String?)?.trim() ?? '',
      role: appRoleFromString(data['role'] as String?) ?? AppRole.teacher,
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'mobile': mobile,
        'institutionId': institutionId,
        'branchId': branchId,
        'role': role.firestoreValue,
        'photoUrl': photoUrl,
      };
}
