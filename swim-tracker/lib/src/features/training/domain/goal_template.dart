import 'training_goal.dart';

class GoalTemplate {
  final String id;
  final String name;
  final String category;
  final GoalType goalType;
  final String description;
  final String? iconName;
  final Map<String, dynamic> defaultValues;

  GoalTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.goalType,
    required this.description,
    this.iconName,
    required this.defaultValues,
  });

  factory GoalTemplate.fromJson(Map<String, dynamic> json) {
    return GoalTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      goalType: GoalType.fromString(json['goal_type'] as String),
      description: json['description'] as String,
      iconName: json['icon_name'] as String?,
      defaultValues: Map<String, dynamic>.from(json['default_values'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'goal_type': goalType.value,
      'description': description,
      'icon_name': iconName,
      'default_values': defaultValues,
    };
  }
}

// Predefined goal templates
class GoalTemplates {
  // Time-based templates
  static final List<GoalTemplate> timeTemplates = [
    GoalTemplate(
      id: 'time_50_free',
      name: '50m Freestyle Time',
      category: 'Sprint',
      goalType: GoalType.time,
      description: 'Improve your 50m Freestyle time',
      iconName: 'sprint',
      defaultValues: {
        'stroke': 'Free',
        'distance': 50,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_100_free',
      name: '100m Freestyle Time',
      category: 'Sprint',
      goalType: GoalType.time,
      description: 'Improve your 100m Freestyle time',
      iconName: 'sprint',
      defaultValues: {
        'stroke': 'Free',
        'distance': 100,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_200_free',
      name: '200m Freestyle Time',
      category: 'Middle Distance',
      goalType: GoalType.time,
      description: 'Improve your 200m Freestyle time',
      iconName: 'distance',
      defaultValues: {
        'stroke': 'Free',
        'distance': 200,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_500_free',
      name: '500y Freestyle Time',
      category: 'Distance',
      goalType: GoalType.time,
      description: 'Improve your 500y Freestyle time',
      iconName: 'distance',
      defaultValues: {
        'stroke': 'Free',
        'distance': 500,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_100_back',
      name: '100m Backstroke Time',
      category: 'Sprint',
      goalType: GoalType.time,
      description: 'Improve your 100m Backstroke time',
      iconName: 'backstroke',
      defaultValues: {
        'stroke': 'Back',
        'distance': 100,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_100_breast',
      name: '100m Breaststroke Time',
      category: 'Sprint',
      goalType: GoalType.time,
      description: 'Improve your 100m Breaststroke time',
      iconName: 'breaststroke',
      defaultValues: {
        'stroke': 'Breast',
        'distance': 100,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_100_fly',
      name: '100m Butterfly Time',
      category: 'Sprint',
      goalType: GoalType.time,
      description: 'Improve your 100m Butterfly time',
      iconName: 'butterfly',
      defaultValues: {
        'stroke': 'Fly',
        'distance': 100,
        'pool_type': 'SCY',
      },
    ),
    GoalTemplate(
      id: 'time_200_im',
      name: '200m Individual Medley',
      category: 'IM',
      goalType: GoalType.time,
      description: 'Improve your 200m IM time',
      iconName: 'im',
      defaultValues: {
        'stroke': 'IM',
        'distance': 200,
        'pool_type': 'SCY',
      },
    ),
  ];

  // Distance-based templates
  static final List<GoalTemplate> distanceTemplates = [
    GoalTemplate(
      id: 'distance_weekly_beginner',
      name: 'Weekly Yardage (Beginner)',
      category: 'Training Volume',
      goalType: GoalType.distance,
      description: 'Swim 10,000 yards per week',
      iconName: 'pool',
      defaultValues: {
        'target_distance': 10000,
        'distance_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'distance_weekly_intermediate',
      name: 'Weekly Yardage (Intermediate)',
      category: 'Training Volume',
      goalType: GoalType.distance,
      description: 'Swim 25,000 yards per week',
      iconName: 'pool',
      defaultValues: {
        'target_distance': 25000,
        'distance_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'distance_weekly_advanced',
      name: 'Weekly Yardage (Advanced)',
      category: 'Training Volume',
      goalType: GoalType.distance,
      description: 'Swim 50,000 yards per week',
      iconName: 'pool',
      defaultValues: {
        'target_distance': 50000,
        'distance_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'distance_monthly',
      name: 'Monthly Distance Goal',
      category: 'Training Volume',
      goalType: GoalType.distance,
      description: 'Achieve your monthly yardage target',
      iconName: 'calendar',
      defaultValues: {
        'target_distance': 100000,
        'distance_period': 'monthly',
      },
    ),
  ];

  // Frequency-based templates
  static final List<GoalTemplate> frequencyTemplates = [
    GoalTemplate(
      id: 'frequency_3x_week',
      name: 'Consistent Practice (3x/week)',
      category: 'Consistency',
      goalType: GoalType.frequency,
      description: 'Train 3 times per week',
      iconName: 'calendar',
      defaultValues: {
        'target_frequency': 3,
        'frequency_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'frequency_5x_week',
      name: 'Regular Training (5x/week)',
      category: 'Consistency',
      goalType: GoalType.frequency,
      description: 'Train 5 times per week',
      iconName: 'calendar',
      defaultValues: {
        'target_frequency': 5,
        'frequency_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'frequency_6x_week',
      name: 'Intensive Training (6x/week)',
      category: 'Consistency',
      goalType: GoalType.frequency,
      description: 'Train 6 times per week',
      iconName: 'calendar',
      defaultValues: {
        'target_frequency': 6,
        'frequency_period': 'weekly',
      },
    ),
    GoalTemplate(
      id: 'frequency_monthly',
      name: 'Monthly Practice Sessions',
      category: 'Consistency',
      goalType: GoalType.frequency,
      description: 'Complete 20 practice sessions this month',
      iconName: 'calendar',
      defaultValues: {
        'target_frequency': 20,
        'frequency_period': 'monthly',
      },
    ),
  ];

  // Custom templates
  static final List<GoalTemplate> customTemplates = [
    GoalTemplate(
      id: 'custom_dryland',
      name: 'Dryland Training Sessions',
      category: 'Strength',
      goalType: GoalType.custom,
      description: 'Track dryland/strength training sessions',
      iconName: 'fitness',
      defaultValues: {
        'custom_unit': 'sessions',
      },
    ),
    GoalTemplate(
      id: 'custom_stretching',
      name: 'Flexibility Sessions',
      category: 'Recovery',
      goalType: GoalType.custom,
      description: 'Track stretching and flexibility work',
      iconName: 'stretch',
      defaultValues: {
        'custom_unit': 'sessions',
      },
    ),
  ];

  static List<GoalTemplate> getAllTemplates() {
    return [
      ...timeTemplates,
      ...distanceTemplates,
      ...frequencyTemplates,
      ...customTemplates,
    ];
  }

  static List<GoalTemplate> getTemplatesByType(GoalType type) {
    return getAllTemplates().where((t) => t.goalType == type).toList();
  }

  static List<GoalTemplate> getTemplatesByCategory(String category) {
    return getAllTemplates().where((t) => t.category == category).toList();
  }
}
