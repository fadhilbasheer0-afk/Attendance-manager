enum AppRole { teacher, student }

extension AppRoleX on AppRole {
  String get firestoreValue => name;
}

AppRole? appRoleFromString(String? v) {
  if (v == null) return null;
  for (final r in AppRole.values) {
    if (r.name == v) return r;
  }
  return null;
}
