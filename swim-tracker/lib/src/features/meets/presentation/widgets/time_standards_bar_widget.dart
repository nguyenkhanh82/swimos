import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../training/domain/time_standard.dart';
import '../../../training/data/time_standards_distribution_service.dart';

/// Widget that displays a horizontal bar showing time standards with swimmer's position
/// and percentage distribution for each standard
class TimeStandardsBarWidget extends StatelessWidget {
  final double swimmerTime;
  final List<TimeStandard> standards;
  final String eventName;
  final TimeStandardsDistributionService? distributionService;

  const TimeStandardsBarWidget({
    super.key,
    required this.swimmerTime,
    required this.standards,
    required this.eventName,
    this.distributionService,
  });

  @override
  Widget build(BuildContext context) {
    if (standards.isEmpty) {
      return const SizedBox.shrink();
    }

    final service = distributionService ?? TimeStandardsDistributionService();
    final distributionInfo = service.getDistributionInfo();

    // Sort standards from slowest (highest time) to fastest (lowest time)
    final sortedStandards = List<TimeStandard>.from(standards)
      ..sort((a, b) => b.timeSeconds.compareTo(a.timeSeconds));

    // Find the range of times (slowest to fastest)
    final slowestTime = sortedStandards.first.timeSeconds;
    final fastestTime = sortedStandards.last.timeSeconds;
    final timeRange = slowestTime - fastestTime;

    // Calculate swimmer's position (0.0 = slowest, 1.0 = fastest)
    double swimmerPosition;
    if (swimmerTime >= slowestTime) {
      swimmerPosition = 0.0; // Below B standard
    } else if (swimmerTime <= fastestTime) {
      swimmerPosition = 1.0; // Faster than top standard (AAAA)
    } else {
      swimmerPosition = (slowestTime - swimmerTime) / timeRange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event name
            Text(
              eventName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            
            // Current time display
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(swimmerTime),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Standards bar
            _buildStandardsBar(
              sortedStandards,
              swimmerTime,
              swimmerPosition,
              slowestTime,
              fastestTime,
            ),
            const SizedBox(height: 12),

            // Percentage labels
            _buildPercentageLabels(distributionInfo, sortedStandards),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardsBar(
    List<TimeStandard> sortedStandards,
    double swimmerTime,
    double swimmerPosition,
    double slowestTime,
    double fastestTime,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        const barHeight = 40.0;
        
        return Stack(
          children: [
            // Background bar container
            SizedBox(
              width: barWidth,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: _buildStandardSegments(
                      sortedStandards,
                      slowestTime,
                      fastestTime,
                      barWidth,
                      barHeight,
                    ),
                  ),
                ),
              ),
            ),
            
            // Swimmer's time indicator
            Positioned(
              left: swimmerPosition * barWidth - 1,
              child: Container(
                width: 2,
                height: barHeight + 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            
            // Swimmer time label above indicator
            if (swimmerPosition >= 0 && swimmerPosition <= 1)
              Positioned(
                left: (swimmerPosition * barWidth) - 30,
                top: -20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTime(swimmerTime),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildStandardSegments(
    List<TimeStandard> sortedStandards,
    double slowestTime,
    double fastestTime,
    double barWidth,
    double barHeight,
  ) {
    final segments = <Widget>[];
    final timeRange = slowestTime - fastestTime;

    for (int i = 0; i < sortedStandards.length; i++) {
      final standard = sortedStandards[i];
      final nextStandard = i < sortedStandards.length - 1
          ? sortedStandards[i + 1]
          : null;

      // Segment spans from this standard's time down to the next (or fastest).
      final segmentDuration = nextStandard != null
          ? slowestTime - nextStandard.timeSeconds
          : standard.timeSeconds - fastestTime;
      final flex = timeRange > 0 && segmentDuration > 0
          ? (segmentDuration / timeRange * 1000).round().clamp(1, 1000)
          : 1;

      segments.add(
        Expanded(
          flex: flex,
          child: Container(
            height: barHeight,
            color: _getStandardColor(standard.standardLevel).withValues(alpha: 0.7),
            child: Center(
              child: Text(
                standard.standardLevel.value,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return segments;
  }

  Widget _buildPercentageLabels(
    List<StandardDistributionInfo> distributionInfo,
    List<TimeStandard> sortedStandards,
  ) {
    // Create a map of standard level to distribution info
    final distributionMap = {
      for (var info in distributionInfo) info.level: info
    };

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sortedStandards.map((standard) {
        final distInfo = distributionMap[standard.standardLevel];
        if (distInfo == null) return const SizedBox.shrink();

        final service = distributionService ?? TimeStandardsDistributionService();
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getStandardColor(standard.standardLevel),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${standard.standardLevel.value}: ${service.formatPercentage(distInfo.percentage)}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStandardColor(StandardLevel level) {
    switch (level) {
      case StandardLevel.b:
        return const Color(0xFF94A3B8); // Gray
      case StandardLevel.bb:
        return const Color(0xFF64748B); // Slate
      case StandardLevel.a:
        return const Color(0xFF3B82F6); // Blue
      case StandardLevel.aa:
        return const Color(0xFF8B5CF6); // Purple
      case StandardLevel.aaa:
        return const Color(0xFFF59E0B); // Amber
      case StandardLevel.aaaa:
        return const Color(0xFFEF4444); // Red
      case StandardLevel.aaaaa:
        return const Color(0xFFDC2626); // Dark red (kept for compatibility; motivational is B–AAAA)
    }
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${secs.toStringAsFixed(2)}s';
  }
}
