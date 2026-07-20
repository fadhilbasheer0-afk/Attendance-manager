import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/student.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen(
      {super.key, required this.student, required this.branchId});

  final Student student;
  final String branchId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final today = DateTime.now();
    final dayUtc = DateTime.utc(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(student.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Admission: ${student.admissionNumber}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: repo.branchById(branchId),
            builder: (context, snap) {
              final b = snap.data;
              return Card(
                child: ListTile(
                  title: Text(b?.name ?? 'Your branch'),
                  subtitle:
                      Text((b?.location ?? '').isEmpty ? '—' : b!.location),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<AttendanceRecord>>(
            future: repo.attendanceForStudentOnDate(
                studentId: student.id, branchId: branchId, dayUtc: dayUtc),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(minHeight: 3),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return const Text('No attendance recorded yet for today.');
              }
              final r = list.first;
              return Card(
                child: ListTile(
                  title: Text('Status: ${r.status.label}'),
                  subtitle: Text(DateFormat.yMMMEd().format(r.date)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
