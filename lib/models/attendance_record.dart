import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_status.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.institutionId,
    required this.branchId,
    required this.date,
    required this.session,
    required this.status,
    required this.markedBy,
  });

  final String id;
  final String studentId;
  final String institutionId;
  final String branchId;
  final DateTime date;
  final AttendanceSession session;
  final AttendanceStatus status;
  final String markedBy;

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final raw = data['date'];
    DateTime date;
    if (raw is Timestamp) {
      final d = raw.toDate();
      date = DateTime.utc(d.year, d.month, d.day);
    } else if (raw is DateTime) {
      date = DateTime.utc(raw.year, raw.month, raw.day);
    } else {
      date = DateTime.utc(1970, 1, 1);
    }
    return AttendanceRecord(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      institutionId: (data['institutionId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      date: date,
      session: attendanceSessionFromString(data['session'] as String?) ?? AttendanceSession.daily,
      status: attendanceStatusFromString(data['status'] as String?) ??
          AttendanceStatus.present,
      markedBy: (data['markedBy'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'institutionId': institutionId,
        'branchId': branchId,
        'date':
            Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
        'session': session.firestoreValue,
        'status': status.firestoreValue,
        'markedBy': markedBy,
      };

  /// Creates a copy with updated fields
  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? institutionId,
    String? branchId,
    DateTime? date,
    AttendanceSession? session,
    AttendanceStatus? status,
    String? markedBy,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      institutionId: institutionId ?? this.institutionId,
      branchId: branchId ?? this.branchId,
      date: date ?? this.date,
      session: session ?? this.session,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
    );
  }
}
