import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_role.dart';
import '../models/branch.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../data/firestore_repository.dart';

class SessionState {
  const SessionState({
    required this.firebaseUser,
    required this.role,
    this.teacher,
    this.student,
  });

  final User firebaseUser;
  final AppRole role;
  final Teacher? teacher;
  final Student? student;

  bool get isTeacher => role == AppRole.teacher;
  bool get isStudent => role == AppRole.student;

  String get profileName {
    if (teacher != null) return teacher!.name;
    if (student != null) return student!.name;
    return firebaseUser.phoneNumber ?? 'User';
  }

  String? get branchId {
    if (teacher != null) return teacher!.branchId;
    if (student != null) return student!.branchId;
    return null;
  }

  String? get institutionId {
    if (teacher != null) return teacher!.institutionId;
    if (student != null) return student!.institutionId;
    return null;
  }

  String? get entityId {
    if (teacher != null) return teacher!.id;
    if (student != null) return student!.id;
    return null;
  }
}

class SessionProvider extends ChangeNotifier {
  SessionProvider({FirestoreRepository? repo})
      : _repo = repo ?? FirestoreRepository() {
    listenToAuth();
  }

  final FirestoreRepository _repo;

  User? _firebaseUser;
  SessionState? _session;
  String? _errorMessage;
  bool _loadingProfile = false;
  bool _authReady = false;

  StreamSubscription? _teacherSub;
  StreamSubscription? _studentSub;
  StreamSubscription? _appAdminSub;
  bool _isAppAdmin = false;

  User? get firebaseUser => _firebaseUser;
  SessionState? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get loadingProfile => _loadingProfile;
  bool get authReady => _authReady;
  bool get isSignedIn => _firebaseUser != null;
  bool get hasProfile => _session != null;
  bool get isAppAdmin => _isAppAdmin;

  @override
  void dispose() {
    _teacherSub?.cancel();
    _studentSub?.cancel();
    _appAdminSub?.cancel();
    super.dispose();
  }

  void listenToAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _firebaseUser = user;
      _errorMessage = null;
      _authReady = true;
      if (user == null) {
        _teacherSub?.cancel();
        _studentSub?.cancel();
        _appAdminSub?.cancel();
        _isAppAdmin = false;
        _session = null;
        _loadingProfile = false;
        notifyListeners();
        return;
      }
      _appAdminSub?.cancel();
      _appAdminSub = _repo.watchAppAdminStatus(user.uid).listen((isAdmin) {
        _isAppAdmin = isAdmin;
        notifyListeners();
      });
      await _loadProfileForUser(user);
    });
  }

  Future<void> refreshProfile() async {
    final u = _firebaseUser;
    if (u == null) return;
    await _loadProfileForUser(u);
  }

  Future<void> _loadProfileForUser(User user) async {
    _loadingProfile = true;
    notifyListeners();
    try {
      // Ensure branches exist now that we are authenticated
      try {
        await _repo.ensureBranchesExist();
      } catch (_) {}

      // 1. Try to find Teacher by UID
      final tSnap = await _repo.getTeacherDoc(user.uid);
      if (tSnap != null) {
        _session = SessionState(
            firebaseUser: user, role: AppRole.teacher, teacher: tSnap);
        _errorMessage = null;
        _teacherSub?.cancel();
        _studentSub?.cancel();
        _teacherSub = _repo.watchTeacherDoc(user.uid).listen((updatedT) {
          if (updatedT != null && _session != null) {
            _session = SessionState(
                firebaseUser: user, role: AppRole.teacher, teacher: updatedT);
            notifyListeners();
          }
        });
        return;
      }

      // 2. Try to find Student by UID
      final sSnap = await _repo.getStudentDoc(user.uid);
      if (sSnap != null) {
        _session = SessionState(
            firebaseUser: user, role: AppRole.student, student: sSnap);
        _errorMessage = null;
        _teacherSub?.cancel();
        _studentSub?.cancel();
        _studentSub = _repo.watchStudentDoc(user.uid).listen((updatedS) {
          if (updatedS != null && _session != null) {
            _session = SessionState(
                firebaseUser: user, role: AppRole.student, student: updatedS);
            notifyListeners();
          }
        });
        return;
      }

      // 3. Not found by UID. We assume they are a new Student and show the Create Profile screen.
      _session = null;
      _errorMessage =
          'No teacher or student profile found for this login. Please create your profile.';
    } on FirebaseException catch (e) {
      _session = null;
      if (e.code == 'unavailable') {
        _errorMessage =
            'Cannot connect to the database. Please check your internet connection. (Admin: verify Firestore Database is created in Firebase Console).';
      } else {
        _errorMessage = e.message ?? e.toString();
      }
    } catch (e) {
      _session = null;
      _errorMessage = e.toString();
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _teacherSub?.cancel();
    _studentSub?.cancel();
    _appAdminSub?.cancel();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  Stream<List<Branch>> watchBranches() => _repo.watchBranches();

  Stream<List<Branch>> watchBranchesForCurrentInstitution() {
    final institutionId = _session?.institutionId;
    if (institutionId == null || institutionId.isEmpty) {
      return const Stream.empty();
    }
    return _repo.watchBranchesForInstitution(institutionId);
  }

  Stream<Branch?> watchBranchById(String branchId) =>
      _repo.watchBranchById(branchId);

  Future<void> setBranchForCurrentUser(String branchId) async {
    final s = _session;
    if (s == null) return;
    final branch = await _repo.branchById(branchId);
    if (branch == null || branch.institutionId != s.institutionId) {
      throw StateError('Branch is outside your institution.');
    }
    if (s.isTeacher && s.teacher != null) {
      await _repo.updateTeacherBranch(s.teacher!.id, branchId);
      await refreshProfile();
      return;
    }
    if (s.isStudent && s.student != null) {
      await _repo.updateStudentBranch(s.student!.id, branchId);
      await refreshProfile();
    }
  }
}
