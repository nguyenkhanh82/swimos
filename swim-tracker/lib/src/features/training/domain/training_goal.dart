class TrainingGoal {
  final String id;
  final String userId;
  final String? swimmerId;
  final String? teamId;
  final GoalType goalType;
  final String title;
  final String? description;
  
  // Time-based goal fields
  final String? stroke;
  final int? distance;
  final String? poolType;
  final double? targetTimeSeconds;
  
  // Distance-based goal fields
  final int? targetDistance;
  final String? distancePeriod;
  
  // Frequency-based goal fields
  final int? targetFrequency;
  final String? frequencyPeriod;
  
  // Custom goal fields
  final double? customTargetValue;
  final String? customUnit;
  
  // Common fields
  final DateTime? targetDate;
  final GoalStatus status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingGoal({
    required this.id,
    required this.userId,
    this.swimmerId,
    this.teamId,
    required this.goalType,
    required this.title,
    this.description,
    this.stroke,
    this.distance,
    this.poolType,
    this.targetTimeSeconds,
    this.targetDistance,
    this.distancePeriod,
    this.targetFrequency,
    this.frequencyPeriod,
    this.customTargetValue,
    this.customUnit,
    this.targetDate,
    this.status = GoalStatus.active,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingGoal.fromJson(Map<String, dynamic> json) {
    return TrainingGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      teamId: json['team_id'] as String?,
      goalType: GoalType.fromString(json['goal_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      stroke: json['stroke'] as String?,
      distance: json['distance'] as int?,
      poolType: json['pool_type'] as String?,
      targetTimeSeconds: json['target_time_seconds'] != null
          ? (json['target_time_seconds'] as num).toDouble()
          : null,
      targetDistance: json['target_distance'] as int?,
      distancePeriod: json['distance_period'] as String?,
      targetFrequency: json['target_frequency'] as int?,
      frequencyPeriod: json['frequency_period'] as String?,
      customTargetValue: json['custom_target_value'] != null
          ? (json['custom_target_value'] as num).toDouble()
          : null,
      customUnit: json['custom_unit'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      status: GoalStatus.fromString(json['status'] as String),
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'team_id': teamId,
      'goal_type': goalType.value,
      'title': title,
      'description': description,
      'stroke': stroke,
      'distance': distance,
      'pool_type': poolType,
      'target_time_seconds': targetTimeSeconds,
      'target_distance': targetDistance,
      'distance_period': distancePeriod,
      'target_frequency': targetFrequency,
      'frequency_period': frequencyPeriod,
      'custom_target_value': customTargetValue,
      'custom_unit': customUnit,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'status': status.value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum GoalType {
  time('time'),
  distance('distance'),
  frequency('frequency'),
  custom('custom');

  final String value;
  const GoalType(this.value);

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalType.custom,
    );
  }
}

enum GoalStatus {
  active('active'),
  completed('completed'),
  paused('paused'),
  archived('archived');

  final String value;
  const GoalStatus(this.value);

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalStatus.active,
    );
  }
}
