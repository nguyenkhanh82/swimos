class NutritionLog {
  final String id;
  final String userId;
  final String swimmerId;
  final DateTime logDate;
  final String mealType;
  final String? description;
  final String? imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int sugar;
  final DateTime createdAt;

  NutritionLog({
    required this.id,
    required this.userId,
    required this.swimmerId,
    required this.logDate,
    required this.mealType,
    this.description,
    this.imageUrl,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sugar = 0,
    required this.createdAt,
  });

  factory NutritionLog.fromJson(Map<String, dynamic> json) {
    return NutritionLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      mealType: json['meal_type'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
      sugar: json['sugar'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'meal_type': mealType,
      'description': description,
      'image_url': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
