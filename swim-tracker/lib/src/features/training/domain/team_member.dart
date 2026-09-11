class TeamMember {
  final String id;
  final String? userId; // Nullable for backward compatibility
  final String swimmerId; // Required - links to swimmers table
  final String? swimcloudId; // SwimCloud ID for API calls
  final String teamId;
  final TeamMemberStatus status;
  final DateTime joinedDate;
  final DateTime? leftDate;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamMember({
    required this.id,
    this.userId,
    required this.swimmerId,
    this.swimcloudId,
    required this.teamId,
    required this.status,
    required this.joinedDate,
    this.leftDate,
    this.role = 'swimmer',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      swimmerId: json['swimmer_id'] as String,
      swimcloudId: json['swimcloud_id'] as String?,
      teamId: json['team_id'] as String,
      status: TeamMemberStatus.fromString(json['status'] as String),
      joinedDate: DateTime.parse(json['joined_date'] as String),
      leftDate: json['left_date'] != null
          ? DateTime.parse(json['left_date'] as String)
          : null,
      role: (json['role'] as String?) ?? 'swimmer',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'swimcloud_id': swimcloudId,
      'team_id': teamId,
      'status': status.value,
      'joined_date': joinedDate.toIso8601String().split('T')[0],
      'left_date': leftDate?.toIso8601String().split('T')[0],
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum TeamMemberStatus {
  active('active'),
  past('past');

  final String value;
  const TeamMemberStatus(this.value);

  static TeamMemberStatus fromString(String value) {
    return TeamMemberStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TeamMemberStatus.active,
    );
  }
}
