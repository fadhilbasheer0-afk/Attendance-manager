import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/firestore_repository.dart';
import '../../providers/session_provider.dart';

class CreateStudentProfileScreen extends StatefulWidget {
  const CreateStudentProfileScreen({super.key});

  @override
  State<CreateStudentProfileScreen> createState() =>
      _CreateStudentProfileScreenState();
}

class _CreateStudentProfileScreenState
    extends State<CreateStudentProfileScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _admission = TextEditingController();
  final _institutionPassword = TextEditingController();
  final _teacherCode = TextEditingController();
  final _photoUrl = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      if (u.displayName != null && u.displayName!.isNotEmpty) {
        _name.text = u.displayName!;
      }
      if (u.photoURL != null && u.photoURL!.isNotEmpty) {
        _photoUrl.text = u.photoURL!;
      }
      if (u.phoneNumber != null && u.phoneNumber!.isNotEmpty) {
        _mobile.text = u.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _admission.dispose();
    _institutionPassword.dispose();
    _teacherCode.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    final admission = _admission.text.trim();
    final institutionPassword = _institutionPassword.text.trim();
    final tCode = _teacherCode.text.trim();
    final photoUrl = _photoUrl.text.trim();

    if (name.isEmpty || mobile.isEmpty || institutionPassword.isEmpty) {
      setState(
          () => _error = 'Please fill Name, Mobile, and Institution Password.');
      return;
    }

    if (_isTeacher) {
      if (tCode.isEmpty) {
        setState(() => _error = 'Please enter the Teacher Password.');
        return;
      }
    } else {
      if (admission.isEmpty) {
        setState(() => _error = 'Please fill Admission details.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not fully signed in.');
      }
      final repo = context.read<FirestoreRepository>();
      final access = _isTeacher
          ? await repo.resolveTeacherAccess(
              institutionCode: institutionPassword,
              teacherCode: tCode,
            )
          : await repo.resolveInstitutionAccess(institutionPassword);

      if (access == null) {
        throw Exception(_isTeacher
            ? 'Institution password or teacher password not found. Verify both passwords match what the admin set.'
            : 'Institution password not found. Please try again.');
      }
      if (access.institutionId.isEmpty || access.branchId.isEmpty) {
        throw Exception('Institution setup incomplete. Contact the administrator.');
      }

      if (_isTeacher) {
        await repo.createTeacherProfile(
          uid: user.uid,
          name: name,
          mobile: mobile,
          institutionId: access.institutionId,
          branchId: access.branchId,
          inviteId: access.inviteId,
          teacherInviteId: access.teacherInviteId,
          photoUrl: photoUrl,
        );
      } else {
        await repo.createStudentProfile(
          uid: user.uid,
          name: name,
          admissionNumber: admission,
          mobile: mobile,
          className: '',
          medium: '',
          institutionId: access.institutionId,
          branchId: access.branchId,
          inviteId: access.inviteId,
          photoUrl: photoUrl,
        );
      }
      if (!mounted) return;
      await context.read<SessionProvider>().refreshProfile();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
              'Welcome! Please select your role and provide your details to continue.'),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Student')),
              ButtonSegment(value: true, label: Text('Teacher')),
            ],
            selected: {_isTeacher},
            onSelectionChanged: (set) {
              setState(() => _isTeacher = set.first);
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: _photoUrl.text.isNotEmpty
                  ? NetworkImage(_photoUrl.text)
                  : null,
              child: _photoUrl.text.isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _photoUrl,
            decoration: const InputDecoration(
                labelText: 'Profile Photo URL', hintText: 'https://...'),
            onChanged: (_) => setState(() {}),
          ),
          const Divider(height: 32),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mobile,
            decoration: const InputDecoration(
                labelText: 'Mobile Number', hintText: '+919000000000'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _institutionPassword,
            decoration: const InputDecoration(
              labelText: 'Institution Password',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          if (!_isTeacher) ...[
            TextField(
              controller: _admission,
              decoration: const InputDecoration(labelText: 'Admission Number'),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Class assignment is private'),
                subtitle: const Text(
                    'A teacher in your institution can assign your class after your profile is created.'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _teacherCode,
              decoration: const InputDecoration(
                labelText: 'Teacher Password',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              obscureText: true,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _createProfile,
            child: Text(_busy ? 'Saving...' : 'Create Profile'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed:
                _busy ? null : () => context.read<SessionProvider>().signOut(),
            child: const Text('Cancel & Sign Out'),
          )
        ],
      ),
    );
  }
}
