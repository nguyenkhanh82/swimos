class ProgressEntry {
  final String id;
  final String goalId;
  final String userId;
  final String? swimmerId;
  final double progressValue;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgressEntry({
    required this.id,
    required this.goalId,
    required this.userId,
    this.swimmerId,
    required this.progressValue,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      progressValue: (json['progress_value'] as num).toDouble(),
      notes: json['notes'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'progress_value': progressValue,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProgressEntry copyWith({
    String? id,
    String? goalId,
    String? userId,
    String? swimmerId,
    double? progressValue,
    String? notes,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      swimmerId: swimmerId ?? this.swimmerId,
      progressValue: progressValue ?? this.progressValue,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
