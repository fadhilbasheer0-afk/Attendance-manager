import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/branch.dart';
import '../../models/institution.dart';

class InstitutionAdminScreen extends StatelessWidget {
  const InstitutionAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutions'),
        actions: [
          IconButton(
            tooltip: 'Add institution',
            icon: const Icon(Icons.add_business),
            onPressed: () => _showInstitutionDialog(context, repo),
          ),
        ],
      ),
      body: StreamBuilder<List<Institution>>(
        stream: repo.watchInstitutions(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text('Could not load institutions.\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final institutions = snap.data!;
          if (institutions.isEmpty) {
            return _EmptyInstitutions(
                onAdd: () => _showInstitutionDialog(context, repo));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: institutions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final institution = institutions[index];
              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.account_balance,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(institution.name.isEmpty
                      ? institution.id
                      : institution.name),
                  subtitle: Text([
                    if (institution.location.isNotEmpty) institution.location,
                    institution.id,
                  ].join(' • ')),
                  children: [
                    StreamBuilder<List<Branch>>(
                      stream: repo.watchBranchesForInstitution(institution.id),
                      builder: (context, branchSnap) {
                        final branches = branchSnap.data ?? [];
                        return Column(
                          children: [
                            for (final branch in branches)
                              ListTile(
                                leading:
                                    const Icon(Icons.location_city_outlined),
                                title: Text(branch.name),
                                subtitle: Text(branch.location),
                              ),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Add branch'),
                              onTap: () =>
                                  _showBranchDialog(context, repo, institution),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.vpn_key_outlined),
                              title: const Text('Institution password'),
                              subtitle: Text(institution.institutionPassword.isNotEmpty ? institution.institutionPassword : '—'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings_outlined),
                              title: const Text('Teacher password'),
                              subtitle: Text(institution.teacherPassword.isNotEmpty ? institution.teacherPassword : '—'),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () => _showEditInstitutionDialog(context, repo, institution),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Institution?'),
                                        content: Text('Delete ${institution.name} (${institution.id}) and its branches?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await repo.deleteInstitution(institution.id);
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institution deleted')));
                                      } catch (e) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () => _showInstitutionDialog(context, repo),
      ),
    );
  }

  void _showInstitutionDialog(BuildContext context, FirestoreRepository repo) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final institutionPasswordController = TextEditingController();
    final teacherPasswordController = TextEditingController();
    final branchesController = TextEditingController(text: 'Main');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add institution'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution name',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter institution name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: idController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Institution code',
                      hintText: 'ABC_SCHOOL',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter institution code'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: institutionPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Institution password',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    obscureText: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter institution password'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: teacherPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Teacher password',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    obscureText: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter teacher password'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: branchesController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Branches',
                      hintText: 'Main\nTown Branch\nEvening Center',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter at least one branch'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final branches = branchesController.text
                    .split(RegExp(r'[\n,]'))
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .toList();
                try {
                  await repo.addInstitution(
                    id: idController.text,
                    name: nameController.text,
                    location: locationController.text,
                    institutionPassword: institutionPasswordController.text,
                    teacherPassword: teacherPasswordController.text,
                    branchNames: branches,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Institution added.')),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Could not save institution: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditInstitutionDialog(BuildContext context, FirestoreRepository repo, Institution institution) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: institution.id);
    final nameController = TextEditingController(text: institution.name);
    final locationController = TextEditingController(text: institution.location);
    final institutionPasswordController = TextEditingController(text: institution.institutionPassword);
    final teacherPasswordController = TextEditingController(text: institution.teacherPassword);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit institution'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Institution name',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter institution name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: idController,
                    enabled: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Institution code',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: institutionPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Institution password',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    obscureText: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter institution password'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: teacherPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Teacher password',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    obscureText: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter teacher password'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                try {
                  final newInstPass = institutionPasswordController.text.trim();
                  final newTeacherPass = teacherPasswordController.text.trim();
                  await repo.updateInstitution(
                    id: institution.id,
                    name: nameController.text,
                    location: locationController.text,
                    institutionPassword: newInstPass != institution.institutionPassword ? newInstPass : null,
                    teacherPassword: newTeacherPass != institution.teacherPassword ? newTeacherPass : null,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institution updated.')));
                } catch (e) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Could not update institution: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showBranchDialog(
      BuildContext context, FirestoreRepository repo, Institution institution) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController =
        TextEditingController(text: institution.location);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add branch to ${institution.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter branch name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              await repo.addBranch(
                institutionId: institution.id,
                name: nameController.text,
                location: locationController.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EmptyInstitutions extends StatelessWidget {
  const _EmptyInstitutions({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No institutions yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add institution'),
            ),
          ],
        ),
      ),
    );
  }
}
