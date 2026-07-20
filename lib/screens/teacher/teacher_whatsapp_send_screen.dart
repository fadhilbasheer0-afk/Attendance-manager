import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/student.dart';
import '../../utils/whatsapp.dart';

class TeacherWhatsAppSendScreen extends StatelessWidget {
  const TeacherWhatsAppSendScreen({
    super.key,
    required this.branchId,
    required this.dayUtc,
    this.focusStudentId,
  });

  final String branchId;
  final DateTime dayUtc;
  final String? focusStudentId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final dateLabel = DateFormat.yMMMEd().format(dayUtc);

    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp alerts')),
      body: StreamBuilder<List<Student>>(
        stream: repo.watchStudentsForBranch(branchId),
        builder: (context, stuSnap) {
          if (!stuSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = stuSnap.data!;
          final byId = {for (final s in students) s.id: s};

          return StreamBuilder<List<AttendanceRecord>>(
            stream: repo.watchAttendanceForBranchOnDate(
                branchId: branchId, dayUtc: dayUtc),
            builder: (context, attSnap) {
              final records = attSnap.data ?? [];
              var absentStudents = records
                  .where((r) => r.status == AttendanceStatus.absent)
                  .map((r) => byId[r.studentId])
                  .whereType<Student>()
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              if (focusStudentId != null) {
                absentStudents = absentStudents
                    .where((s) => s.id == focusStudentId)
                    .toList();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Absent — $dateLabel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opens WhatsApp with this prefilled message:\n"$kAbsentAlertMessage"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (absentStudents.isEmpty)
                    const Text('No absent students for this selection.')
                  else
                    ...absentStudents.map(
                      (s) => Card(
                        child: ListTile(
                          title: Text(s.name),
                          subtitle: Text('Mobile: ${s.mobile}'),
                          trailing: FilledButton(
                            onPressed: s.mobile.trim().isEmpty
                                ? null
                                : () async {
                                    final ok =
                                        await openWhatsAppAbsentAlert(s.mobile);
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Could not open WhatsApp')),
                                      );
                                    }
                                  },
                            child: const Text('Send'),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
