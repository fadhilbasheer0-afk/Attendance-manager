import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/firestore_repository.dart';
import '../../models/student.dart';

class TeacherStudentListScreen extends StatefulWidget {
  const TeacherStudentListScreen({
    super.key,
    required this.branchId,
    required this.onTakeAttendance,
  });

  final String branchId;
  final VoidCallback onTakeAttendance;

  @override
  State<TeacherStudentListScreen> createState() =>
      _TeacherStudentListScreenState();
}

class _TeacherStudentListScreenState extends State<TeacherStudentListScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          TextButton.icon(
            onPressed: widget.onTakeAttendance,
            icon: const Icon(Icons.fact_check),
            label: const Text('Attendance'),
          ),
        ],
      ),
      body: StreamBuilder<List<Student>>(
        stream: repo.watchStudentsForBranch(widget.branchId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snap.data!;
          if (students.isEmpty) {
            return const Center(child: Text('No students in this branch yet.'));
          }

          // Key = "ClassName — Medium" so English/Malayalam sections are separate
          final classesMap = <String, int>{};
          for (final s in students) {
            final cls = s.className.isEmpty ? 'Unassigned' : s.className;
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
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${classesMap[c]} Students'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedClass = c),
                  ),
                );
              },
            );
          }

          final displayedStudents = students.where((s) {
            final cls = s.className.isEmpty ? 'Unassigned' : s.className;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedClass = null),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Class: $_selectedClass',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('${displayedStudents.length} Students'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: displayedStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = displayedStudents[i];
                    return Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                            'Admission: ${s.admissionNumber} | Mobile: ${s.mobile}\nMedium: ${s.medium.isEmpty ? 'N/A' : s.medium}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () async {
                            final uri = Uri.parse('tel:${s.mobile}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
