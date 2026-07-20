import 'package:flutter/material.dart';

import 'institution_admin_screen.dart';
import 'admin_profile_screen.dart';

class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const InstitutionAdminScreen(),
      const AdminProfileScreen(),
    ];
    final selected = _index.clamp(0, pages.length - 1);
    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: pages[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Admin'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
