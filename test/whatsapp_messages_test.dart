import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_manager/utils/whatsapp_messages.dart';

void main() {
  test('buildFeeWhatsAppMessage includes student and fee details', () {
    final message = buildFeeWhatsAppMessage(
      studentName: 'Aarav',
      className: '10A',
      division: 'A',
      branchName: 'Main Branch',
      totalFee: 12000,
      pendingFee: 4000,
      lastDate: DateTime(2026, 7, 10),
    );

    expect(message, contains('DEAR PARENT,'));
    expect(message, contains('NAME OF STUDENT: Aarav'));
    expect(message, contains('CLASS: 10A'));
    expect(message, contains('DIVISION: A'));
    expect(message, contains('BRANCH: Main Branch'));
    expect(message, contains('TOTAL FEE: ₹12000'));
    expect(message, contains('PENDING FEE: ₹4000'));
    expect(message, contains('LAST DATE FOR PAYMENT: 7/10/2026'));
  });

  test('buildMarksWhatsAppMessage includes exam and subject details', () {
    final message = buildMarksWhatsAppMessage(
      examName: 'Unit Test',
      studentName: 'Aarav',
      className: '10A',
      division: 'A',
      branchName: 'Main Branch',
      admissionNumber: '1234',
      subjectMarks: {
        'English': 90,
        'Maths': 80,
      },
      totalMarksPerSubject: 100,
    );

    expect(message, contains('NAME OF THE STUDENT: Aarav'));
    expect(message, contains('CLASS: 10A'));
    expect(message, contains('DIVISION: A'));
    expect(message, contains('BRANCH: Main Branch'));
    expect(message, contains('ADMISSION NUMBER: 1234'));
    expect(message, contains('in the Unit Test we conducted.'));
    expect(message, contains('ENGLISH: 90'));
    expect(message, contains('MATHS: 80'));
    expect(message, contains('MAXIMUM MARKS: 200'));
    expect(message, contains('MARKS OBTAINED: 170'));
    expect(message, contains('PERCENTAGE: 85.00%'));
  });
}
