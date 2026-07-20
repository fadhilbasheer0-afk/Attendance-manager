enum AttendanceStatus { present, absent, late }

extension AttendanceStatusX on AttendanceStatus {
  String get firestoreValue => name;

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

AttendanceStatus? attendanceStatusFromString(String? v) {
  if (v == null) return null;
  for (final s in AttendanceStatus.values) {
    if (s.name == v) return s;
  }
  return null;
}
