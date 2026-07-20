import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/student.dart';
import '../../providers/session_provider.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    super.key,
    required this.student,
    required this.branchId,
    required this.onOpenBranchPicker,
  });

  final Student student;
  final String branchId;
  final VoidCallback onOpenBranchPicker;

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundImage: student.photoUrl.isNotEmpty
                  ? NetworkImage(student.photoUrl)
                  : null,
              child: student.photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 52)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(student.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Admission: ${student.admissionNumber}'),
                  const SizedBox(height: 8),
                  Text(
                      'Class: ${student.className.isEmpty ? 'N/A' : student.className}'),
                  const SizedBox(height: 8),
                  Text(
                      'Medium: ${student.medium.isEmpty ? 'N/A' : student.medium}'),
                  const SizedBox(height: 8),
                  Text('Mobile: ${student.mobile}'),
                  const SizedBox(height: 8),
                  Text('Student ID: ${student.id}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Branch?>(
            stream: context.read<SessionProvider>().watchBranchById(branchId),
            builder: (context, snap) {
              final b = snap.data;
              return Card(
                child: ListTile(
                  title: Text('Branch: ${b?.name ?? branchId}'),
                  subtitle: const Text('Assigned institution'),
                  trailing: const Icon(Icons.lock_outline),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Signed-in account'),
              subtitle: Text(u?.email ?? u?.phoneNumber ?? '—'),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<SessionProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
