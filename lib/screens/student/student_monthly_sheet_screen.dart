import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';

class StudentMonthlySheetScreen extends StatefulWidget {
  const StudentMonthlySheetScreen(
      {super.key, required this.studentId, required this.branchId});

  final String studentId;
  final String branchId;

  @override
  State<StudentMonthlySheetScreen> createState() =>
      _StudentMonthlySheetScreenState();
}

class _StudentMonthlySheetScreenState extends State<StudentMonthlySheetScreen> {
  late int _year;
  late int _month;

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
        title: const Text('My Attendance Sheet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth),
                Text(
                  _monthLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: repo.watchAttendanceForBranchInMonth(
            branchId: widget.branchId, year: _year, month: _month),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snap.data!;
          final myRecords =
              allRecords.where((r) => r.studentId == widget.studentId).toList();
          final attByDay = {for (final r in myRecords) r.date.day: r.status};

          int present = 0, absent = 0, lateCount = 0;
          for (final st in attByDay.values) {
            if (st == AttendanceStatus.present) present++;
            if (st == AttendanceStatus.absent) absent++;
            if (st == AttendanceStatus.late) lateCount++;
          }

          final firstWeekday =
              DateTime(_year, _month, 1).weekday; // 1=Mon..7=Sun
          final daysBefore = firstWeekday == 7 ? 0 : firstWeekday;
          final totalGridItems = daysBefore + _daysInMonth;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                          label: 'Present',
                          count: present,
                          color: Colors.green),
                      _Stat(label: 'Absent', count: absent, color: Colors.red),
                      _Stat(
                          label: 'Late',
                          count: lateCount,
                          color: Colors.orange),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _DayHeader('S'),
                    _DayHeader('M'),
                    _DayHeader('T'),
                    _DayHeader('W'),
                    _DayHeader('T'),
                    _DayHeader('F'),
                    _DayHeader('S'),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalGridItems,
                  itemBuilder: (context, index) {
                    if (index < daysBefore) return const SizedBox();
                    final day = index - daysBefore + 1;
                    final status = attByDay[day];

                    Color? bgColor;
                    Color textColor = colorScheme.onSurface;
                    String label = '$day';

                    if (status == AttendanceStatus.present) {
                      bgColor = Colors.green.shade100;
                      textColor = Colors.green.shade800;
                    } else if (status == AttendanceStatus.absent) {
                      bgColor = Colors.red.shade100;
                      textColor = Colors.red.shade800;
                    } else if (status == AttendanceStatus.late) {
                      bgColor = Colors.orange.shade100;
                      textColor = Colors.orange.shade800;
                    } else {
                      bgColor = colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3);
                      textColor = colorScheme.onSurfaceVariant;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: status != null
                            ? Border.all(
                                color: textColor.withValues(alpha: 0.5),
                                width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  children: [
                    _LegendItem(color: Colors.green, label: 'Present'),
                    _LegendItem(color: Colors.red, label: 'Absent'),
                    _LegendItem(color: Colors.orange, label: 'Late'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );
}
