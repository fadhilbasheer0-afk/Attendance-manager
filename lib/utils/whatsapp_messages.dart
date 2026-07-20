import 'package:intl/intl.dart';

String buildFeeWhatsAppMessage({
  required String studentName,
  required String className,
  required String division,
  required String branchName,
  required String institutionName,
  required double totalFee,
  required double pendingFee,
  DateTime? lastDate,
}) {
  final resolvedStudentName = _cleanText(studentName) ?? 'N/A';
  final resolvedClassName = _cleanText(className) ?? 'N/A';
  final resolvedDivision = _cleanText(division) ?? 'N/A';
  final resolvedBranchName = _cleanText(branchName) ?? 'N/A';
  final resolvedInstitutionName = _cleanText(institutionName) ?? 'N/A';
  final resolvedLastDate = lastDate == null ? 'N/A' : DateFormat('M/d/yyyy').format(lastDate);

  return '''
DEAR PARENT,

✨ Wishing your family a great day.

⏰ This is an official reminder from $resolvedInstitutionName to inform you about the PENDING FEE of your child till this month.

NAME OF STUDENT: $resolvedStudentName  
CLASS: $resolvedClassName  
DIVISION: $resolvedDivision
BRANCH: $resolvedBranchName  
TOTAL FEE: ₹${totalFee.toStringAsFixed(0)}
PENDING FEE: ₹${pendingFee.toStringAsFixed(0)}
LAST DATE FOR PAYMENT: $resolvedLastDate

Kindly inform us if there any concerns.

Regards,  
$resolvedInstitutionName
''';
}

String buildMarksWhatsAppMessage({
  required String examName,
  required String studentName,
  required String className,
  required String division,
  required String branchName,
  required String admissionNumber,
  required String institutionName,
  required Map<String, int> subjectMarks,
  required int totalMarksPerSubject,
  String? rank,
}) {
  final resolvedExamName = _cleanText(examName) ?? 'the selected exam';
  final resolvedStudentName = _cleanText(studentName) ?? 'N/A';
  final resolvedClassName = _cleanText(className) ?? 'N/A';
  final resolvedDivision = _cleanText(division) ?? 'N/A';
  final resolvedBranchName = _cleanText(branchName) ?? 'N/A';
  final resolvedAdmissionNumber = _cleanText(admissionNumber) ?? 'N/A';
  final resolvedInstitutionName = _cleanText(institutionName) ?? 'N/A';
  final resolvedRank = rank != null && rank.isNotEmpty ? rank : '-';

  final scoredTotal = subjectMarks.values.fold<int>(0, (sum, value) => sum + value);
  final maxTotal = subjectMarks.isEmpty ? 0 : subjectMarks.length * totalMarksPerSubject;
  final percentage = maxTotal == 0 ? 0.0 : (scoredTotal / maxTotal) * 100;

  return '''
DEAR PARENT,

✨ Wishing your family a great day.

⏰ This is an official reminder from $resolvedInstitutionName to inform you about the marks your child obtained in the $resolvedExamName we conducted.

NAME OF THE STUDENT: $resolvedStudentName  
CLASS: $resolvedClassName  
DIVISION: $resolvedDivision
BRANCH: $resolvedBranchName
ADMISSION NUMBER: $resolvedAdmissionNumber

🏆SUBJECTS & MARKS:

ENGLISH: ${_subjectMark(subjectMarks, 'English')}
HINDI: ${_subjectMark(subjectMarks, 'Hindi')}
PHYSICS: ${_subjectMark(subjectMarks, 'Physics')}
CHEMISTRY: ${_subjectMark(subjectMarks, 'Chemistry')}
BIOLOGY: ${_subjectMark(subjectMarks, 'Biology')}
MATHS: ${_subjectMark(subjectMarks, 'Maths', aliases: const ['Mathematics'])}
GEOGRAPHY: ${_subjectMark(subjectMarks, 'Geography')}
HISTORY: ${_subjectMark(subjectMarks, 'History')}
LANG 1: ${_subjectMark(subjectMarks, 'Lang 1', aliases: const ['Language 1', 'LANG 1'])}
LANG 2: ${_subjectMark(subjectMarks, 'Lang 2', aliases: const ['Language 2', 'LANG 2'])}
IT: ${_subjectMark(subjectMarks, 'IT', aliases: const ['Information Technology', 'Computer'])}
MAXIMUM MARKS: $maxTotal
MARKS OBTAINED: $scoredTotal
PERCENTAGE: ${percentage.toStringAsFixed(2)}%
RANK: $resolvedRank


Let us know your valuable response, suggestions & comments regarding the score sheet as a reply of this message.

Regards,  
$resolvedInstitutionName
''';
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  return trimmed != null && trimmed.isNotEmpty ? trimmed : null;
}

String _subjectMark(
  Map<String, int> subjectMarks,
  String subject, {
  List<String> aliases = const [],
}) {
  final wanted = [subject, ...aliases].map((entry) => entry.toLowerCase().trim());
  for (final entry in subjectMarks.entries) {
    if (wanted.contains(entry.key.toLowerCase().trim())) {
      return entry.value.toString();
    }
  }
  return '-';
}
