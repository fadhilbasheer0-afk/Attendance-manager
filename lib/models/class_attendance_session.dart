import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_status.dart';

class ClassAttendanceSession {
  const ClassAttendanceSession({
    required this.id,
    required this.classId,
    required this.institutionId,
    required this.branchId,
    required this.date,
    required this.session,
    required this.status,
    required this.markedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  final String institutionId;
  final String branchId;
  final DateTime date;
  final AttendanceSession session;
  final AttendanceSessionStatus status;
  final String markedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClassAttendanceSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      final d = rawDate.toDate();
      date = DateTime.utc(d.year, d.month, d.day);
    } else if (rawDate is DateTime) {
      date = DateTime.utc(rawDate.year, rawDate.month, rawDate.day);
    } else {
      date = DateTime.utc(1970, 1, 1);
    }
    final rawCreated = data['createdAt'];
    DateTime createdAt;
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else {
      createdAt = DateTime.now();
    }
    final rawUpdated = data['updatedAt'];
    DateTime updatedAt;
    if (rawUpdated is Timestamp) {
      updatedAt = rawUpdated.toDate();
    } else if (rawUpdated is DateTime) {
      updatedAt = rawUpdated;
    } else {
      updatedAt = DateTime.now();
    }
    return ClassAttendanceSession(
      id: doc.id,
      classId: (data['classId'] as String?) ?? '',
      institutionId: (data['institutionId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      date: date,
      session: attendanceSessionFromString(data['session'] as String?) ?? AttendanceSession.daily,
      status: attendanceSessionStatusFromString(data['status'] as String?) ?? AttendanceSessionStatus.notMarked,
      markedBy: (data['markedBy'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'classId': classId,
        'institutionId': institutionId,
        'branchId': branchId,
        'date': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
        'session': session.firestoreValue,
        'status': status.firestoreValue,
        'markedBy': markedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ClassAttendanceSession copyWith({
    String? id,
    String? classId,
    String? institutionId,
    String? branchId,
    DateTime? date,
    AttendanceSession? session,
    AttendanceSessionStatus? status,
    String? markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassAttendanceSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      institutionId: institutionId ?? this.institutionId,
      branchId: branchId ?? this.branchId,
      date: date ?? this.date,
      session: session ?? this.session,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Unique key for class+date+session combination
  String get compositeKey => '${classId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${session.firestoreValue}';
}