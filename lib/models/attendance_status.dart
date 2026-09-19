enum AttendanceStatus { present, absent, late, noClass }

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
      case AttendanceStatus.noClass:
        return 'No Class';
    }
  }

  bool get countsForPercentage {
    return this == AttendanceStatus.present || this == AttendanceStatus.absent || this == AttendanceStatus.late;
  }
}

AttendanceStatus? attendanceStatusFromString(String? v) {
  if (v == null) return null;
  for (final s in AttendanceStatus.values) {
    if (s.name == v) return s;
  }
  return null;
}

enum AttendanceSession { daily, fn, an }

extension AttendanceSessionX on AttendanceSession {
  String get firestoreValue => name.toLowerCase();

  String get label {
    switch (this) {
      case AttendanceSession.daily:
        return 'Daily';
      case AttendanceSession.fn:
        return 'FN – Forenoon';
      case AttendanceSession.an:
        return 'AN – Afternoon';
    }
  }

  String get shortLabel {
    switch (this) {
      case AttendanceSession.daily:
        return 'Daily';
      case AttendanceSession.fn:
        return 'FN';
      case AttendanceSession.an:
        return 'AN';
    }
  }
}

AttendanceSession? attendanceSessionFromString(String? v) {
  if (v == null) return null;
  final lower = v.toLowerCase();
  for (final s in AttendanceSession.values) {
    if (s.name.toLowerCase() == lower) return s;
  }
  return null;
}

enum AttendanceSessionStatus { notMarked, completed, noClass }

extension AttendanceSessionStatusX on AttendanceSessionStatus {
  String get firestoreValue => name;

  String get label {
    switch (this) {
      case AttendanceSessionStatus.notMarked:
        return 'Not Marked';
      case AttendanceSessionStatus.completed:
        return 'Completed';
      case AttendanceSessionStatus.noClass:
        return 'No Class';
    }
  }
}

AttendanceSessionStatus? attendanceSessionStatusFromString(String? v) {
  if (v == null) return null;
  for (final s in AttendanceSessionStatus.values) {
    if (s.name == v) return s;
  }
  return null;
}
