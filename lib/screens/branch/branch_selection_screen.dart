import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Select branch')),
      body: StreamBuilder(
        stream: session.watchBranches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Could not load branches.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final branches = snapshot.data!;
          if (branches.isEmpty) {
            return const Center(child: Text('No branches configured yet.'));
          }
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context
                        .read<SessionProvider>()
                        .setBranchForCurrentUser(b.id);
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
