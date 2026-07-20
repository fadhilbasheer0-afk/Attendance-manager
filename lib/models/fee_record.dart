import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.amount,
    required this.date,
    required this.receiptNumber,
  });

  final double amount;
  final DateTime date;
  final String receiptNumber;

  factory PaymentHistoryItem.fromMap(Map<String, dynamic> data) {
    final rawDate = data['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else {
      date = DateTime.now();
    }
    return PaymentHistoryItem(
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      receiptNumber: (data['receiptNumber'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'receiptNumber': receiptNumber,
      };
}

class FeeRecord {
  const FeeRecord({
    required this.id,
    required this.studentId,
    required this.institutionId,
    required this.branchId,
    required this.className,
    required this.medium,
    required this.feeCategory,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    required this.dueDate,
    required this.paymentHistory,
  });

  final String id;
  final String studentId;
  final String institutionId;
  final String branchId;
  final String className;
  final String medium;
  final String feeCategory;
  final double totalAmount;
  final double amountPaid;
  final String status;
  final DateTime dueDate;
  final List<PaymentHistoryItem> paymentHistory;

  factory FeeRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDue = data['dueDate'];
    DateTime dueDate;
    if (rawDue is Timestamp) {
      dueDate = rawDue.toDate();
    } else if (rawDue is DateTime) {
      dueDate = rawDue;
    } else {
      dueDate = DateTime.now();
    }

    final rawHistory = data['paymentHistory'] as List<dynamic>? ?? [];
    final history = rawHistory
        .map((e) => PaymentHistoryItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return FeeRecord(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      institutionId: (data['institutionId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      className: (data['className'] as String?) ?? '',
      medium: (data['medium'] as String?) ?? '',
      feeCategory: (data['feeCategory'] as String?) ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: (data['status'] as String?) ?? 'Unpaid',
      dueDate: dueDate,
      paymentHistory: history,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'institutionId': institutionId,
        'branchId': branchId,
        'className': className,
        'medium': medium,
        'feeCategory': feeCategory,
        'totalAmount': totalAmount,
        'amountPaid': amountPaid,
        'status': status,
        'dueDate': Timestamp.fromDate(dueDate),
        'paymentHistory': paymentHistory.map((e) => e.toMap()).toList(),
      };
}
