class GoalProgress {
  final double currentValue;
  final double targetValue;
  final double progressPercentage;
  final String? bestTime; // Formatted time string for time goals
  final String? recentTime; // Formatted time string for recent swim
  final ProgressStatus status;
  final String? statusMessage;
  final int? daysRemaining;

  GoalProgress({
    required this.currentValue,
    required this.targetValue,
    required this.progressPercentage,
    this.bestTime,
    this.recentTime,
    required this.status,
    this.statusMessage,
    this.daysRemaining,
  });

  String get formattedProgress => '${(progressPercentage * 100).toStringAsFixed(0)}%';

  String get formattedCurrentValue {
    if (bestTime != null) return bestTime!;
    if (currentValue % 1 == 0) {
      return currentValue.toInt().toString();
    }
    return currentValue.toStringAsFixed(1);
  }

  String get formattedTargetValue {
    if (targetValue % 1 == 0) {
      return targetValue.toInt().toString();
    }
    return targetValue.toStringAsFixed(1);
  }
}

enum ProgressStatus {
  onTrack,
  inProgress,
  behind,
  completed,
  notStarted,
}

extension ProgressStatusExtension on ProgressStatus {
  String get displayName {
    switch (this) {
      case ProgressStatus.onTrack:
        return 'On Track';
      case ProgressStatus.inProgress:
        return 'In Progress';
      case ProgressStatus.behind:
        return 'Behind';
      case ProgressStatus.completed:
        return 'Completed';
      case ProgressStatus.notStarted:
        return 'Not Started';
    }
  }

  String get colorHex {
    switch (this) {
      case ProgressStatus.onTrack:
        return '0xFF0EA5E9'; // Blue
      case ProgressStatus.inProgress:
        return '0xFFFFA500'; // Orange
      case ProgressStatus.behind:
        return '0xFFFF4444'; // Red
      case ProgressStatus.completed:
        return '0xFF10B981'; // Green
      case ProgressStatus.notStarted:
        return '0xFF94A3B8'; // Gray
    }
  }
}
