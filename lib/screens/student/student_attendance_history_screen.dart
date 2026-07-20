import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';

class StudentAttendanceHistoryScreen extends StatelessWidget {
  const StudentAttendanceHistoryScreen(
      {super.key, required this.studentId, required this.branchId});

  final String studentId;
  final String branchId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance history')),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: repo.watchAttendanceHistoryForStudent(
            studentId: studentId, branchId: branchId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('No attendance history yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              return Card(
                child: ListTile(
                  title: Text(r.status.label),
                  subtitle: Text(DateFormat.yMMMEd().format(r.date)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
