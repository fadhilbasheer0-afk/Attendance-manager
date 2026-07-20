import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/firestore_repository.dart';
import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = FirestoreRepository();
  try {
    await repo.ensureBranchesExist();
  } catch (e) {
    // Ignore permission denied error if user is not logged in yet.
    debugPrint('Could not initialize branches: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repo),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(repo: repo),
        ),
      ],
      child: const AttendanceManagerApp(),
    ),
  );
}

class AttendanceManagerApp extends StatelessWidget {
  const AttendanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
