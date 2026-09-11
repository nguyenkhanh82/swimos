import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/time_standard.dart';

class TimeStandardsWidget extends StatelessWidget {
  final SwimmerStandardInfo standardInfo;
  final VoidCallback? onTapSuggestGoal;

  const TimeStandardsWidget({
    super.key,
    required this.standardInfo,
    this.onTapSuggestGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Standards',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStandardColor(standardInfo.currentStandard).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    standardInfo.currentStandardDisplay,
                    style: GoogleFonts.outfit(
                      color: _getStandardColor(standardInfo.currentStandard),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Current Level',
                    standardInfo.currentStandardDisplay,
                    _getStandardColor(standardInfo.currentStandard),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoColumn(
                    'Next Target',
                    standardInfo.nextStandardDisplay,
                    _getStandardColor(standardInfo.nextStandard),
                  ),
                ),
              ],
            ),
            if (standardInfo.canImprove && standardInfo.timeToNextStandard != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFF0EA5E9), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drop ${_formatTimeDrop(standardInfo.timeToNextStandard!)} to reach ${standardInfo.nextStandardDisplay}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onTapSuggestGoal != null && standardInfo.canImprove) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTapSuggestGoal,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Create Goal for Next Standard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStandardColor(StandardLevel? level) {
    if (level == null) return Colors.grey;

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
        return const Color(0xFFDC2626); // Dark Red
    }
  }

  String _formatTimeDrop(double seconds) {
    if (seconds < 1) {
      return '${(seconds * 100).toStringAsFixed(0)} hundredths';
    } else if (seconds < 60) {
      return '${seconds.toStringAsFixed(2)}s';
    } else {
      final minutes = (seconds / 60).floor();
      final secs = seconds % 60;
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
  }
}
