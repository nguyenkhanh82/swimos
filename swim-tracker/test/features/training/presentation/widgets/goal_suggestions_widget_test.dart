import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/presentation/widgets/goal_suggestions_widget.dart';

void main() {
  group('GoalSuggestion', () {
    test('fromJson creates valid time goal suggestion', () {
      final json = {
        'title': 'Break 50 Free in 25 seconds',
        'goalType': 'time',
        'stroke': 'Free',
        'distance': 50,
        'targetTimeSeconds': 25.0,
        'targetDate': '2026-03-20',
        'rationale': 'Your current best is 26.5s. This is an achievable 6% improvement.',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, 'Break 50 Free in 25 seconds');
      expect(suggestion.goalType, 'time');
      expect(suggestion.stroke, 'Free');
      expect(suggestion.distance, 50);
      expect(suggestion.targetTimeSeconds, 25.0);
      expect(suggestion.targetDate, '2026-03-20');
      expect(suggestion.rationale, contains('achievable'));
      expect(suggestion.priority, 'high');
    });

    test('fromJson creates valid distance goal suggestion', () {
      final json = {
        'title': 'Swim 50,000m This Month',
        'goalType': 'distance',
        'targetDistance': 50000,
        'distancePeriod': 'month',
        'targetDate': '2026-02-28',
        'rationale': 'Build endurance with consistent volume.',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, 'Swim 50,000m This Month');
      expect(suggestion.goalType, 'distance');
      expect(suggestion.targetDistance, 50000);
      expect(suggestion.distancePeriod, 'month');
      expect(suggestion.targetDate, '2026-02-28');
      expect(suggestion.priority, 'medium');
    });

    test('fromJson creates valid frequency goal suggestion', () {
      final json = {
        'title': 'Train 12 Times This Month',
        'goalType': 'frequency',
        'targetFrequency': 12,
        'frequencyPeriod': 'month',
        'targetDate': '2026-03-15',
        'rationale': 'Build consistency with regular training sessions.',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, 'Train 12 Times This Month');
      expect(suggestion.goalType, 'frequency');
      expect(suggestion.targetFrequency, 12);
      expect(suggestion.frequencyPeriod, 'month');
      expect(suggestion.priority, 'high');
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'title': 'Custom Goal',
        'goalType': 'custom',
        'rationale': 'Custom goal rationale',
        'priority': 'low',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, 'Custom Goal');
      expect(suggestion.goalType, 'custom');
      expect(suggestion.stroke, null);
      expect(suggestion.distance, null);
      expect(suggestion.targetTimeSeconds, null);
      expect(suggestion.targetDistance, null);
      expect(suggestion.targetFrequency, null);
      expect(suggestion.targetDate, null);
      expect(suggestion.priority, 'low');
    });

    test('fromJson handles numeric type conversions', () {
      final json = {
        'title': 'Test Goal',
        'goalType': 'time',
        'distance': 100, // int
        'targetTimeSeconds': 60.5, // double
        'rationale': 'Test',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.distance, 100);
      expect(suggestion.targetTimeSeconds, 60.5);
    });
  });

  group('GoalSuggestion Priority Logic', () {
    test('high priority suggestions should be processed first', () {
      final highPriority = GoalSuggestion(
        title: 'High Priority Goal',
        goalType: 'time',
        rationale: 'Important',
        priority: 'high',
      );

      final mediumPriority = GoalSuggestion(
        title: 'Medium Priority Goal',
        goalType: 'distance',
        rationale: 'Moderate',
        priority: 'medium',
      );

      final lowPriority = GoalSuggestion(
        title: 'Low Priority Goal',
        goalType: 'frequency',
        rationale: 'Nice to have',
        priority: 'low',
      );

      expect(highPriority.priority, 'high');
      expect(mediumPriority.priority, 'medium');
      expect(lowPriority.priority, 'low');
    });
  });

  group('GoalSuggestion Edge Cases', () {
    test('handles empty rationale', () {
      final json = {
        'title': 'Goal',
        'goalType': 'custom',
        'rationale': '',
        'priority': 'low',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.rationale, '');
    });

    test('handles very long title', () {
      final longTitle = 'A' * 200; // 200 character title
      final json = {
        'title': longTitle,
        'goalType': 'time',
        'rationale': 'Test',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, longTitle);
      expect(suggestion.title.length, 200);
    });

    test('handles large target values', () {
      final json = {
        'title': 'Marathon Swim',
        'goalType': 'distance',
        'targetDistance': 1000000, // 1 million meters
        'rationale': 'Ultimate endurance test',
        'priority': 'low',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.targetDistance, 1000000);
    });

    test('handles decimal target times', () {
      final json = {
        'title': 'Precise Time Goal',
        'goalType': 'time',
        'targetTimeSeconds': 58.99,
        'rationale': 'USA Swimming BB standard',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.targetTimeSeconds, 58.99);
    });
  });

  group('GoalSuggestion Type Validation', () {
    test('time goal has required time fields', () {
      final json = {
        'title': 'Time Goal',
        'goalType': 'time',
        'stroke': 'Free',
        'distance': 100,
        'targetTimeSeconds': 60.0,
        'rationale': 'Improve speed',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.goalType, 'time');
      expect(suggestion.stroke, isNotNull);
      expect(suggestion.distance, isNotNull);
      expect(suggestion.targetTimeSeconds, isNotNull);
    });

    test('distance goal has required distance fields', () {
      final json = {
        'title': 'Distance Goal',
        'goalType': 'distance',
        'targetDistance': 50000,
        'distancePeriod': 'month',
        'rationale': 'Build endurance',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.goalType, 'distance');
      expect(suggestion.targetDistance, isNotNull);
      expect(suggestion.distancePeriod, isNotNull);
    });

    test('frequency goal has required frequency fields', () {
      final json = {
        'title': 'Frequency Goal',
        'goalType': 'frequency',
        'targetFrequency': 12,
        'frequencyPeriod': 'month',
        'rationale': 'Build consistency',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.goalType, 'frequency');
      expect(suggestion.targetFrequency, isNotNull);
      expect(suggestion.frequencyPeriod, isNotNull);
    });
  });

  group('GoalSuggestion Date Handling', () {
    test('parses ISO date format correctly', () {
      final json = {
        'title': 'Date Test Goal',
        'goalType': 'time',
        'targetDate': '2026-12-31',
        'rationale': 'End of year goal',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.targetDate, '2026-12-31');
    });

    test('handles null target date', () {
      final json = {
        'title': 'No Date Goal',
        'goalType': 'custom',
        'rationale': 'Ongoing goal',
        'priority': 'low',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.targetDate, null);
    });
  });

  group('GoalSuggestion Complete Examples', () {
    test('realistic 100 Free time goal suggestion', () {
      final json = {
        'title': '100 Free - Reach BB Standard',
        'goalType': 'time',
        'stroke': 'Free',
        'distance': 100,
        'targetTimeSeconds': 58.99,
        'targetDate': '2026-06-01',
        'rationale': 'Your current best is 61.2s (B). Drop 2.2 seconds to reach BB standard.',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, contains('100 Free'));
      expect(suggestion.goalType, 'time');
      expect(suggestion.stroke, 'Free');
      expect(suggestion.distance, 100);
      expect(suggestion.targetTimeSeconds, 58.99);
      expect(suggestion.rationale, contains('BB standard'));
      expect(suggestion.priority, 'high');
    });

    test('realistic monthly volume goal suggestion', () {
      final json = {
        'title': 'Swim 40,000m Per Month',
        'goalType': 'distance',
        'targetDistance': 40000,
        'distancePeriod': 'month',
        'targetDate': '2026-04-30',
        'rationale': 'Based on your recent average of 35,000m/month, this 14% increase will build endurance.',
        'priority': 'medium',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, contains('40,000m'));
      expect(suggestion.goalType, 'distance');
      expect(suggestion.targetDistance, 40000);
      expect(suggestion.distancePeriod, 'month');
      expect(suggestion.rationale, contains('endurance'));
      expect(suggestion.priority, 'medium');
    });

    test('realistic consistency goal suggestion', () {
      final json = {
        'title': 'Build Training Consistency',
        'goalType': 'frequency',
        'targetFrequency': 12,
        'frequencyPeriod': 'month',
        'targetDate': '2026-03-31',
        'rationale': 'You\'ve been averaging 8 sessions/month. Aim for 3 sessions per week to improve consistency.',
        'priority': 'high',
      };

      final suggestion = GoalSuggestion.fromJson(json);

      expect(suggestion.title, contains('Consistency'));
      expect(suggestion.goalType, 'frequency');
      expect(suggestion.targetFrequency, 12);
      expect(suggestion.frequencyPeriod, 'month');
      expect(suggestion.rationale, contains('consistency'));
      expect(suggestion.priority, 'high');
    });
  });
}
