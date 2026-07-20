import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/student.dart';
import 'teacher_whatsapp_send_screen.dart';

class TeacherAbsentStudentsScreen extends StatefulWidget {
  const TeacherAbsentStudentsScreen({super.key, required this.branchId});

  final String branchId;

  @override
  State<TeacherAbsentStudentsScreen> createState() =>
      _TeacherAbsentStudentsScreenState();
}

class _TeacherAbsentStudentsScreenState
    extends State<TeacherAbsentStudentsScreen> {
  DateTime _day = DateTime.now();

  DateTime get _dayUtc => DateTime.utc(_day.year, _day.month, _day.day);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final dateLabel = DateFormat.yMMMEd().format(_dayUtc);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absent'),
        actions: [
          IconButton(
              onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
          IconButton(
            tooltip: 'WhatsApp alerts',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => TeacherWhatsAppSendScreen(
                      branchId: widget.branchId, dayUtc: _dayUtc),
                ),
              );
            },
            icon: const Icon(Icons.chat),
          ),
        ],
      ),
      body: StreamBuilder<List<Student>>(
        stream: repo.watchStudentsForBranch(widget.branchId),
        builder: (context, stuSnap) {
          if (!stuSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = stuSnap.data!;
          final byId = {for (final s in students) s.id: s};

          return StreamBuilder<List<AttendanceRecord>>(
            stream: repo.watchAttendanceForBranchOnDate(
                branchId: widget.branchId, dayUtc: _dayUtc),
            builder: (context, attSnap) {
              final records = attSnap.data ?? [];
              final absentIds = records
                  .where((r) => r.status == AttendanceStatus.absent)
                  .map((r) => r.studentId)
                  .toSet();
              final absentStudents = absentIds
                  .map((id) => byId[id])
                  .whereType<Student>()
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              if (absentStudents.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No absent records for $dateLabel.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: absentStudents.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      child: Text(dateLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                    );
                  }
                  final s = absentStudents[i - 1];
                  return Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle: Text('Admission: ${s.admissionNumber}'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => TeacherWhatsAppSendScreen(
                                branchId: widget.branchId,
                                dayUtc: _dayUtc,
                                focusStudentId: s.id,
                              ),
                            ),
                          );
                        },
                        child: const Text('Alert'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
