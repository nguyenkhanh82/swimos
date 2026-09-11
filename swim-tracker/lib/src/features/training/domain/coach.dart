class Coach {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Coach({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
