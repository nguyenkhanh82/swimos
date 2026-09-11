import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/training_goals_repository.dart';
import '../data/teams_repository.dart';
import '../domain/training_goal.dart';
import '../domain/goal_progress.dart';
import 'widgets/goal_suggestions_widget.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalStatus? _filterStatus;
  String? _filterTeamId;

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsListProvider);
    final teamsAsync = ref.watch(teamsListProvider);

    return Column(
      children: [
        // Filters
        _buildFilters(teamsAsync.value ?? []),

        // Goals List
        Expanded(
          child: goalsAsync.when(
            data: (goals) {
              // Apply filters
              var filteredGoals = goals;

              if (_filterStatus != null) {
                filteredGoals = filteredGoals
                    .where((g) => g.status == _filterStatus)
                    .toList();
              }

              if (_filterTeamId != null) {
                filteredGoals = filteredGoals
                    .where((g) => g.teamId == _filterTeamId)
                    .toList();
              }

              if (filteredGoals.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(goalsListProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      filteredGoals.length + 1, // +1 for suggestions widget
                  itemBuilder: (context, index) {
                    // Show suggestions widget at the top
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GoalSuggestionsWidget(
                          onGoalCreated: () {
                            ref.invalidate(goalsListProvider);
                          },
                        ),
                      );
                    }

                    final goal = filteredGoals[index - 1];
                    return _GoalCard(goal: goal);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $err', style: GoogleFonts.outfit()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(goalsListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(List<dynamic> teams) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: DropdownButtonFormField<GoalStatus?>(
              initialValue: _filterStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<GoalStatus?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...GoalStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.value.toUpperCase()),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatus = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // Team Filter
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _filterTeamId,
              decoration: InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Teams'),
                ),
                const DropdownMenuItem<String?>(
                  value: 'personal',
                  child: Text('Personal'),
                ),
                ...teams.map((team) => DropdownMenuItem(
                      value: team.id,
                      child: Text(team.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterTeamId = value == 'personal' ? '' : value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // AI Suggestions widget at top
          GoalSuggestionsWidget(
            onGoalCreated: () {
              ref.invalidate(goalsListProvider);
            },
          ),
          const SizedBox(height: 32),
          // Empty state message
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No Goals Yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a goal to track your training progress',
            style: GoogleFonts.outfit(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/training/goals/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final TrainingGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/training/goals/${goal.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(goal.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      goal.status.value.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: _getStatusColor(goal.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (goal.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              progressAsync.when(
                data: (progress) => _buildProgressInfo(progress, goal),
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error loading progress: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressInfo(GoalProgress progress, TrainingGoal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getGoalDisplayText(goal, progress),
              style: GoogleFonts.outfit(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            Text(
              progress.formattedProgress,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.progressPercentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress.status),
            ),
            minHeight: 8,
          ),
        ),
        if (progress.daysRemaining != null && progress.daysRemaining! > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${progress.daysRemaining} days remaining',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getGoalDisplayText(TrainingGoal goal, GoalProgress progress) {
    switch (goal.goalType) {
      case GoalType.time:
        return 'Current: ${progress.bestTime ?? "N/A"} / Target: ${_formatTime(goal.targetTimeSeconds ?? 0)}';
      case GoalType.distance:
        return 'Current: ${progress.formattedCurrentValue}${goal.distancePeriod == 'daily' ? 'm/day' : goal.distancePeriod == 'weekly' ? 'm/week' : 'm/month'} / Target: ${progress.formattedTargetValue}${goal.distancePeriod == 'daily' ? 'm/day' : goal.distancePeriod == 'weekly' ? 'm/week' : 'm/month'}';
      case GoalType.frequency:
        return 'Current: ${progress.formattedCurrentValue} sessions / Target: ${progress.formattedTargetValue} sessions';
      case GoalType.custom:
        return 'Current: ${progress.formattedCurrentValue}${goal.customUnit ?? ''} / Target: ${progress.formattedTargetValue}${goal.customUnit ?? ''}';
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

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return const Color(0xFF0EA5E9);
      case GoalStatus.completed:
        return const Color(0xFF10B981);
      case GoalStatus.paused:
        return const Color(0xFFFFA500);
      case GoalStatus.archived:
        return Colors.grey;
    }
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
