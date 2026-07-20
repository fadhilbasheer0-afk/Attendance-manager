class ClassModel {
  const ClassModel({
    required this.id,
    required this.className,
    required this.medium,
    required this.whatsappLink,
    required this.institutionId,
    required this.branchId,
    required this.colorValue,
  });

  final String id;
  final String className; // e.g. "Class 10"
  final String medium; // e.g. "English Medium"
  final String whatsappLink; // e.g. WhatsApp Group URL
  final String institutionId;
  final String branchId;
  final int colorValue; // ARGB representation of color for dashboard card

  factory ClassModel.fromMap(String id, Map<String, dynamic> data) {
    return ClassModel(
      id: id,
      className: (data['className'] as String?)?.trim() ?? '',
      medium: (data['medium'] as String?)?.trim() ?? '',
      whatsappLink: (data['whatsappLink'] as String?)?.trim() ?? '',
      institutionId: (data['institutionId'] as String?)?.trim() ?? '',
      branchId: (data['branchId'] as String?)?.trim() ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF1976D2, // Default blue
    );
  }

  Map<String, dynamic> toMap() => {
        'className': className.trim(),
        'medium': medium.trim(),
        'whatsappLink': whatsappLink.trim(),
        'institutionId': institutionId.trim(),
        'branchId': branchId.trim(),
        'colorValue': colorValue,
      };

  String get title => '$className ($medium)';
}
