import '../utils/interval_parser.dart';

class TrainingSession {
  final String id;
  final String userId;
  final String? swimmerId;
  final String? practiceId;
  final DateTime trainingDate;
  final String setDescription;
  final String stroke;
  final int distancePerRep;
  final int numberOfReps;
  final int totalDistance;
  final int? restSeconds;
  final String poolType;
  final String intensity;
  final String? notes;
  final String? teamId;
  final String? goalId;
  final int? rpe;
  final int? dayOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingSession({
    required this.id,
    required this.userId,
    this.swimmerId,
    this.practiceId,
    required this.trainingDate,
    required this.setDescription,
    required this.stroke,
    required this.distancePerRep,
    required this.numberOfReps,
    required this.totalDistance,
    this.restSeconds,
    this.poolType = 'SCY',
    this.intensity = 'moderate',
    this.notes,
    this.teamId,
    this.goalId,
    this.rpe,
    this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMainSet {
    final lowerDesc = setDescription.toLowerCase();
    final lowerStroke = stroke.toLowerCase();

    if (lowerDesc.contains('warm up') || lowerDesc.contains('warmup'))
      return false;
    if (lowerDesc.contains('cool down') || lowerDesc.contains('cooldown'))
      return false;
    if (lowerStroke == 'drill') return false;

    return true;
  }

  TrainingSession copyWith({
    String? id,
    String? userId,
    String? swimmerId,
    String? practiceId,
    DateTime? trainingDate,
    String? setDescription,
    String? stroke,
    int? distancePerRep,
    int? numberOfReps,
    int? totalDistance,
    int? restSeconds,
    String? poolType,
    String? intensity,
    String? notes,
    String? teamId,
    String? goalId,
    int? rpe,
    int? dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      swimmerId: swimmerId ?? this.swimmerId,
      practiceId: practiceId ?? this.practiceId,
      trainingDate: trainingDate ?? this.trainingDate,
      setDescription: setDescription ?? this.setDescription,
      stroke: stroke ?? this.stroke,
      distancePerRep: distancePerRep ?? this.distancePerRep,
      numberOfReps: numberOfReps ?? this.numberOfReps,
      totalDistance: totalDistance ?? this.totalDistance,
      restSeconds: restSeconds ?? this.restSeconds,
      poolType: poolType ?? this.poolType,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      teamId: teamId ?? this.teamId,
      goalId: goalId ?? this.goalId,
      rpe: rpe ?? this.rpe,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      practiceId: json['practice_id'] as String?,
      trainingDate: DateTime.parse(json['training_date'] as String),
      setDescription: json['set_description'] as String,
      stroke: json['stroke'] as String,
      distancePerRep: json['distance_per_rep'] as int,
      numberOfReps: json['number_of_reps'] as int,
      totalDistance: json['total_distance'] as int,
      restSeconds: json['rest_seconds'] as int?,
      poolType: (json['pool_type'] as String?) ?? 'SCY',
      intensity: (json['intensity'] as String?) ?? 'moderate',
      notes: json['notes'] as String?,
      teamId: json['team_id'] as String?,
      goalId: json['goal_id'] as String?,
      rpe: json['rpe'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'practice_id': practiceId,
      'training_date': trainingDate.toIso8601String().split('T')[0],
      'set_description': setDescription,
      'stroke': stroke,
      'distance_per_rep': distancePerRep,
      'number_of_reps': numberOfReps,
      'total_distance': totalDistance,
      'rest_seconds': restSeconds,
      'pool_type': poolType,
      'intensity': intensity,
      'notes': notes,
      'team_id': teamId,
      'goal_id': goalId,
      'rpe': rpe,
      'day_of_week': dayOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if this training session is an interval set
  /// Returns true if the setDescription contains valid interval notation
  /// (e.g., "5x100 on 1:10" returns true, "400 IM" returns false)
  bool isIntervalSet() {
    return IntervalParser.isIntervalSet(setDescription);
  }

  /// Get the interval duration in seconds for this training session
  /// Returns the interval in seconds if this is an interval set, or null for continuous sets
  ///
  /// Examples:
  /// - "5x100 on 1:10" -> 70 seconds
  /// - "10x50 on :45" -> 45 seconds
  /// - "400 IM" -> null (continuous set)
  int? getIntervalSeconds() {
    return IntervalParser.parseIntervalSeconds(setDescription);
  }
}
