import '../domain/time_standard.dart';

/// Service to calculate percentage distribution of swimmers achieving each time standard
/// Based on typical USA Swimming statistics
class TimeStandardsDistributionService {
  /// Get distribution percentages for each standard level
  /// Returns a map of StandardLevel to percentage (0.0 to 1.0)
  Map<StandardLevel, double> getDistributionPercentages() {
    return {
      StandardLevel.b: 0.50,      // ~50% of swimmers achieve B
      StandardLevel.bb: 0.30,     // ~30% of swimmers achieve BB
      StandardLevel.a: 0.12,      // ~12% of swimmers achieve A
      StandardLevel.aa: 0.05,     // ~5% of swimmers achieve AA
      StandardLevel.aaa: 0.02,    // ~2% of swimmers achieve AAA
      StandardLevel.aaaa: 0.008,  // ~0.8% of swimmers achieve AAAA
      StandardLevel.aaaaa: 0.002, // ~0.2% of swimmers achieve AAAAA
    };
  }

  /// Get cumulative distribution (percentage of swimmers achieving at least this standard)
  /// For example, if 50% achieve B and 30% achieve BB, then:
  /// - At least B: 100% (everyone)
  /// - At least BB: 50% (those who achieve BB or better)
  /// - At least A: 20% (those who achieve A or better)
  Map<StandardLevel, double> getCumulativeDistribution() {
    final percentages = getDistributionPercentages();
    final cumulative = <StandardLevel, double>{};
    
    // Order from slowest to fastest
    final levels = [
      StandardLevel.b,
      StandardLevel.bb,
      StandardLevel.a,
      StandardLevel.aa,
      StandardLevel.aaa,
      StandardLevel.aaaa,
      StandardLevel.aaaaa,
    ];
    
    double cumulativePercent = 1.0; // 100% achieve at least nothing (everyone starts)
    
    for (final level in levels) {
      cumulative[level] = cumulativePercent;
      cumulativePercent -= percentages[level] ?? 0.0;
    }
    
    return cumulative;
  }

  /// Get percentage for a specific standard level
  double getPercentageForStandard(StandardLevel level) {
    return getDistributionPercentages()[level] ?? 0.0;
  }

  /// Format percentage as string (e.g., "50%", "0.8%")
  String formatPercentage(double percentage) {
    if (percentage >= 1.0) {
      return '${(percentage * 100).toStringAsFixed(0)}%';
    } else if (percentage >= 0.01) {
      return '${(percentage * 100).toStringAsFixed(1)}%';
    } else {
      return '${(percentage * 100).toStringAsFixed(2)}%';
    }
  }

  /// Get distribution data for visualization
  /// Returns list of standard info with percentages, ordered from slowest to fastest
  List<StandardDistributionInfo> getDistributionInfo() {
    final percentages = getDistributionPercentages();
    final cumulative = getCumulativeDistribution();
    
    final levels = [
      StandardLevel.b,
      StandardLevel.bb,
      StandardLevel.a,
      StandardLevel.aa,
      StandardLevel.aaa,
      StandardLevel.aaaa,
      StandardLevel.aaaaa,
    ];
    
    return levels.map((level) {
      return StandardDistributionInfo(
        level: level,
        percentage: percentages[level] ?? 0.0,
        cumulativePercentage: cumulative[level] ?? 0.0,
      );
    }).toList();
  }
}

class StandardDistributionInfo {
  final StandardLevel level;
  final double percentage; // Percentage achieving exactly this standard
  final double cumulativePercentage; // Percentage achieving at least this standard

  StandardDistributionInfo({
    required this.level,
    required this.percentage,
    required this.cumulativePercentage,
  });
}
