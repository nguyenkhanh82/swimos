import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/milestones_repository.dart';
import '../../domain/goal_milestone.dart';
import '../../domain/training_goal.dart';

class MilestonesSection extends ConsumerWidget {
  final TrainingGoal goal;

  const MilestonesSection({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestonesByGoalProvider(goal.id));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestones',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _generateMilestones(context, ref),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Auto-Generate'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            milestonesAsync.when(
              data: (milestones) {
                if (milestones.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return _buildMilestonesList(milestones, ref);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No Milestones Yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Break down your goal into checkpoints',
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _generateMilestones(context, ref),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Milestones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesList(List<GoalMilestone> milestones, WidgetRef ref) {
    return Column(
      children: [
        for (int i = 0; i < milestones.length; i++)
          _buildMilestoneItem(milestones[i], i == milestones.length - 1, ref),
      ],
    );
  }

  Widget _buildMilestoneItem(
      GoalMilestone milestone, bool isLast, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: milestone.isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: milestone.isCompleted
                        ? const Color(0xFF10B981)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: milestone.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: milestone.isCompleted
                        ? const Color(0xFF10B981)
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: milestone.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          milestone.isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: milestone.isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.grey[400],
                        ),
                        onPressed: () => _toggleMilestone(milestone, ref),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${_formatValue(milestone.targetValue)}',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (milestone.targetDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(milestone.targetDate!),
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (milestone.isCompleted &&
                      milestone.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed ${_formatDate(milestone.completedAt!)}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMilestones(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(milestonesRepositoryProvider);
      await repository.generateMilestonesForGoal(goal);
      ref.invalidate(milestonesByGoalProvider(goal.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestones generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleMilestone(GoalMilestone milestone, WidgetRef ref) async {
    try {
      final repository = ref.read(milestonesRepositoryProvider);
      if (milestone.isCompleted) {
        await repository.uncompleteMilestone(milestone.id);
      } else {
        await repository.completeMilestone(milestone.id);
      }
      ref.invalidate(milestonesByGoalProvider(goal.id));
    } catch (e) {
      // Silent fail
    }
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
