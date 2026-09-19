enum AttendanceMode { daily, twoSession }

AttendanceMode? attendanceModeFromString(String? v) {
  if (v == null) return null;
  for (final m in AttendanceMode.values) {
    if (m.name == v) return m;
  }
  return null;
}

extension AttendanceModeX on AttendanceMode {
  String get firestoreValue => name;

  String get label {
    switch (this) {
      case AttendanceMode.daily:
        return 'Once Per Day';
      case AttendanceMode.twoSession:
        return 'Two Sessions Per Day';
    }
  }
}

class ClassModel {
  const ClassModel({
    required this.id,
    required this.className,
    required this.medium,
    required this.whatsappLink,
    required this.institutionId,
    required this.branchId,
    required this.colorValue,
    this.attendanceMode = AttendanceMode.daily,
  });

  final String id;
  final String className;
  final String medium;
  final String whatsappLink;
  final String institutionId;
  final String branchId;
  final int colorValue;
  final AttendanceMode attendanceMode;

  factory ClassModel.fromMap(String id, Map<String, dynamic> data) {
    return ClassModel(
      id: id,
      className: (data['className'] as String?)?.trim() ?? '',
      medium: (data['medium'] as String?)?.trim() ?? '',
      whatsappLink: (data['whatsappLink'] as String?)?.trim() ?? '',
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['branchId'] as String?)?.trim() ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF1976D2,
      attendanceMode: attendanceModeFromString(data['attendanceMode'] as String?) ?? AttendanceMode.daily,
    );
  }

  Map<String, dynamic> toMap() => {
        'className': className.trim(),
        'medium': medium.trim(),
        'whatsappLink': whatsappLink.trim(),
        'institutionId': institutionId.trim(),
        'branchId': branchId.trim(),
        'colorValue': colorValue,
        'attendanceMode': attendanceMode.firestoreValue,
      };

  String get title => '$className ($medium)';
}
