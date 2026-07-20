import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/auth/google_login_screen.dart';
import '../screens/branch/branch_selection_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/student/create_student_profile_screen.dart';
import '../screens/student/student_home_shell.dart';
import '../screens/teacher/teacher_home_shell.dart';
import '../screens/admin/admin_home_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (!session.authReady) {
          return const SplashScreen(message: 'Starting…');
        }
        if (session.firebaseUser == null) {
          return const GoogleLoginScreen();
        }
        if (session.loadingProfile) {
          return const SplashScreen(message: 'Loading your profile…');
        }
        if (session.isAppAdmin) {
          return const AdminHomeShell();
        }
        if (session.errorMessage != null && session.session == null) {
          if (session.errorMessage!
              .contains('No teacher or student profile found')) {
            return const CreateStudentProfileScreen();
          }
          return _ProfileMissingScreen(message: session.errorMessage!);
        }
        final s = session.session;
        if (s == null) {
          return const GoogleLoginScreen();
        }
        final bid = s.branchId;
        if (bid == null || bid.isEmpty) {
          return const BranchSelectionScreen();
        }
        if (s.isTeacher) {
          return TeacherHomeShell(key: ValueKey(s.teacher!.id));
        }
        return StudentHomeShell(key: ValueKey(s.student!.id));
      },
    );
  }
}

class _ProfileMissingScreen extends StatelessWidget {
  const _ProfileMissingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup required')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.info_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (FirebaseAuth.instance.currentUser?.uid != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                'User id: ${FirebaseAuth.instance.currentUser!.uid}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () async {
                try {
                  await context.read<SessionProvider>().signOut();
                } catch (_) {
                  await FirebaseAuth.instance.signOut();
                }
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
