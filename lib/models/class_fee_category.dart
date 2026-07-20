import 'package:cloud_firestore/cloud_firestore.dart';

class ClassFeeCategory {
  const ClassFeeCategory({
    required this.id,
    required this.branchId,
    required this.className,
    required this.medium,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String branchId;
  final String className;
  final String medium;
  final String name;
  final DateTime createdAt;

  factory ClassFeeCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawCreated = data['createdAt'];
    DateTime createdAt;
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else {
      createdAt = DateTime.now();
    }

    return ClassFeeCategory(
      id: doc.id,
      branchId: (data['branchId'] as String?)?.trim() ?? '',
      className: (data['className'] as String?)?.trim() ?? '',
      medium: (data['medium'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'branchId': branchId.trim(),
        'className': className.trim(),
        'medium': medium.trim(),
        'name': name.trim(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
