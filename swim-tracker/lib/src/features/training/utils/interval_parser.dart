/// Utility functions for parsing interval notation from swim set descriptions.
///
/// Supports formats like "5x100 on 1:10", "10x50 on :45", "3x200 on 2:30".
/// Returns null for continuous sets (e.g., "400 IM") without interval notation.
class IntervalParser {
  /// Parse interval notation from set description
  /// Returns interval duration in seconds, or null if not an interval set
  ///
  /// Supported formats:
  /// - "on 1:10" -> 70 seconds (1 minute 10 seconds)
  /// - "on :45" -> 45 seconds
  /// - "on 2:30" -> 150 seconds (2 minutes 30 seconds)
  ///
  /// Examples:
  /// - "5x100 on 1:10" -> 70
  /// - "10x50 on :45" -> 45
  /// - "3x200 on 2:30" -> 150
  /// - "400 IM" -> null (continuous set)
  /// - "8x100 Free" -> null (no interval notation)
  static int? parseIntervalSeconds(String setDescription) {
    if (setDescription.trim().isEmpty) return null;

    // Pattern: "on X:XX" or "on :XX" or "on XX"
    // Matches: "on 1:10", "on :45", "on 90"
    final regex = RegExp(r'on\s+(\d+)?:?(\d+)', caseSensitive: false);
    final match = regex.firstMatch(setDescription);
    if (match == null) return null;

    final group1 = match.group(1);
    final group2 = match.group(2);

    // Handle different formats:
    // "on 1:10" -> group1="1", group2="10" -> 70 seconds
    // "on :45" -> group1=null, group2="45" -> 45 seconds
    // "on 90" -> group1=null, group2="90" -> 90 seconds
    if (setDescription.contains(':')) {
      // Format with colon: minutes:seconds
      final minutes = int.tryParse(group1 ?? '0') ?? 0;
      final seconds = int.tryParse(group2 ?? '0') ?? 0;
      return minutes * 60 + seconds;
    } else {
      // Format without colon: just seconds
      final seconds = int.tryParse(group2 ?? '0') ?? 0;
      return seconds > 0 ? seconds : null;
    }
  }

  /// Check if a set description represents an interval set
  /// Returns true if the description contains valid interval notation
  static bool isIntervalSet(String setDescription) {
    return parseIntervalSeconds(setDescription) != null;
  }

  /// Format interval seconds as a display string (M:SS format)
  ///
  /// Examples:
  /// - 70 -> "1:10"
  /// - 45 -> "0:45"
  /// - 150 -> "2:30"
  static String formatInterval(int seconds) {
    if (seconds <= 0) return '0:00';

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Format interval for countdown display (shows remaining time)
  /// Returns formatted string like "0:45" or "1:10"
  static String formatCountdown(double remainingSeconds) {
    if (remainingSeconds <= 0) return '0:00';

    final totalSeconds = remainingSeconds.ceil();
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Extract the interval notation from a set description
  /// Returns the matched portion (e.g., "on 1:10") or null if not found
  static String? extractIntervalNotation(String setDescription) {
    if (setDescription.trim().isEmpty) return null;

    final regex = RegExp(r'on\s+\d*:?\d+', caseSensitive: false);
    final match = regex.firstMatch(setDescription);
    return match?.group(0);
  }

  /// Create a formatted display string for interval mode
  /// Example: "5x100 on 1:10" -> "5x100 @ 1:10"
  static String formatIntervalModeDisplay(
    String setDescription,
    int intervalSeconds,
  ) {
    final intervalStr = formatInterval(intervalSeconds);

    // Try to extract the set portion before "on"
    final onIndex = setDescription.toLowerCase().indexOf('on');
    if (onIndex > 0) {
      final setPortion = setDescription.substring(0, onIndex).trim();
      return '$setPortion @ $intervalStr';
    }

    // Fallback: just show the interval
    return '@ $intervalStr';
  }
}
