class DailyMacroTarget {
  final String id;
  final String userId;
  final String swimmerId;
  final int caloriesTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final int sugarTarget;
  final DateTime updatedAt;

  const DailyMacroTarget({
    required this.id,
    required this.userId,
    required this.swimmerId,
    this.caloriesTarget = 2500,
    this.proteinTarget = 150,
    this.carbsTarget = 300,
    this.fatTarget = 75,
    this.sugarTarget = 50,
    required this.updatedAt,
  });

  factory DailyMacroTarget.fromJson(Map<String, dynamic> json) {
    return DailyMacroTarget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String,
      caloriesTarget: json['calories_target'] as int? ?? 2500,
      proteinTarget: json['protein_target'] as int? ?? 150,
      carbsTarget: json['carbs_target'] as int? ?? 300,
      fatTarget: json['fat_target'] as int? ?? 75,
      sugarTarget: json['sugar_target'] as int? ?? 50,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'calories_target': caloriesTarget,
      'protein_target': proteinTarget,
      'carbs_target': carbsTarget,
      'fat_target': fatTarget,
      'sugar_target': sugarTarget,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
