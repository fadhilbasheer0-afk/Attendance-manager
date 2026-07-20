class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.location,
    required this.institutionId,
  });

  final String id;
  final String name;
  final String location;
  final String institutionId;

  factory Branch.fromMap(String id, Map<String, dynamic> data) {
    return Branch(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      location: (data['location'] as String?)?.trim() ?? '',
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'location': location,
        'institutionId': institutionId,
      };
}
