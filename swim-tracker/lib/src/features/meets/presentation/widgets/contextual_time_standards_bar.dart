import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../training/domain/time_standard.dart';

/// One segment in the bar: label + time (motivational or national tier).
class _BarSegment {
  final String label;
  final double timeSeconds;
  final bool isNationalTier;

  _BarSegment({required this.label, required this.timeSeconds, required this.isNationalTier});
}

/// Contextual time standards bar: shows only relevant standards
/// (previous + current + next 2) with time cuts, "Current", and "Next goal" labels.
/// Supports motivational B–AAAA and optional national tiers (Sectional, Futures, Junior National, National).
/// Blue gradient fill to swimmer position, circular marker, grey for unachieved.
/// When [onNextGoalTap] is set, tapping "Next goal" calls it with the target time and standard label (add to training suggestions).
class ContextualTimeStandardsBar extends StatelessWidget {
  final double swimmerTime;
  final List<TimeStandard> standards;
  /// Optional national-level cuts (Sectional, Futures, Junior National, National). Shown after AAAA when provided.
  final List<NationalTierStandard> nationalTierStandards;
  /// Called when user taps "Next goal" with (targetTimeSeconds, standardLabel). Use to add goal to training suggestions.
  final void Function(double targetTimeSeconds, String standardLabel)? onNextGoalTap;
  static const int _maxVisible = 4;

  ContextualTimeStandardsBar({
    super.key,
    required this.swimmerTime,
    required this.standards,
    List<NationalTierStandard>? nationalTierStandards,
    this.onNextGoalTap,
  }) : nationalTierStandards = nationalTierStandards ?? [];

  @override
  Widget build(BuildContext context) {
    final segments = <_BarSegment>[];
    for (final s in standards) {
      segments.add(_BarSegment(
        label: s.standardLevel.value,
        timeSeconds: s.timeSeconds,
        isNationalTier: false,
      ));
    }
    for (final n in nationalTierStandards) {
      segments.add(_BarSegment(
        label: n.name,
        timeSeconds: n.timeSeconds,
        isNationalTier: true,
      ));
    }
    if (segments.isEmpty) return const SizedBox.shrink();

    segments.sort((a, b) => b.timeSeconds.compareTo(a.timeSeconds));

    // Index of highest (fastest) standard achieved: largest i where swimmerTime <= cut
    int currentIndex = -1;
    for (var i = segments.length - 1; i >= 0; i--) {
      if (swimmerTime <= segments[i].timeSeconds) {
        currentIndex = i;
        break;
      }
    }
    // Slice: previous, current, next, next+1 (max 4)
    final sliceStart = currentIndex < 0
        ? 0
        : currentIndex >= segments.length - 1
            ? (segments.length - _maxVisible).clamp(0, segments.length)
            : (currentIndex - 1).clamp(0, segments.length - 1);
    final sliceEnd = (sliceStart + _maxVisible).clamp(0, segments.length);
    final slice = segments.sublist(sliceStart, sliceEnd);
    if (slice.isEmpty) return const SizedBox.shrink();

    final slowest = slice.first.timeSeconds;
    final fastest = slice.last.timeSeconds;
    final range = slowest - fastest;
    final swimmerPosition = range > 0
        ? ((slowest - swimmerTime) / range).clamp(0.0, 1.0)
        : 0.5;

    final currentInSlice = currentIndex < 0 ? -1 : (currentIndex - sliceStart).clamp(0, slice.length - 1);
    final hasCurrent = currentIndex >= 0 && currentIndex < segments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            const barHeight = 32.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Grey background bar
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                ),
                // Blue gradient fill up to swimmer position
                FractionallySizedBox(
                  widthFactor: swimmerPosition,
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                          const Color(0xFF0EA5E9).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Circular marker at swimmer position
                Positioned(
                  left: swimmerPosition * barWidth - 10,
                  top: -4,
                  child: Container(
                    width: 20,
                    height: 40,
                    alignment: Alignment.center,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0EA5E9), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Three aligned rows: standard labels, times, then "Next goal" on bottom
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(slice.length, (i) {
            final segment = slice[i];
            final isNextGoal = i == currentInSlice + 1 || (!hasCurrent && i == 0);
            final color = segment.isNationalTier
                ? const Color(0xFF7C3AED) // Violet for national tiers
                : _getStandardColor(StandardLevel.fromString(segment.label));
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Row 1: standard label
                  Text(
                    segment.label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Row 2: time cut
                  Text(
                    _formatTime(segment.timeSeconds),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Row 3: "Next goal" (tappable to add to training) or empty
                  SizedBox(
                    height: 16,
                    child: isNextGoal
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onNextGoalTap != null
                                  ? () => onNextGoalTap!(segment.timeSeconds, segment.label)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Center(
                                  child: Text(
                                    onNextGoalTap != null ? 'Add as goal' : 'Next goal',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getStandardColor(StandardLevel level) {
    switch (level) {
      case StandardLevel.b:
      case StandardLevel.bb:
        return const Color(0xFF64748B); // Slate
      case StandardLevel.a:
        return const Color(0xFF3B82F6); // Blue
      case StandardLevel.aa:
        return const Color(0xFF22C55E); // Green
      case StandardLevel.aaa:
        return const Color(0xFFF59E0B); // Amber
      case StandardLevel.aaaa:
        return const Color(0xFFEF4444); // Red
      case StandardLevel.aaaaa:
        return const Color(0xFFDC2626); // Dark red (motivational is B–AAAA only)
    }
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return secs.toStringAsFixed(2);
  }
}

/// A widget that sizes its child to a fraction of the parent's size.
class FractionallySizedBox extends StatelessWidget {
  final double widthFactor;
  final Widget child;

  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * widthFactor).clamp(0.0, constraints.maxWidth);
        return SizedBox(width: width, child: child);
      },
    );
  }
}
