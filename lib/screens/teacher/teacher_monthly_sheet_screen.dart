import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/student.dart';

/// A key that uniquely identifies a class group: className + medium.
class _ClassKey {
  const _ClassKey(this.className, this.medium);
  final String className;
  final String medium;

  String get displayName =>
      '${className.isEmpty ? "Unassigned" : className} — ${medium.isEmpty ? "Unknown" : medium} Medium';

  @override
  bool operator ==(Object other) =>
      other is _ClassKey &&
      other.className == className &&
      other.medium == medium;

  @override
  int get hashCode => Object.hash(className, medium);
}

class TeacherMonthlySheetScreen extends StatefulWidget {
  const TeacherMonthlySheetScreen({super.key, required this.branchId});

  final String branchId;

  @override
  State<TeacherMonthlySheetScreen> createState() =>
      _TeacherMonthlySheetScreenState();
}

class _TeacherMonthlySheetScreenState extends State<TeacherMonthlySheetScreen> {
  late int _year;
  late int _month;
  _ClassKey? _selectedClass;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
        if (_month == 1) {
          _month = 12;
          _year--;
        } else {
          _month--;
        }
        _selectedClass = null;
      });

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _selectedClass = null;
    });
  }

  String get _monthLabel => DateFormat.yMMMM().format(DateTime(_year, _month));

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Sheet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(_monthLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Student>>(
        stream: repo.watchStudentsForBranch(widget.branchId),
        builder: (context, stuSnap) {
          if (stuSnap.hasError) {
            return Center(child: Text('Error: ${stuSnap.error}'));
          }
          if (!stuSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = stuSnap.data!;
          if (students.isEmpty) {
            return const Center(child: Text('No students in this branch.'));
          }

          // Build unique class groups from students (className + medium)
          final groupMap = <_ClassKey, List<Student>>{};
          for (final s in students) {
            final key = _ClassKey(s.className, s.medium);
            groupMap.putIfAbsent(key, () => []).add(s);
          }
          final groups = groupMap.keys.toList()
            ..sort((a, b) {
              final c = a.className.compareTo(b.className);
              return c != 0 ? c : a.medium.compareTo(b.medium);
            });

          return StreamBuilder<List<AttendanceRecord>>(
            stream: repo.watchAttendanceForBranchInMonth(
              branchId: widget.branchId,
              year: _year,
              month: _month,
            ),
            builder: (context, attSnap) {
              final records = attSnap.data ?? [];

              // Map: studentId -> day -> AttendanceStatus
              final attMap = <String, Map<int, AttendanceStatus>>{};
              for (final r in records) {
                attMap.putIfAbsent(r.studentId,
                    () => <int, AttendanceStatus>{})[r.date.day] = r.status;
              }

              if (_selectedClass == null) {
                // Class picker list
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final key = groups[i];
                    final count = groupMap[key]!.length;

                    // Summary stats for this class this month
                    int totalPresent = 0, totalAbsent = 0, totalLate = 0;
                    for (final s in groupMap[key]!) {
                      final dayMap = attMap[s.id] ?? {};
                      for (final status in dayMap.values) {
                        if (status == AttendanceStatus.present) {
                          totalPresent++;
                        } else if (status == AttendanceStatus.absent) {
                          totalAbsent++;
                        } else if (status == AttendanceStatus.late) {
                          totalLate++;
                        }
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            key.className.isEmpty
                                ? '?'
                                : key.className
                                        .replaceAll(RegExp(r'[^0-9]'), '')
                                        .isNotEmpty
                                    ? key.className
                                        .replaceAll(RegExp(r'[^0-9]'), '')
                                    : key.className[0].toUpperCase(),
                            style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(key.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '$count students  •  ✅$totalPresent  ❌$totalAbsent  🕐$totalLate',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setState(() => _selectedClass = key),
                      ),
                    );
                  },
                );
              }

              // Full sheet for selected class
              final classStudents = groupMap[_selectedClass!] ?? [];
              classStudents.sort((a, b) => a.name.compareTo(b.name));
              final days = List.generate(_daysInMonth, (i) => i + 1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header bar
                  Container(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () =>
                              setState(() => _selectedClass = null),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedClass!.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('${classStudents.length} students'),
                      ],
                    ),
                  ),
                  // Legend
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 16,
                      children: [
                        _LegendDot(
                            color: Colors.green.shade600, label: 'Present'),
                        _LegendDot(color: Colors.red.shade400, label: 'Absent'),
                        _LegendDot(
                            color: Colors.orange.shade400, label: 'Late'),
                        _LegendDot(
                            color: Colors.grey.shade300, label: 'Not marked'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable table
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 44,
                          columnSpacing: 6,
                          horizontalMargin: 12,
                          columns: [
                            const DataColumn(label: Text('Name')),
                            ...days.map(
                              (d) => DataColumn(
                                label: SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$d',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                            const DataColumn(label: Text('P')),
                            const DataColumn(label: Text('A')),
                            const DataColumn(label: Text('L')),
                          ],
                          rows: classStudents.map((s) {
                            final dayMap = attMap[s.id] ?? {};
                            int presentCount = 0,
                                absentCount = 0,
                                lateCount = 0;
                            final cells = days.map((d) {
                              final status = dayMap[d];
                              Color? color;
                              String symbol = '';
                              if (status == AttendanceStatus.present) {
                                color = Colors.green.shade600;
                                symbol = 'P';
                                presentCount++;
                              } else if (status == AttendanceStatus.absent) {
                                color = Colors.red.shade400;
                                symbol = 'A';
                                absentCount++;
                              } else if (status == AttendanceStatus.late) {
                                color = Colors.orange.shade400;
                                symbol = 'L';
                                lateCount++;
                              }
                              return DataCell(
                                Container(
                                  width: 24,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: color?.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    symbol,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color ?? Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList();

                            return DataRow(cells: [
                              DataCell(SizedBox(
                                width: 130,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              )),
                              ...cells,
                              DataCell(Text('$presentCount',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text('$absentCount',
                                  style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text('$lateCount',
                                  style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold))),
                            ]);
                          }).toList(),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
