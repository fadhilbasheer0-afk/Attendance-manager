import 'package:cloud_firestore/cloud_firestore.dart';

class MarkRecord {
  const MarkRecord({
    required this.id,
    required this.studentId,
    required this.institutionId,
    required this.branchId,
    required this.className,
    required this.medium,
    required this.examName,
    required this.subjectMarks,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String institutionId;
  final String branchId;
  final String className;
  final String medium;
  final String examName;
  final Map<String, int> subjectMarks;
  final DateTime updatedAt;

  factory MarkRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawUpdated = data['updatedAt'];
    DateTime updatedAt;
    if (rawUpdated is Timestamp) {
      updatedAt = rawUpdated.toDate();
    } else if (rawUpdated is DateTime) {
      updatedAt = rawUpdated;
    } else {
      updatedAt = DateTime.now();
    }

    final rawMarks = data['subjectMarks'] as Map<String, dynamic>? ?? {};
    final marks = <String, int>{};
    rawMarks.forEach((key, val) {
      if (val is num) {
        marks[key] = val.toInt();
      }
    });

    return MarkRecord(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      institutionId: (data['institutionId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      className: (data['className'] as String?) ?? '',
      medium: (data['medium'] as String?) ?? '',
      examName: (data['examName'] as String?) ?? '',
      subjectMarks: marks,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'institutionId': institutionId,
        'branchId': branchId,
        'className': className,
        'medium': medium,
        'examName': examName,
        'subjectMarks': subjectMarks,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
