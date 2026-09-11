class Team {
  final String id;
  final String name;
  final String? location;
  final TeamType teamType;
  final String? level;
  final String createdBy;
  final bool isActive;
  final String? sportenginesId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.location,
    required this.teamType,
    this.level,
    required this.createdBy,
    this.isActive = true,
    this.sportenginesId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      teamType: TeamType.fromString(json['team_type'] as String),
      level: json['level'] as String?,
      createdBy: json['created_by'] as String,
      isActive: (json['is_active'] as bool?) ?? true,
      sportenginesId: json['sportengines_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'team_type': teamType.value,
      'level': level,
      'created_by': createdBy,
      'is_active': isActive,
      'sportengines_id': sportenginesId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum TeamType {
  regular('regular'),
  camp('camp'),
  privateCoach('private_coach'),
  self('self');

  final String value;
  const TeamType(this.value);

  static TeamType fromString(String value) {
    return TeamType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TeamType.regular,
    );
  }
}
