import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../providers/session_provider.dart';
import '../admin/institution_admin_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherHomeShell extends StatefulWidget {
  const TeacherHomeShell({super.key});

  @override
  State<TeacherHomeShell> createState() => _TeacherHomeShellState();
}

class _TeacherHomeShellState extends State<TeacherHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().session!;
    final isAppAdmin = context.watch<SessionProvider>().isAppAdmin;
    final branchId = session.branchId!;

    final pages = <Widget>[
      TeacherDashboardScreen(branchId: branchId),
      if (isAppAdmin) const InstitutionAdminScreen(),
      TeacherProfileScreen(
        branchId: branchId,
        onOpenBranchPicker: () => _openBranchPicker(context),
      ),
    ];
    final selectedIndex = _index >= pages.length ? pages.length - 1 : _index;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          if (isAppAdmin)
            const NavigationDestination(
                icon: Icon(Icons.account_balance_outlined),
                selectedIcon: Icon(Icons.account_balance),
                label: 'Admin'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _openBranchPicker(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TeacherBranchPickerPage()),
    );
  }
}

class TeacherBranchPickerPage extends StatelessWidget {
  const TeacherBranchPickerPage({super.key});

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
