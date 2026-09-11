import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../training/data/training_goals_repository.dart';
import '../../training/domain/training_goal.dart';
import '../../training/domain/goal_progress.dart';

class GoalCardWidget extends ConsumerWidget {
  final TrainingGoal goal;

  const GoalCardWidget({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return progressAsync.when(
      data: (GoalProgress progress) => _buildCard(context, goal, progress),
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Error loading progress',
            style: GoogleFonts.outfit(color: Colors.red)),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, TrainingGoal goal, GoalProgress progress) {
    final statusColor = _getProgressColor(progress.status);

    return InkWell(
      onTap: () => context.push('/training/goals/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progress.statusMessage ?? progress.status.displayName,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getCurrentDisplayText(goal, progress),
                  style:
                      GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  progress.formattedProgress,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progressPercentage.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _getTargetDisplayText(goal, progress),
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                ),
                if (progress.daysRemaining != null &&
                    progress.daysRemaining! > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${progress.daysRemaining} days left',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDisplayText(TrainingGoal goal, GoalProgress progress) {
    switch (goal.goalType) {
      case GoalType.time:
        return 'Current: ${progress.bestTime ?? "N/A"}';
      case GoalType.distance:
        return 'Current: ${progress.formattedCurrentValue}m';
      case GoalType.frequency:
        return 'Current: ${progress.formattedCurrentValue} sessions';
      case GoalType.custom:
        return 'Current: ${progress.formattedCurrentValue}${goal.customUnit ?? ''}';
    }
  }

  String _getTargetDisplayText(TrainingGoal goal, GoalProgress progress) {
    switch (goal.goalType) {
      case GoalType.time:
        return 'Target: ${_formatTime(goal.targetTimeSeconds ?? 0)}';
      case GoalType.distance:
        final period = goal.distancePeriod == 'daily'
            ? 'm/day'
            : goal.distancePeriod == 'weekly'
                ? 'm/week'
                : 'm/month';
        return 'Target: ${progress.formattedTargetValue}$period';
      case GoalType.frequency:
        return 'Target: ${progress.formattedTargetValue} sessions/${goal.frequencyPeriod ?? 'week'}';
      case GoalType.custom:
        return 'Target: ${progress.formattedTargetValue}${goal.customUnit ?? ''}';
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

  Color _getProgressColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.onTrack:
        return const Color(0xFF0EA5E9);
      case ProgressStatus.inProgress:
        return const Color(0xFFFFA500);
      case ProgressStatus.behind:
        return const Color(0xFFFF4444);
      case ProgressStatus.completed:
        return const Color(0xFF10B981);
      case ProgressStatus.notStarted:
        return Colors.grey;
    }
  }
}
