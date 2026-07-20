import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_role.dart';
import '../models/attendance_record.dart';
import '../models/attendance_status.dart';
import '../models/branch.dart';
import '../models/class_model.dart';
import '../models/institution.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/mark_record.dart';
import '../models/fee_record.dart';
import '../models/class_exam.dart';
import '../models/class_fee_category.dart';

class InstitutionAccess {
  const InstitutionAccess({
    required this.institutionId,
    required this.branchId,
    required this.inviteId,
    this.teacherInviteId = '',
  });

  final String institutionId;
  final String branchId;
  final String inviteId;
  final String teacherInviteId;
}

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _teachers =>
      _db.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection('students');
  CollectionReference<Map<String, dynamic>> get _attendance =>
      _db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection('classes');
  CollectionReference<Map<String, dynamic>> get _branches =>
      _db.collection('branches');
  CollectionReference<Map<String, dynamic>> get _institutions =>
      _db.collection('institutions');
  CollectionReference<Map<String, dynamic>> get _institutionInvites =>
      _db.collection('institutionInvites');
  CollectionReference<Map<String, dynamic>> get _teacherInvites =>
      _db.collection('teacherInvites');
  CollectionReference<Map<String, dynamic>> get _appAdmins =>
      _db.collection('appAdmins');
  CollectionReference<Map<String, dynamic>> get _marks =>
      _db.collection('marks');
  CollectionReference<Map<String, dynamic>> get _fees =>
      _db.collection('fees');
  CollectionReference<Map<String, dynamic>> get _classExams =>
      _db.collection('classExams');
  CollectionReference<Map<String, dynamic>> get _classFeeCategories =>
      _db.collection('classFeeCategories');

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentPhoneE164 => _auth.currentUser?.phoneNumber;

  Future<Teacher?> getTeacherDoc(String uid) async {
    final doc = await _teachers.doc(uid).get();
    if (doc.exists) {
      return Teacher.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Student?> getStudentDoc(String uid) async {
    final doc = await _students.doc(uid).get();
    if (doc.exists) {
      return Student.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Stream<Teacher?> watchTeacherDoc(String uid) {
    return _teachers
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Teacher.fromMap(doc.id, doc.data()!) : null);
  }

  Stream<Student?> watchStudentDoc(String uid) {
    return _students
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Student.fromMap(doc.id, doc.data()!) : null);
  }

  Stream<bool> watchAppAdminStatus(String uid) {
    return _appAdmins.doc(uid).snapshots().map((doc) => doc.exists);
  }

  String inviteIdForCode(String code) =>
      base64Url.encode(utf8.encode(code.trim())).replaceAll('=', '');

  String teacherInviteIdForCodes(String institutionCode, String teacherCode) =>
      inviteIdForCode('${institutionCode.trim()}\n${teacherCode.trim()}');

  String _cleanId(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_-]'), '_');
  }

  Future<InstitutionAccess?> resolveInstitutionAccess(String code) async {
    final inviteId = inviteIdForCode(code);
    final doc = await _institutionInvites.doc(inviteId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return InstitutionAccess(
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['defaultBranchId'] as String?)?.trim() ?? '',
      inviteId: inviteId,
    );
  }

  Future<InstitutionAccess?> resolveTeacherAccess({
    required String institutionCode,
    required String teacherCode,
  }) async {
    final inviteId = inviteIdForCode(institutionCode);
    final teacherInviteId =
        teacherInviteIdForCodes(institutionCode, teacherCode);
    final doc = await _teacherInvites.doc(teacherInviteId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return InstitutionAccess(
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['defaultBranchId'] as String?)?.trim() ?? '',
      inviteId: inviteId,
      teacherInviteId: teacherInviteId,
    );
  }

  Future<Branch?> branchById(String branchId) async {
    final doc = await _branches.doc(branchId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Branch.fromMap(doc.id, doc.data()!);
  }

  Future<void> ensureBranchesExist() async {
    final countSnap = await _institutions.count().get();
    if (countSnap.count == 0) {
      await addInstitution(
        id: 'DEFAULT',
        name: 'Default Institution',
        location: 'Default Location',
        institutionPassword: 'demo',
        teacherPassword: 'demo',
        branchNames: ['Main Branch'],
      );
    }
  }

  Stream<List<Institution>> watchInstitutions() {
    return _institutions.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => Institution.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<Institution?> getInstitutionById(String institutionId) async {
    final doc = await _institutions.doc(institutionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Institution.fromMap(doc.id, doc.data()!);
  }

  Stream<List<Branch>> watchBranches() {
    return _branches.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => Branch.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<Branch>> watchBranchesForInstitution(String institutionId) {
    return _branches
        .where('institutionId', isEqualTo: institutionId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Branch.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<Branch?> watchBranchById(String branchId) {
    return _branches.doc(branchId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Branch.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> addInstitution({
    required String id,
    required String name,
    required String location,
    required String institutionPassword,
    required String teacherPassword,
    required List<String> branchNames,
  }) async {
    final institutionId = _cleanId(id);
    if (institutionId.isEmpty) {
      throw ArgumentError('Institution code is required');
    }
    final cleanedBranches =
        branchNames.map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
    if (cleanedBranches.isEmpty) {
      throw ArgumentError('Add at least one branch');
    }
    if (institutionPassword.trim().isEmpty || teacherPassword.trim().isEmpty) {
      throw ArgumentError('Institution and teacher passwords are required');
    }

    final batch = _db.batch();
    final defaultBranchId =
        '${institutionId}_${_cleanId(cleanedBranches.first)}';
    batch.set(
      _institutions.doc(institutionId),
      Institution(
        id: institutionId,
        name: name.trim(),
        location: location.trim(),
        institutionPassword: institutionPassword.trim(),
        teacherPassword: teacherPassword.trim(),
      ).toMap(),
    );
    for (final branchName in cleanedBranches) {
      final branchId = '${institutionId}_${_cleanId(branchName)}';
      batch.set(
        _branches.doc(branchId),
        Branch(
          id: branchId,
          name: branchName,
          location: location.trim(),
          institutionId: institutionId,
        ).toMap(),
      );
    }
    batch.set(_institutionInvites.doc(inviteIdForCode(institutionPassword)), {
      'institutionId': institutionId,
      'defaultBranchId': defaultBranchId,
    });
    batch.set(
      _teacherInvites.doc(
        teacherInviteIdForCodes(institutionPassword, teacherPassword),
      ),
      {
        'institutionId': institutionId,
        'defaultBranchId': defaultBranchId,
      },
    );
    await batch.commit();
  }

  Future<void> updateInstitution({
    required String id,
    required String name,
    required String location,
    String? institutionPassword,
    String? teacherPassword,
    String? firstBranchId,
  }) {
    return _updateInstitutionInternal(
      id: id,
      name: name,
      location: location,
      institutionPassword: institutionPassword,
      teacherPassword: teacherPassword,
    );
  }

  Future<void> _updateInstitutionInternal({
    required String id,
    required String name,
    required String location,
    String? institutionPassword,
    String? teacherPassword,
  }) async {
    final docRef = _institutions.doc(id);
    final doc = await docRef.get();
    final old = doc.data() ?? <String, dynamic>{};
    final oldInstPass = (old['institutionPassword'] as String?) ?? '';
    final oldTeacherPass = (old['teacherPassword'] as String?) ?? '';

    final batch = _db.batch();
    final updateData = <String, dynamic>{
      'name': name.trim(),
      'location': location.trim(),
    };
    if (institutionPassword != null) {
      updateData['institutionPassword'] = institutionPassword.trim();
    }
    if (teacherPassword != null) {
      updateData['teacherPassword'] = teacherPassword.trim();
    }
    batch.update(docRef, updateData);

    // Update invites if passwords changed.
    // Delete old invite docs when present and create new ones.
    if (institutionPassword != null && oldInstPass.isNotEmpty) {
      final oldInviteId = inviteIdForCode(oldInstPass);
      batch.delete(_institutionInvites.doc(oldInviteId));
    }
    if (institutionPassword != null && institutionPassword.trim().isNotEmpty) {
      final newInviteId = inviteIdForCode(institutionPassword);
      batch.set(_institutionInvites.doc(newInviteId), {
        'institutionId': id,
        'defaultBranchId': '${id}_${_cleanId('Main')}',
      });
    }

    // Teacher invite depends on institution code; compute base values.
    final baseOldInst = oldInstPass;
    final baseNewInst = institutionPassword?.trim() ?? oldInstPass;

    if (teacherPassword != null && oldTeacherPass.isNotEmpty && baseOldInst.isNotEmpty) {
      final oldTeacherInviteId = teacherInviteIdForCodes(baseOldInst, oldTeacherPass);
      batch.delete(_teacherInvites.doc(oldTeacherInviteId));
    }
    if (teacherPassword != null && teacherPassword.trim().isNotEmpty && baseNewInst.isNotEmpty) {
      final newTeacherInviteId = teacherInviteIdForCodes(baseNewInst, teacherPassword);
      batch.set(_teacherInvites.doc(newTeacherInviteId), {
        'institutionId': id,
        'defaultBranchId': '${id}_${_cleanId('Main')}',
      });
    }

    await batch.commit();
  }

  Future<void> deleteInstitution(String id) async {
    final doc = await _institutions.doc(id).get();
    final data = doc.data() ?? <String, dynamic>{};
    final instPass = (data['institutionPassword'] as String?) ?? '';
    final teacherPass = (data['teacherPassword'] as String?) ?? '';

    final batch = _db.batch();
    // Delete institution doc
    batch.delete(_institutions.doc(id));

    // Delete branches belonging to institution
    final branchesSnap = await _branches.where('institutionId', isEqualTo: id).get();
    for (final b in branchesSnap.docs) {
      batch.delete(_branches.doc(b.id));
    }

    // Delete invites if present
    if (instPass.isNotEmpty) {
      final inviteId = inviteIdForCode(instPass);
      batch.delete(_institutionInvites.doc(inviteId));
    }
    if (instPass.isNotEmpty && teacherPass.isNotEmpty) {
      final teacherInviteId = teacherInviteIdForCodes(instPass, teacherPass);
      batch.delete(_teacherInvites.doc(teacherInviteId));
    }

    await batch.commit();
  }

  Future<void> removeOtherAppAdmins() async {
    final uid = currentUid;
    if (uid == null) return;
    final snap = await _appAdmins.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      if (d.id != uid) batch.delete(_appAdmins.doc(d.id));
    }
    await batch.commit();
  }

  Future<void> addBranch({
    required String institutionId,
    required String name,
    required String location,
  }) async {
    final branchId = '${_cleanId(institutionId)}_${_cleanId(name)}';
    await _branches.doc(branchId).set(
          Branch(
            id: branchId,
            name: name.trim(),
            location: location.trim(),
            institutionId: institutionId,
          ).toMap(),
        );
  }

  Future<void> updateBranch({
    required String id,
    required String name,
    required String location,
  }) {
    return _branches.doc(id).update({
      'name': name.trim(),
      'location': location.trim(),
    });
  }

  Future<bool> branchHasLinkedRecords(String branchId) async {
    final classes =
        await _classes.where('branchId', isEqualTo: branchId).limit(1).get();
    if (classes.docs.isNotEmpty) return true;
    final students =
        await _students.where('branchId', isEqualTo: branchId).limit(1).get();
    if (students.docs.isNotEmpty) return true;
    final teachers =
        await _teachers.where('branchId', isEqualTo: branchId).limit(1).get();
    return teachers.docs.isNotEmpty;
  }

  Future<void> deleteBranch(String id) {
    return _branches.doc(id).delete();
  }

  Future<void> updateTeacherBranch(String teacherId, String branchId) {
    return _teachers.doc(teacherId).update({'branchId': branchId.trim()});
  }

  Future<void> updateStudentBranch(String studentId, String branchId) {
    return _students.doc(studentId).update({'branchId': branchId.trim()});
  }

  Future<void> createStudentProfile({
    required String uid,
    required String name,
    required String admissionNumber,
    required String mobile,
    required String institutionId,
    required String className,
    required String medium,
    required String branchId,
    required String inviteId,
    String photoUrl = '',
  }) async {
    final cleanedBranchId = branchId.trim();
    final cleanedInstitutionId = institutionId.trim();
    final s = Student(
      id: uid,
      name: name.trim(),
      admissionNumber: admissionNumber.trim(),
      mobile: mobile.trim(),
      institutionId: cleanedInstitutionId,
      branchId: cleanedBranchId,
      className: className.trim(),
      medium: medium.trim(),
      role: AppRole.student,
      photoUrl: photoUrl.trim(),
    );
    await _students.doc(uid).set({
      ...s.toMap(),
      'inviteId': inviteId.trim(),
    });
  }

  Future<void> updateStudentProfile({
    required String uid,
    required String name,
    required String admissionNumber,
    required String mobile,
    required String className,
    required String medium,
    required String branchId,
    required String photoUrl,
  }) async {
    await _students.doc(uid).update({
      'name': name.trim(),
      'admissionNumber': admissionNumber.trim(),
      'mobile': mobile.trim(),
      'className': className.trim(),
      'medium': medium.trim(),
      'branchId': branchId.trim(),
      'photoUrl': photoUrl.trim(),
    });
  }

  Future<void> deleteStudentProfile(String uid) async {
    await _students.doc(uid).delete();
  }

  Future<void> addStudentByTeacher({
    required String name,
    required String admissionNumber,
    required String className,
    required String medium,
    required String branchId,
    String mobile = '',
  }) async {
    final cleanedBranchId = branchId.trim();
    final branch = await branchById(cleanedBranchId);
    if (branch == null) {
      throw ArgumentError('Invalid branch ID: $cleanedBranchId');
    }
    final docRef = _students.doc();
    final s = Student(
      id: docRef.id,
      name: name.trim(),
      admissionNumber: admissionNumber.trim(),
      mobile: mobile.trim(),
      institutionId: branch.institutionId,
      branchId: cleanedBranchId,
      className: className.trim(),
      medium: medium.trim(),
      role: AppRole.student,
      photoUrl: '',
    );
    await docRef.set(s.toMap());
  }

  Stream<List<ClassModel>> watchClassesForBranch(String branchId) {
    final cleanedBranchId = branchId.trim();
    return _classes
        .where('branchId', isEqualTo: cleanedBranchId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ClassModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.className.compareTo(b.className));
      return list;
    });
  }

  Future<void> addClass({
    required String className,
    required String medium,
    required String whatsappLink,
    required String branchId,
    required int colorValue,
  }) async {
    final cleanedBranchId = branchId.trim();
    final branch = await branchById(cleanedBranchId);
    if (branch == null) {
      throw ArgumentError('Invalid branch ID: $cleanedBranchId');
    }
    final docRef = _classes.doc();
    final c = ClassModel(
      id: docRef.id,
      className: className.trim(),
      medium: medium.trim(),
      whatsappLink: whatsappLink.trim(),
      institutionId: branch.institutionId,
      branchId: cleanedBranchId,
      colorValue: colorValue,
    );
    await docRef.set(c.toMap());
  }

  Future<void> updateClass({
    required String id,
    required String className,
    required String medium,
    required String whatsappLink,
    required String branchId,
    required int colorValue,
  }) async {
    final cleanedBranchId = branchId.trim();
    final branch = await branchById(cleanedBranchId);
    if (branch == null) {
      throw ArgumentError('Invalid branch ID: $cleanedBranchId');
    }
    await _classes.doc(id).update({
      'className': className.trim(),
      'medium': medium.trim(),
      'whatsappLink': whatsappLink.trim(),
      'colorValue': colorValue,
    });
  }

  Future<void> deleteClass(String id) async {
    await _classes.doc(id).delete();
  }

  Future<void> createTeacherProfile({
    required String uid,
    required String name,
    required String mobile,
    required String institutionId,
    required String branchId,
    required String inviteId,
    required String teacherInviteId,
    String photoUrl = '',
  }) async {
    final cleanedBranchId = branchId.trim();
    final cleanedInstitutionId = institutionId.trim();

    final t = Teacher(
      id: uid,
      name: name.trim(),
      mobile: mobile.trim(),
      institutionId: cleanedInstitutionId,
      branchId: cleanedBranchId,
      role: AppRole.teacher,
      photoUrl: photoUrl.trim(),
    );
    await _teachers.doc(uid).set({
      ...t.toMap(),
      'inviteId': inviteId.trim(),
      'teacherInviteId': teacherInviteId.trim(),
    });
  }

  Future<void> wipeDatabase() async {
    throw UnsupportedError(
        'Database wipe is disabled in multi-institution mode.');
  }

  Stream<List<Student>> watchStudentsForBranch(String branchId) {
    final cleanedBranchId = branchId.trim();
    return _students
        .where('branchId', isEqualTo: cleanedBranchId)
        .orderBy('name')
        .snapshots()
        .map(
            (s) => s.docs.map((d) => Student.fromMap(d.id, d.data())).toList());
  }

  Future<List<AttendanceRecord>> attendanceForStudentOnDate({
    required String studentId,
    required String branchId,
    required DateTime dayUtc,
  }) async {
    final start =
        Timestamp.fromDate(DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day));
    final end = Timestamp.fromDate(
        DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day + 1));
    final snap = await _attendance
        .where('studentId', isEqualTo: studentId)
        .where('branchId', isEqualTo: branchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .limit(5)
        .get();
    return snap.docs.map(AttendanceRecord.fromDoc).toList();
  }

  Future<void> upsertAttendance({
    required String studentId,
    required String branchId,
    required DateTime dayUtc,
    required AttendanceStatus status,
    String? markedByTeacherId,
  }) async {
    final marker = markedByTeacherId ?? currentUid;
    if (marker == null || marker.isEmpty) {
      throw StateError('Not signed in');
    }
    final day = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    final existing = await attendanceForStudentOnDate(
      studentId: studentId,
      branchId: branchId,
      dayUtc: day,
    );
    final branch = await branchById(branchId);
    final data = AttendanceRecord(
      id: '',
      studentId: studentId,
      institutionId: branch?.institutionId ?? '',
      branchId: branchId,
      date: day,
      status: status,
      markedBy: marker,
    ).toFirestore();

    if (existing.isNotEmpty) {
      await _attendance.doc(existing.first.id).update(data);
    } else {
      await _attendance.add(data);
    }
  }

  Stream<List<AttendanceRecord>> watchAttendanceForBranchOnDate({
    required String branchId,
    required DateTime dayUtc,
  }) {
    final cleanedBranchId = branchId.trim();
    final start =
        Timestamp.fromDate(DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day));
    final end = Timestamp.fromDate(
        DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day + 1));
    return _attendance
        .where('branchId', isEqualTo: cleanedBranchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  Stream<List<AttendanceRecord>> watchAttendanceHistoryForStudent({
    required String studentId,
    required String branchId,
    int limit = 120,
  }) {
    return _attendance
        .where('studentId', isEqualTo: studentId)
        .where('branchId', isEqualTo: branchId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  /// Fetches all attendance records for [branchId] in the given [year]/[month].
  Stream<List<AttendanceRecord>> watchAttendanceForBranchInMonth({
    required String branchId,
    required int year,
    required int month,
  }) {
    final cleanedBranchId = branchId.trim();
    final start = Timestamp.fromDate(DateTime.utc(year, month, 1));
    final end = Timestamp.fromDate(
      month < 12
          ? DateTime.utc(year, month + 1, 1)
          : DateTime.utc(year + 1, 1, 1),
    );
    return _attendance
        .where('branchId', isEqualTo: cleanedBranchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  /// Students filtered by branch, class name, and medium.
  Stream<List<Student>> watchStudentsForClass({
    required String branchId,
    required String className,
    required String medium,
  }) {
    final cleanedBranchId = branchId.trim();
    final cleanedClassName = className.trim();
    final cleanedMedium = medium.trim();

    var query = _students
        .where('branchId', isEqualTo: cleanedBranchId)
        .where('className', isEqualTo: cleanedClassName);

    if (cleanedMedium.isNotEmpty) {
      query = query.where('medium', isEqualTo: cleanedMedium);
    }

    return query.orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => Student.fromMap(d.id, d.data())).toList());
  }

  Future<void> bulkUpsertAttendance({
    required List<String> studentIds,
    required String branchId,
    required DateTime dayUtc,
    required AttendanceStatus status,
  }) async {
    final marker = currentUid;
    if (marker == null || marker.isEmpty) throw StateError('Not signed in');
    final day = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);

    final start = Timestamp.fromDate(day);
    final end = Timestamp.fromDate(day.add(const Duration(days: 1)));

    final existingSnap = await _attendance
        .where('branchId', isEqualTo: branchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    final existingMap = {
      for (final d in existingSnap.docs) (d.data()['studentId'] as String): d.id
    };

    final batch = _db.batch();
    for (final sid in studentIds) {
      final branch = await branchById(branchId);
      final data = AttendanceRecord(
        id: '',
        studentId: sid,
        institutionId: branch?.institutionId ?? '',
        branchId: branchId,
        date: day,
        status: status,
        markedBy: marker,
      ).toFirestore();

      if (existingMap.containsKey(sid)) {
        batch.update(_attendance.doc(existingMap[sid]), data);
      } else {
        batch.set(_attendance.doc(), data);
      }
    }
    await batch.commit();
  }

  Stream<List<MarkRecord>> watchMarksForClass({
    required String branchId,
    required String className,
    required String medium,
    required String examName,
  }) {
    final cleanedBranchId = branchId.trim();
    final cleanedClassName = className.trim();
    final cleanedMedium = medium.trim();
    final cleanedExamName = examName.trim();

    return _marks
        .where('branchId', isEqualTo: cleanedBranchId)
        .where('className', isEqualTo: cleanedClassName)
        .where('medium', isEqualTo: cleanedMedium)
        .where('examName', isEqualTo: cleanedExamName)
        .snapshots()
        .map((snap) => snap.docs.map(MarkRecord.fromDoc).toList());
  }

  Future<void> upsertMarkRecord({
    required String studentId,
    required String branchId,
    required String className,
    required String medium,
    required String examName,
    required Map<String, int> subjectMarks,
  }) async {
    final branch = await branchById(branchId);
    final institutionId = branch?.institutionId ?? '';

    final query = await _marks
        .where('studentId', isEqualTo: studentId)
        .where('examName', isEqualTo: examName)
        .limit(1)
        .get();

    final record = MarkRecord(
      id: '',
      studentId: studentId,
      institutionId: institutionId,
      branchId: branchId,
      className: className,
      medium: medium,
      examName: examName,
      subjectMarks: subjectMarks,
      updatedAt: DateTime.now(),
    );

    if (query.docs.isNotEmpty) {
      await _marks.doc(query.docs.first.id).update(record.toFirestore());
    } else {
      await _marks.add(record.toFirestore());
    }
  }

  Stream<List<FeeRecord>> watchFeesForClass({
    required String branchId,
    required String className,
    required String medium,
    required String feeCategory,
  }) {
    final cleanedBranchId = branchId.trim();
    final cleanedClassName = className.trim();
    final cleanedMedium = medium.trim();
    final cleanedFeeCategory = feeCategory.trim();

    return _fees
        .where('branchId', isEqualTo: cleanedBranchId)
        .where('className', isEqualTo: cleanedClassName)
        .where('medium', isEqualTo: cleanedMedium)
        .where('feeCategory', isEqualTo: cleanedFeeCategory)
        .snapshots()
        .map((snap) => snap.docs.map(FeeRecord.fromDoc).toList());
  }

  Future<void> recordFeePayment({
    required String studentId,
    required String branchId,
    required String className,
    required String medium,
    required String feeCategory,
    required double totalAmount,
    required double paymentAmount,
    required String receiptNumber,
    required DateTime dueDate,
  }) async {
    final branch = await branchById(branchId);
    final institutionId = branch?.institutionId ?? '';

    final query = await _fees
        .where('studentId', isEqualTo: studentId)
        .where('feeCategory', isEqualTo: feeCategory)
        .limit(1)
        .get();

    FeeRecord record;
    if (query.docs.isNotEmpty) {
      final existing = FeeRecord.fromDoc(query.docs.first);
      final updatedHistory = List<PaymentHistoryItem>.from(existing.paymentHistory)
        ..add(PaymentHistoryItem(
          amount: paymentAmount,
          date: DateTime.now(),
          receiptNumber: receiptNumber,
        ));
      final updatedPaid = existing.amountPaid + paymentAmount;
      String status = 'Unpaid';
      if (updatedPaid >= existing.totalAmount) {
        status = 'Paid';
      } else if (updatedPaid > 0) {
        status = 'Partially Paid';
      }
      record = FeeRecord(
        id: existing.id,
        studentId: studentId,
        institutionId: institutionId,
        branchId: branchId,
        className: className,
        medium: medium,
        feeCategory: feeCategory,
        totalAmount: existing.totalAmount,
        amountPaid: updatedPaid,
        status: status,
        dueDate: existing.dueDate,
        paymentHistory: updatedHistory,
      );
      await _fees.doc(existing.id).update(record.toFirestore());
    } else {
      final history = [
        PaymentHistoryItem(
          amount: paymentAmount,
          date: DateTime.now(),
          receiptNumber: receiptNumber,
        )
      ];
      String status = 'Unpaid';
      if (paymentAmount >= totalAmount) {
        status = 'Paid';
      } else if (paymentAmount > 0) {
        status = 'Partially Paid';
      }
      record = FeeRecord(
        id: '',
        studentId: studentId,
        institutionId: institutionId,
        branchId: branchId,
        className: className,
        medium: medium,
        feeCategory: feeCategory,
        totalAmount: totalAmount,
        amountPaid: paymentAmount,
        status: status,
        dueDate: dueDate,
        paymentHistory: history,
      );
      await _fees.add(record.toFirestore());
    }
  }

  Future<void> updateFeeDetails({
    required String studentId,
    required String branchId,
    required String className,
    required String medium,
    required String feeCategory,
    required double totalAmount,
    required DateTime dueDate,
  }) async {
    final branch = await branchById(branchId);
    final institutionId = branch?.institutionId ?? '';

    final query = await _fees
        .where('studentId', isEqualTo: studentId)
        .where('feeCategory', isEqualTo: feeCategory)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final existing = FeeRecord.fromDoc(query.docs.first);
      String status = 'Unpaid';
      if (existing.amountPaid >= totalAmount) {
        status = 'Paid';
      } else if (existing.amountPaid > 0) {
        status = 'Partially Paid';
      }
      final record = FeeRecord(
        id: existing.id,
        studentId: studentId,
        institutionId: institutionId,
        branchId: branchId,
        className: className,
        medium: medium,
        feeCategory: feeCategory,
        totalAmount: totalAmount,
        amountPaid: existing.amountPaid,
        status: status,
        dueDate: dueDate,
        paymentHistory: existing.paymentHistory,
      );
      await _fees.doc(existing.id).update(record.toFirestore());
    } else {
      final record = FeeRecord(
        id: '',
        studentId: studentId,
        institutionId: institutionId,
        branchId: branchId,
        className: className,
        medium: medium,
        feeCategory: feeCategory,
        totalAmount: totalAmount,
        amountPaid: 0.0,
        status: 'Unpaid',
        dueDate: dueDate,
        paymentHistory: const [],
      );
      await _fees.add(record.toFirestore());
    }
  }

  Stream<List<ClassExam>> watchClassExams({
    required String branchId,
    required String className,
    required String medium,
  }) {
    return _classExams
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(ClassExam.fromDoc).toList());
  }

  Future<void> ensureDefaultClassExamsIfEmpty({
    required String branchId,
    required String className,
    required String medium,
  }) async {
    final existing = await _classExams
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    const defaults = [
      ('Midterm Exam', 100),
      ('Final Exam', 100),
      ('Unit Test 1', 50),
      ('Unit Test 2', 50),
    ];
    final batch = _db.batch();
    final now = DateTime.now();
    for (final (name, totalMarks) in defaults) {
      final ref = _classExams.doc();
      batch.set(ref, ClassExam(
        id: ref.id,
        branchId: branchId,
        className: className,
        medium: medium,
        name: name,
        totalMarks: totalMarks,
        createdAt: now,
      ).toFirestore());
    }
    await batch.commit();
  }

  Future<ClassExam> addClassExam({
    required String branchId,
    required String className,
    required String medium,
    required String name,
    required int totalMarks,
  }) async {
    final trimmedName = name.trim();
    final duplicate = await _classExams
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .where('name', isEqualTo: trimmedName)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw StateError('An exam with this name already exists.');
    }

    final ref = _classExams.doc();
    final exam = ClassExam(
      id: ref.id,
      branchId: branchId,
      className: className,
      medium: medium,
      name: trimmedName,
      totalMarks: totalMarks,
      createdAt: DateTime.now(),
    );
    await ref.set(exam.toFirestore());
    return exam;
  }

  Future<void> updateClassExam({
    required String examId,
    required String branchId,
    required String className,
    required String medium,
    required String oldName,
    required String newName,
    required int totalMarks,
  }) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName != oldName.trim()) {
      final duplicate = await _classExams
          .where('branchId', isEqualTo: branchId.trim())
          .where('className', isEqualTo: className.trim())
          .where('medium', isEqualTo: medium.trim())
          .where('name', isEqualTo: trimmedNewName)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty && duplicate.docs.first.id != examId) {
        throw StateError('An exam with this name already exists.');
      }
    }

    await _classExams.doc(examId).update({
      'name': trimmedNewName,
      'totalMarks': totalMarks,
    });

    if (trimmedNewName != oldName.trim()) {
      final marksQuery = await _marks
          .where('branchId', isEqualTo: branchId.trim())
          .where('className', isEqualTo: className.trim())
          .where('medium', isEqualTo: medium.trim())
          .where('examName', isEqualTo: oldName.trim())
          .get();
      if (marksQuery.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in marksQuery.docs) {
          batch.update(doc.reference, {'examName': trimmedNewName});
        }
        await batch.commit();
      }
    }
  }

  Future<void> deleteClassExam({
    required String examId,
    required String branchId,
    required String className,
    required String medium,
    required String examName,
  }) async {
    await _classExams.doc(examId).delete();

    final marksQuery = await _marks
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .where('examName', isEqualTo: examName.trim())
        .get();
    if (marksQuery.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in marksQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Stream<List<ClassFeeCategory>> watchClassFeeCategories({
    required String branchId,
    required String className,
    required String medium,
  }) {
    return _classFeeCategories
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(ClassFeeCategory.fromDoc).toList());
  }

  Future<void> ensureDefaultClassFeeCategoriesIfEmpty({
    required String branchId,
    required String className,
    required String medium,
  }) async {
    final existing = await _classFeeCategories
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    const defaults = [
      'Tuition Fee - Term 1',
      'Tuition Fee - Term 2',
      'Admission Fee',
      'Exam Fee',
    ];
    final batch = _db.batch();
    final now = DateTime.now();
    for (final name in defaults) {
      final ref = _classFeeCategories.doc();
      batch.set(ref, ClassFeeCategory(
        id: ref.id,
        branchId: branchId,
        className: className,
        medium: medium,
        name: name,
        createdAt: now,
      ).toFirestore());
    }
    await batch.commit();
  }

  Future<ClassFeeCategory> addClassFeeCategory({
    required String branchId,
    required String className,
    required String medium,
    required String name,
  }) async {
    final trimmedName = name.trim();
    final duplicate = await _classFeeCategories
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .where('name', isEqualTo: trimmedName)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw StateError('A fee category with this name already exists.');
    }

    final ref = _classFeeCategories.doc();
    final category = ClassFeeCategory(
      id: ref.id,
      branchId: branchId,
      className: className,
      medium: medium,
      name: trimmedName,
      createdAt: DateTime.now(),
    );
    await ref.set(category.toFirestore());
    return category;
  }

  Future<void> updateClassFeeCategory({
    required String categoryId,
    required String branchId,
    required String className,
    required String medium,
    required String oldName,
    required String newName,
  }) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName != oldName.trim()) {
      final duplicate = await _classFeeCategories
          .where('branchId', isEqualTo: branchId.trim())
          .where('className', isEqualTo: className.trim())
          .where('medium', isEqualTo: medium.trim())
          .where('name', isEqualTo: trimmedNewName)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty && duplicate.docs.first.id != categoryId) {
        throw StateError('A fee category with this name already exists.');
      }
    }

    await _classFeeCategories.doc(categoryId).update({'name': trimmedNewName});

    if (trimmedNewName != oldName.trim()) {
      final feesQuery = await _fees
          .where('branchId', isEqualTo: branchId.trim())
          .where('className', isEqualTo: className.trim())
          .where('medium', isEqualTo: medium.trim())
          .where('feeCategory', isEqualTo: oldName.trim())
          .get();
      if (feesQuery.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in feesQuery.docs) {
          batch.update(doc.reference, {'feeCategory': trimmedNewName});
        }
        await batch.commit();
      }
    }
  }

  Future<void> deleteClassFeeCategory({
    required String categoryId,
    required String branchId,
    required String className,
    required String medium,
    required String categoryName,
  }) async {
    await _classFeeCategories.doc(categoryId).delete();

    final feesQuery = await _fees
        .where('branchId', isEqualTo: branchId.trim())
        .where('className', isEqualTo: className.trim())
        .where('medium', isEqualTo: medium.trim())
        .where('feeCategory', isEqualTo: categoryName.trim())
        .get();
    if (feesQuery.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in feesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
