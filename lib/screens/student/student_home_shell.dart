import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../providers/session_provider.dart';
import 'student_monthly_sheet_screen.dart';
import 'student_profile_screen.dart';

class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({super.key});

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().session!;
    final student = session.student!;
    final branchId = session.branchId!;

    final pages = <Widget>[
      StudentMonthlySheetScreen(studentId: student.id, branchId: branchId),
      StudentProfileScreen(
        student: student,
        branchId: branchId,
        onOpenBranchPicker: () => _openBranchPicker(context),
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Attendance'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _openBranchPicker(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _StudentBranchPickerPage()),
    );
  }
}

class _StudentBranchPickerPage extends StatelessWidget {
  const _StudentBranchPickerPage();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Change branch')),
      body: StreamBuilder<List<Branch>>(
        stream: session.watchBranchesForCurrentInstitution(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final branches = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = branches[i];
              return Card(
                child: ListTile(
                  title: Text(b.name),
                  subtitle: Text(b.location),
                  onTap: () async {
                    await context
                        .read<SessionProvider>()
                        .setBranchForCurrentUser(b.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
