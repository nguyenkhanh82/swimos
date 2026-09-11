class TrainingPractice {
  final String id;
  final String goalId;
  final String swimmerId;
  final String setDescription;
  final String stroke;
  final int distancePerRep;
  final int numberOfReps;
  final int totalDistance;
  final int restSeconds;
  final String intensity;
  final String rationale;
  final DateTime createdAt;

  TrainingPractice({
    required this.id,
    required this.goalId,
    required this.swimmerId,
    required this.setDescription,
    required this.stroke,
    required this.distancePerRep,
    required this.numberOfReps,
    required this.totalDistance,
    required this.restSeconds,
    required this.intensity,
    required this.rationale,
    required this.createdAt,
  });

  factory TrainingPractice.fromJson(Map<String, dynamic> json) {
    return TrainingPractice(
      id: json['id'] as String? ?? '',
      goalId: json['goal_id'] as String? ?? '',
      swimmerId: json['swimmer_id'] as String,
      setDescription: json['set_description'] as String,
      stroke: json['stroke'] as String,
      distancePerRep: json['distance_per_rep'] as int,
      numberOfReps: json['number_of_reps'] as int,
      totalDistance: json['total_distance'] as int,
      restSeconds: json['rest_seconds'] as int,
      intensity: json['intensity'] as String,
      rationale: json['rationale'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'swimmer_id': swimmerId,
      'set_description': setDescription,
      'stroke': stroke,
      'distance_per_rep': distancePerRep,
      'number_of_reps': numberOfReps,
      'total_distance': totalDistance,
      'rest_seconds': restSeconds,
      'intensity': intensity,
      'rationale': rationale,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper to convert to TrainingSession for saving to training log
  Map<String, dynamic> toTrainingSessionData({
    required String userId,
    required DateTime trainingDate,
    String? teamId,
  }) {
    return {
      'user_id': userId,
      'swimmer_id': swimmerId,
      'training_date': trainingDate.toIso8601String().split('T')[0],
      'set_description': setDescription,
      'stroke': stroke,
      'distance_per_rep': distancePerRep,
      'number_of_reps': numberOfReps,
      'total_distance': totalDistance,
      'rest_seconds': restSeconds,
      'pool_type': 'SCY', // Default, can be overridden
      'intensity': intensity,
      'notes': rationale,
      'team_id': teamId,
    };
  }
}
