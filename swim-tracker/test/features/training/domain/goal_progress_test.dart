import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/goal_progress.dart';

void main() {
  group('GoalProgress', () {
    test('formattedProgress formats percentage correctly', () {
      final progress = GoalProgress(
        currentValue: 75,
        targetValue: 100,
        progressPercentage: 0.75,
        status: ProgressStatus.inProgress,
      );

      expect(progress.formattedProgress, '75%');
    });

    test('formattedCurrentValue formats integer values', () {
      final progress = GoalProgress(
        currentValue: 50,
        targetValue: 100,
        progressPercentage: 0.5,
        status: ProgressStatus.inProgress,
      );

      expect(progress.formattedCurrentValue, '50');
    });

    test('formattedCurrentValue formats decimal values', () {
      final progress = GoalProgress(
        currentValue: 50.5,
        targetValue: 100,
        progressPercentage: 0.505,
        status: ProgressStatus.inProgress,
      );

      expect(progress.formattedCurrentValue, '50.5');
    });

    test('formattedCurrentValue uses bestTime when available', () {
      final progress = GoalProgress(
        currentValue: 50.5,
        targetValue: 100,
        progressPercentage: 0.505,
        bestTime: '50.50s',
        status: ProgressStatus.inProgress,
      );

      expect(progress.formattedCurrentValue, '50.50s');
    });
  });

  group('ProgressStatus', () {
    test('displayName returns correct string', () {
      expect(ProgressStatus.onTrack.displayName, 'On Track');
      expect(ProgressStatus.inProgress.displayName, 'In Progress');
      expect(ProgressStatus.behind.displayName, 'Behind');
      expect(ProgressStatus.completed.displayName, 'Completed');
      expect(ProgressStatus.notStarted.displayName, 'Not Started');
    });
  });
}
