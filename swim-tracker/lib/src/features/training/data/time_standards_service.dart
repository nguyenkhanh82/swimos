import '../domain/time_standard.dart';
import 'time_standards_repository.dart';

class TimeStandardsService {
  final TimeStandardsRepository _repository;

  TimeStandardsService(this._repository);

  /// Calculate swimmer's current standard and next achievable standard
  Future<SwimmerStandardInfo> calculateStandardInfo({
    required double currentTime,
    required String gender,
    required String ageGroup,
    required String stroke,
    required int distance,
    required String course,
  }) async {
    // Get all standards for this event
    final standards = await _repository.getStandardsByStrokeDistance(
      gender: gender,
      ageGroup: ageGroup,
      stroke: stroke,
      distance: distance,
      course: course,
    );

    if (standards.isEmpty) {
      return SwimmerStandardInfo(
        currentTime: currentTime,
        event: '$distance $stroke',
        ageGroup: ageGroup,
        gender: gender,
        course: course,
      );
    }

    // Sort standards from slowest to fastest (B to AAAAA)
    standards.sort((a, b) => b.timeSeconds.compareTo(a.timeSeconds));

    StandardLevel? currentStandard;
    StandardLevel? nextStandard;
    double? timeToNextStandard;

    // Find the highest standard achieved (continue checking all standards)
    for (final standard in standards) {
      if (currentTime <= standard.timeSeconds) {
        // Swimmer has achieved this standard, keep checking for higher standards
        currentStandard = standard.standardLevel;
      }
    }

    // If a standard was achieved, find the next one
    if (currentStandard != null) {
      final nextLevel = currentStandard.nextLevel;
      if (nextLevel != null) {
        // Find the time standard for the next level
        final nextStandardTime = standards.firstWhere(
          (s) => s.standardLevel == nextLevel,
          orElse: () => standards.first,
        );
        nextStandard = nextLevel;
        timeToNextStandard = currentTime - nextStandardTime.timeSeconds;
      }
    }

    // If no standard achieved yet, the next standard is B
    if (currentStandard == null && standards.isNotEmpty) {
      final bStandard = standards.firstWhere(
        (s) => s.standardLevel == StandardLevel.b,
        orElse: () => standards.last,
      );
      nextStandard = StandardLevel.b;
      timeToNextStandard = currentTime - bStandard.timeSeconds;
    }

    return SwimmerStandardInfo(
      currentTime: currentTime,
      currentStandard: currentStandard,
      nextStandard: nextStandard,
      timeToNextStandard: timeToNextStandard,
      event: '$distance $stroke',
      ageGroup: ageGroup,
      gender: gender,
      course: course,
    );
  }

  /// Get suggested goal based on current best time
  Future<double?> getSuggestedGoalTime({
    required double currentBestTime,
    required String gender,
    required String ageGroup,
    required String stroke,
    required int distance,
    required String course,
  }) async {
    final standardInfo = await calculateStandardInfo(
      currentTime: currentBestTime,
      gender: gender,
      ageGroup: ageGroup,
      stroke: stroke,
      distance: distance,
      course: course,
    );

    if (standardInfo.nextStandard != null) {
      // Get the time for the next standard
      final nextStandardTime = await _repository.getStandard(
        gender: gender,
        ageGroup: ageGroup,
        course: course,
        event: '$distance $stroke',
        standardLevel: standardInfo.nextStandard!,
      );

      return nextStandardTime?.timeSeconds;
    }

    // If at max level, suggest 1% improvement
    return currentBestTime * 0.99;
  }

  /// Format time difference for display
  String formatTimeDifference(double seconds) {
    final absSeconds = seconds.abs();
    final isNegative = seconds < 0;

    final formattedTime = absSeconds >= 60
        ? '${(absSeconds / 60).floor()}:${(absSeconds % 60).toStringAsFixed(2).padLeft(5, '0')}'
        : '${absSeconds.toStringAsFixed(2)}s';

    return isNegative ? '-$formattedTime' : formattedTime;
  }
}
