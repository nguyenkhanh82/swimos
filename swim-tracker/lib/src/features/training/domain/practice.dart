import 'training_session.dart';

/// A practice (session) that groups multiple sets (e.g. "Monday AM").
class Practice {
  final String id;
  final String userId;
  final String swimmerId;
  final DateTime practiceDate;
  final String? name;
  final String? teamId;
  final String? goalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TrainingSession>? sets;

  const Practice({
    required this.id,
    required this.userId,
    required this.swimmerId,
    required this.practiceDate,
    this.name,
    this.teamId,
    this.goalId,
    required this.createdAt,
    required this.updatedAt,
    this.sets,
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String,
      practiceDate: DateTime.parse(json['practice_date'] as String),
      name: json['name'] as String?,
      teamId: json['team_id'] as String?,
      goalId: json['goal_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sets: json['training_sets'] != null
          ? (json['training_sets'] as List)
              .map((s) => TrainingSession.fromJson(s))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'practice_date': practiceDate.toIso8601String().split('T')[0],
      'name': name,
      'team_id': teamId,
      'goal_id': goalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
