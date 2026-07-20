class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.location,
    this.institutionPassword = '',
    this.teacherPassword = '',
  });

  final String id;
  final String name;
  final String location;
  final String institutionPassword;
  final String teacherPassword;

  factory Institution.fromMap(String id, Map<String, dynamic> data) {
    return Institution(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      location: (data['location'] as String?)?.trim() ?? '',
      institutionPassword:
          (data['institutionPassword'] as String?)?.trim() ?? '',
      teacherPassword: (data['teacherPassword'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'location': location,
        'institutionPassword': institutionPassword,
        'teacherPassword': teacherPassword,
      };
}
