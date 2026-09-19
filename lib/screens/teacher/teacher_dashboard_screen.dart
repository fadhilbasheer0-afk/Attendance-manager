import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../models/branch.dart';
import '../../models/class_model.dart';
import 'teacher_class_main_screen.dart';
import 'teacher_home_shell.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.branchId,
  });

  final String branchId;

  // Modern preset colors for the class cards
  static const List<int> presetColors = [
    0xFF1976D2, // Blue
    0xFF303F9F, // Indigo
    0xFF7B1FA2, // Purple
    0xFF00796B, // Teal
    0xFF388E3C, // Green
    0xFFF57C00, // Orange
    0xFFC2185B, // Pink
    0xFF0097A7, // Cyan
    0xFFD32F2F, // Red
    0xFF455A64, // Blue Grey
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FirestoreRepository>();
    final today = DateFormat.yMMMEd().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Change Branch',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TeacherBranchPickerPage(),
                ),
              );
            },
            icon: const Icon(Icons.location_on),
          ),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: repo.watchClassesForBranch(branchId),
        builder: (context, classSnap) {
          final classes = classSnap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder<Branch?>(
                stream: repo.watchBranchById(branchId),
                builder: (context, snap) {
                  final b = snap.data;
                  return Card(
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TeacherBranchPickerPage()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.location_on,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Current Branch',
                                          style:
                                              Theme.of(context).textTheme.labelLarge),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.edit, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b?.name ?? branchId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(today,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Classes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (classes.isNotEmpty)
                    Text(
                      '${classes.length} Total',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (classSnap.connectionState == ConnectionState.waiting)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (classes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No classes created yet',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Add New" below to create a class',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final c = classes[index];
                    final classColor = Color(c.colorValue);

                    return Material(
                      color: classColor,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 3,
                      child: Stack(
                        children: [
                          InkWell(
                            onTap: () async {  // Added async here
                                    // Add a small delay to allow Firestore to propagate updates
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    if (context.mounted) { // Check if the widget is still mounted
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TeacherClassMainScreen(
                                            className: c.className,
                                            medium: c.medium,
                                            branchId: c.branchId,
                                            title: c.title,
                                            whatsappLink: c.whatsappLink,
                                            institutionId: c.institutionId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.school,
                                      color: Colors.white, size: 30),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.className,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.medium,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              tooltip: 'Class Options',
                              onPressed: () =>
                                  _showClassOptions(context, repo, c),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80), // Padding to avoid FAB overlap
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, repo),
        label: const Text('Add New'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context, FirestoreRepository repo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                title: const Text('Add New Class',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a new classroom for attendance'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClassDialog(context, repo);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text('Add New Student',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Add student profile details directly'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStudentDialog(context, repo);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.description, color: Colors.white),
                ),
                title: const Text("Monthly Report",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Generate monthly attendance report (PDF)"),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Implement navigation to monthly report screen
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showClassOptions(
      BuildContext context, FirestoreRepository repo, ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Class: ${classModel.title}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Class Details'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClassDialog(context, repo, classModel: classModel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Class'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Class?'),
                      content: Text(
                        'Are you sure you want to permanently delete "${classModel.className} (${classModel.medium})"?\n\n'
                        'Note: This will not automatically delete student profiles, but they will no longer be visible under this class.',
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await repo.deleteClass(classModel.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Class deleted successfully.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting class: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showClassDialog(BuildContext context, FirestoreRepository repo,
      {ClassModel? classModel}) {
    final isEdit = classModel != null;
    final formKey = GlobalKey<FormState>();
    final classController = TextEditingController(text: classModel?.className);
    final mediumController = TextEditingController(text: classModel?.medium ?? '');
    final linkController =
        TextEditingController(text: classModel?.whatsappLink);

    int selectedColor = classModel?.colorValue ?? presetColors.first;
    AttendanceMode selectedAttendanceMode =
        classModel?.attendanceMode ?? AttendanceMode.daily;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Class' : 'Create Class'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Class (e.g. Class 10, Class 9)',
                          hintText: 'Class 10',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter class name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: mediumController,
                        decoration: const InputDecoration(
                          labelText: 'Medium / Division (e.g. English Medium, A, B)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter medium / division'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Group Link',
                          hintText: 'https://chat.whatsapp.com/...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link, color: Colors.green),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter group link';
                          }
                          final clean = v.trim();
                          if (!clean.startsWith('https://chat.whatsapp.com/') &&
                              !clean.startsWith('http://chat.whatsapp.com/')) {
                            return 'Must be a valid WhatsApp invite link';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AttendanceMode>(
                        decoration: const InputDecoration(
                          labelText: 'Attendance Mode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        initialValue: selectedAttendanceMode,
                        items: AttendanceMode.values.map((mode) {
                          return DropdownMenuItem<AttendanceMode>(
                            value: mode,
                            child: Text(mode.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedAttendanceMode = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Card Color:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: presetColors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final colorInt = presetColors[idx];
                            final isSelected = selectedColor == colorInt;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedColor = colorInt),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(colorInt),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    width: isSelected ? 3.0 : 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() == true) {
                      try {
                        if (isEdit) {
                          await repo.updateClass(
                            id: classModel.id,
                            className: classController.text.trim(),
                            medium: mediumController.text.trim(),
                            whatsappLink: linkController.text.trim(),
                            branchId: branchId,
                            colorValue: selectedColor,
                            attendanceMode: selectedAttendanceMode,
                          );
                        } else {
                          await repo.addClass(
                            className: classController.text.trim(),
                            medium: mediumController.text.trim(),
                            whatsappLink: linkController.text.trim(),
                            branchId: branchId,
                            colorValue: selectedColor,
                            attendanceMode: selectedAttendanceMode,
                          );
                          // Small delay to allow Firestore to propagate
                          await Future.delayed(const Duration(milliseconds: 300));
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        // No need for a SnackBar here, as the stream builder will react and update.
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error saving class: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStudentDialog(BuildContext context, FirestoreRepository repo) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final admController = TextEditingController();
    final mobileController = TextEditingController();

    ClassModel? selectedClass;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StreamBuilder<List<ClassModel>>(
          stream: repo.watchClassesForBranch(branchId),
          builder: (context, classSnap) {
            final classes = classSnap.data ?? [];

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Add Student Profile'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Student Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter student name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<ClassModel>(
                            initialValue: selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Assign Class',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select Class'),
                            items: classes.map((c) {
                              return DropdownMenuItem<ClassModel>(
                                value: c,
                                child: Text('${c.className} (${c.medium})'),
                              );
                            }).toList(),
                            validator: (v) =>
                                v == null ? 'Select a class' : null,
                            onChanged: (val) {
                              setState(() => selectedClass = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: admController,
                            decoration: const InputDecoration(
                              labelText: 'Admission Number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter admission number'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number (Optional)',
                              border: OutlineInputBorder(),
                              hintText: '+919000000000',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final clean = v.trim();
                                if (!clean.startsWith('+') ||
                                    clean.length < 10) {
                                  return 'Format: +[country_code][number] (e.g. +919900000000)';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: classes.isEmpty
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() == true &&
                                  selectedClass != null) {
                                try {
                                  await repo.addStudentByTeacher(
                                    name: nameController.text.trim(),
                                    admissionNumber: admController.text.trim(),
                                    className: selectedClass!.className,
                                    medium: selectedClass!.medium,
                                    branchId: branchId,
                                    mobile: mobileController.text.trim(),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Student added successfully.')),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error adding student: $e')),
                                    );
                                  }
                                }
                              }
                            },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

}
