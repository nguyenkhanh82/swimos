import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/training_goal.dart';

void main() {
  group('TrainingGoal', () {
    test('fromJson creates TrainingGoal with time goal fields', () {
      final json = {
        'id': 'goal-1',
        'user_id': 'user-1',
        'team_id': null,
        'goal_type': 'time',
        'title': '100m Freestyle Goal',
        'description': 'Break 50 seconds',
        'stroke': 'Free',
        'distance': 100,
        'pool_type': 'SCY',
        'target_time_seconds': 50.0,
        'target_date': '2024-12-31',
        'status': 'active',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final goal = TrainingGoal.fromJson(json);

      expect(goal.id, 'goal-1');
      expect(goal.userId, 'user-1');
      expect(goal.teamId, isNull);
      expect(goal.goalType, GoalType.time);
      expect(goal.title, '100m Freestyle Goal');
      expect(goal.stroke, 'Free');
      expect(goal.distance, 100);
      expect(goal.poolType, 'SCY');
      expect(goal.targetTimeSeconds, 50.0);
      expect(goal.targetDate, DateTime.parse('2024-12-31'));
    });

    test('fromJson creates TrainingGoal with distance goal fields', () {
      final json = {
        'id': 'goal-2',
        'user_id': 'user-1',
        'goal_type': 'distance',
        'title': 'Weekly Distance Goal',
        'target_distance': 5000,
        'distance_period': 'weekly',
        'status': 'active',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final goal = TrainingGoal.fromJson(json);

      expect(goal.goalType, GoalType.distance);
      expect(goal.targetDistance, 5000);
      expect(goal.distancePeriod, 'weekly');
    });

    test('toJson converts TrainingGoal to JSON', () {
      final goal = TrainingGoal(
        id: 'goal-1',
        userId: 'user-1',
        goalType: GoalType.frequency,
        title: 'Training Frequency',
        targetFrequency: 4,
        frequencyPeriod: 'weekly',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = goal.toJson();

      expect(json['id'], 'goal-1');
      expect(json['goal_type'], 'frequency');
      expect(json['target_frequency'], 4);
      expect(json['frequency_period'], 'weekly');
    });
  });

  group('GoalType', () {
    test('fromString returns correct GoalType', () {
      expect(GoalType.fromString('time'), GoalType.time);
      expect(GoalType.fromString('distance'), GoalType.distance);
      expect(GoalType.fromString('frequency'), GoalType.frequency);
      expect(GoalType.fromString('custom'), GoalType.custom);
    });

    test('fromString returns custom as default for invalid values', () {
      expect(GoalType.fromString('invalid'), GoalType.custom);
    });
  });

  group('GoalStatus', () {
    test('fromString returns correct GoalStatus', () {
      expect(GoalStatus.fromString('active'), GoalStatus.active);
      expect(GoalStatus.fromString('completed'), GoalStatus.completed);
      expect(GoalStatus.fromString('paused'), GoalStatus.paused);
      expect(GoalStatus.fromString('archived'), GoalStatus.archived);
    });

    test('fromString returns active as default for invalid values', () {
      expect(GoalStatus.fromString('invalid'), GoalStatus.active);
    });
  });
}
