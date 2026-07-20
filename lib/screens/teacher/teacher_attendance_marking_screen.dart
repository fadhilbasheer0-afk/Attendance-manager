import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/student.dart';
import 'teacher_whatsapp_send_screen.dart';

class TeacherAttendanceMarkingScreen extends StatefulWidget {
  const TeacherAttendanceMarkingScreen({super.key, required this.branchId});

  final String branchId;

  @override
  State<TeacherAttendanceMarkingScreen> createState() =>
      _TeacherAttendanceMarkingScreenState();
}

class _TeacherAttendanceMarkingScreenState
    extends State<TeacherAttendanceMarkingScreen> {
  DateTime _day = DateTime.now();
  String? _selectedClass;
  bool _busy = false;

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

  Future<void> _setStatus(
    FirestoreRepository repo,
    Student student,
    AttendanceStatus status,
  ) async {
    await repo.upsertAttendance(
      studentId: student.id,
      branchId: widget.branchId,
      dayUtc: _dayUtc,
      status: status,
    );
  }

  Future<void> _markAll(FirestoreRepository repo, List<Student> students,
      AttendanceStatus status) async {
    setState(() => _busy = true);
    try {
      await repo.bulkUpsertAttendance(
        studentIds: students.map((s) => s.id).toList(),
        branchId: widget.branchId,
        dayUtc: _dayUtc,
        status: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final dateLabel = DateFormat.yMMMEd().format(_dayUtc);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pick date',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Date: $dateLabel',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: repo.watchStudentsForBranch(widget.branchId),
              builder: (context, stuSnap) {
                if (stuSnap.hasError) {
                  return Center(child: Text('Error: ${stuSnap.error}'));
                }
                if (!stuSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = stuSnap.data!;
                return StreamBuilder<List<AttendanceRecord>>(
                  stream: repo.watchAttendanceForBranchOnDate(
                      branchId: widget.branchId, dayUtc: _dayUtc),
                  builder: (context, attSnap) {
                    final records = attSnap.data ?? [];
                    final byStudent = {for (final r in records) r.studentId: r};

                    if (students.isEmpty) {
                      return const Center(
                          child: Text('No students in this branch.'));
                    }

                    // Key = "ClassName — Medium" so each medium is a separate group
                    final classesMap = <String, int>{};
                    for (final s in students) {
                      final cls =
                          s.className.isEmpty ? 'Unassigned' : s.className;
                      final med = s.medium.isEmpty ? 'Unknown' : s.medium;
                      final c = '$cls — $med Medium';
                      classesMap[c] = (classesMap[c] ?? 0) + 1;
                    }
                    final classes = classesMap.keys.toList()..sort();

                    if (_selectedClass == null) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: classes.length,
                        itemBuilder: (context, i) {
                          final c = classes[i];
                          return Card(
                            child: ListTile(
                              title: Text(c,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('${classesMap[c]} Students'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => setState(() => _selectedClass = c),
                            ),
                          );
                        },
                      );
                    }

                    final displayedStudents = students.where((s) {
                      final cls =
                          s.className.isEmpty ? 'Unassigned' : s.className;
                      final med = s.medium.isEmpty ? 'Unknown' : s.medium;
                      return '$cls — $med Medium' == _selectedClass;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () =>
                                        setState(() => _selectedClass = null),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedClass!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text('${displayedStudents.length} Students'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _markAll(
                                            repo,
                                            displayedStudents,
                                            AttendanceStatus.present),
                                    icon: const Icon(Icons.check_circle_outline,
                                        color: Colors.green, size: 20),
                                    label: const Text('Mark All Present',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _markAll(
                                            repo,
                                            displayedStudents,
                                            AttendanceStatus.absent),
                                    icon: const Icon(Icons.cancel_outlined,
                                        color: Colors.red, size: 20),
                                    label: const Text('Mark All Absent',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            itemCount: displayedStudents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final s = displayedStudents[i];
                              final current = byStudent[s.id]?.status;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 2),
                                      Text('Admission: ${s.admissionNumber}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _StatusButton(
                                            label: 'Present',
                                            icon: Icons.check,
                                            color: Colors.green,
                                            selected: current ==
                                                AttendanceStatus.present,
                                            onTap: () => _setStatus(repo, s,
                                                AttendanceStatus.present),
                                          ),
                                          const SizedBox(width: 8),
                                          _StatusButton(
                                            label: 'Late',
                                            icon: Icons.access_time,
                                            color: Colors.orange,
                                            selected: current ==
                                                AttendanceStatus.late,
                                            onTap: () => _setStatus(
                                                repo, s, AttendanceStatus.late),
                                          ),
                                          const SizedBox(width: 8),
                                          _StatusButton(
                                            label: 'Absent',
                                            icon: Icons.close,
                                            color: Colors.red,
                                            selected: current ==
                                                AttendanceStatus.absent,
                                            onTap: () async {
                                              await _setStatus(repo, s,
                                                  AttendanceStatus.absent);
                                              if (!context.mounted) return;
                                              final go = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                      'Marked absent'),
                                                  content: const Text(
                                                      'Send a WhatsApp alert to the parent?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child: const Text(
                                                            'Not now')),
                                                    FilledButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, true),
                                                        child: const Text(
                                                            'Send alert')),
                                                  ],
                                                ),
                                              );
                                              if (go == true &&
                                                  context.mounted) {
                                                await Navigator.of(context)
                                                    .push<void>(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        TeacherWhatsAppSendScreen(
                                                      branchId: widget.branchId,
                                                      dayUtc: _dayUtc,
                                                      focusStudentId: s.id,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(icon, color: selected ? Colors.white : color, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : color,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
