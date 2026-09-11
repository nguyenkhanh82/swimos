import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/training_goals_repository.dart';
import '../data/progress_entry_repository.dart';
import '../data/swimmers_repository.dart';
import '../data/milestones_repository.dart';
import '../domain/training_goal.dart';
import '../domain/goal_progress.dart';
import '../domain/progress_entry.dart';
import '../data/goal_suggestions_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_goal_screen.dart';
import 'widgets/milestones_section.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  bool _isEditing = false;
  bool _isAnalyzing = false;
  String? _aiAnalysis;

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(goalProvider(widget.goalId));
    final progressAsync = ref.watch(goalProgressProvider(widget.goalId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Goal Details', style: GoogleFonts.spaceGrotesk()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() => _isEditing = true);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _confirmDelete(context);
              } else if (value == 'pause') {
                await _updateStatus(GoalStatus.paused);
              } else if (value == 'resume') {
                await _updateStatus(GoalStatus.active);
              } else if (value == 'complete') {
                await _updateStatus(GoalStatus.completed);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause', child: Text('Pause Goal')),
              const PopupMenuItem(value: 'resume', child: Text('Resume Goal')),
              const PopupMenuItem(
                  value: 'complete', child: Text('Mark Complete')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Goal', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: goalAsync.when(
        data: (goal) {
          if (goal == null) {
            return const Center(child: Text('Goal not found'));
          }

          if (_isEditing) {
            return CreateGoalScreen(
                goalToEdit: goal,
                onSave: () {
                  setState(() => _isEditing = false);
                  ref.invalidate(goalProvider(widget.goalId));
                });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(goalProvider(widget.goalId));
              ref.invalidate(goalProgressProvider(widget.goalId));
              if (goal.goalType == GoalType.custom) {
                ref.invalidate(progressEntriesProvider(widget.goalId));
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalHeader(goal),
                  const SizedBox(height: 24),
                  progressAsync.when(
                    data: (progress) => Column(
                      children: [
                        _buildProgressSection(progress, goal),
                        const SizedBox(height: 24),
                        _buildAIAnalysisSection(progress, goal),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 24),
                  _buildGoalDetails(goal),
                  const SizedBox(height: 24),
                  MilestonesSection(goal: goal),
                  if (goal.goalType == GoalType.time) ...[
                    const SizedBox(height: 24),
                    _buildTrainingPlanSection(goal),
                  ],
                  if (goal.goalType == GoalType.custom) ...[
                    const SizedBox(height: 24),
                    _buildProgressHistory(goal),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: goalAsync.maybeWhen(
        data: (goal) {
          if (goal?.goalType == GoalType.custom && !_isEditing) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddProgressDialog(context, goal!),
              icon: const Icon(Icons.add),
              label: const Text('Add Progress'),
              backgroundColor: const Color(0xFF0EA5E9),
            );
          }
          return null;
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildGoalHeader(TrainingGoal goal) {
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
                Expanded(
                  child: Text(
                    goal.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(goal.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    goal.status.value.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: _getStatusColor(goal.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 12),
              Text(
                goal.description!,
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  Icons.category,
                  goal.goalType.value.toUpperCase(),
                  const Color(0xFF0EA5E9),
                ),
                if (goal.targetDate != null)
                  _buildChip(
                    Icons.calendar_today,
                    'Due ${_formatDate(goal.targetDate!)}',
                    Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeProgress(
      TrainingGoal goal, GoalProgress progress) async {
    setState(() => _isAnalyzing = true);
    try {
      final supabase = Supabase.instance.client;
      final service = GoalSuggestionsService(supabase);
      final milestones =
          await ref.read(milestonesByGoalProvider(goal.id).future);
      final entries = await ref.read(progressEntriesProvider(goal.id).future);

      double targetValue = 0;
      String metric = "";
      if (goal.goalType == GoalType.time) {
        targetValue = goal.targetTimeSeconds ?? 0;
        metric = "seconds";
      } else if (goal.goalType == GoalType.distance) {
        targetValue = (goal.targetDistance ?? 0).toDouble();
        metric = "meters";
      } else if (goal.goalType == GoalType.frequency) {
        targetValue = (goal.targetFrequency ?? 0).toDouble();
        metric = "sessions";
      } else {
        targetValue = goal.customTargetValue ?? 0;
        metric = goal.customUnit ?? "units";
      }

      final analysis = await service.analyzeGoalProgress(
        goalId: goal.id,
        goalTitle: goal.title,
        targetValue: targetValue,
        currentValue: progress.currentValue,
        metric: metric,
        milestones: milestones.map((m) => m.toJson()).toList(),
        recentEntries: entries.map((e) => e.toJson()).toList(),
      );

      if (mounted) {
        setState(() => _aiAnalysis = analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error analyzing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildAIAnalysisSection(GoalProgress progress, TrainingGoal goal) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 8),
                Text(
                  'Coach AI Analysis',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_aiAnalysis == null)
              ElevatedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => _analyzeProgress(goal, progress),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                ),
                child: Text(
                  _aiAnalysis!,
                  style: GoogleFonts.outfit(
                      fontSize: 15, height: 1.5, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => _analyzeProgress(goal, progress),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label:
                    Text(_isAnalyzing ? 'Re-analyzing...' : 'Refresh Analysis'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(GoalProgress progress, TrainingGoal goal) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatValue(progress.currentValue, goal),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progress.status),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[400],
                  size: 32,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatValue(progress.targetValue, goal),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.statusMessage ?? '',
                      style: GoogleFonts.outfit(
                        color: _getProgressColor(progress.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      progress.formattedProgress,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.progressPercentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress.status),
                    ),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
            if (progress.daysRemaining != null &&
                progress.daysRemaining! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${progress.daysRemaining} days remaining',
                      style: GoogleFonts.outfit(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetails(TrainingGoal goal) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Details',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildGoalSpecificDetails(goal),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGoalSpecificDetails(TrainingGoal goal) {
    switch (goal.goalType) {
      case GoalType.time:
        return [
          _buildDetailRow('Event', '${goal.distance}m ${goal.stroke}'),
          _buildDetailRow('Pool Type', goal.poolType ?? 'Any'),
          _buildDetailRow(
              'Target Time', _formatTime(goal.targetTimeSeconds ?? 0)),
        ];
      case GoalType.distance:
        return [
          _buildDetailRow('Target Distance', '${goal.targetDistance}m'),
          _buildDetailRow(
              'Period', goal.distancePeriod?.toUpperCase() ?? 'N/A'),
        ];
      case GoalType.frequency:
        return [
          _buildDetailRow(
              'Target Frequency', '${goal.targetFrequency} sessions'),
          _buildDetailRow(
              'Period', goal.frequencyPeriod?.toUpperCase() ?? 'N/A'),
        ];
      case GoalType.custom:
        return [
          _buildDetailRow('Target Value', '${goal.customTargetValue}'),
          if (goal.customUnit != null)
            _buildDetailRow('Unit', goal.customUnit!),
        ];
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanSection(TrainingGoal goal) {
    // Use goal.swimmerId if available, otherwise fall back to selected swimmer
    final swimmerId = goal.swimmerId;
    if (swimmerId == null) {
      return const SizedBox.shrink();
    }

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
                  'Training Plan',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      '/training/goals/${goal.id}/practice',
                      extra: {
                        'swimmerId': swimmerId,
                      },
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Practice'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Get personalized training sets to help you achieve your goal',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/training/goals/${goal.id}/build-macro-plan',
                    extra: {
                      'swimmerId': swimmerId,
                    },
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Build Macro Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/training/goals/${goal.id}/practice',
                    extra: {
                      'swimmerId': swimmerId,
                    },
                  );
                },
                icon: const Icon(Icons.fitness_center),
                label: const Text('View Training Plan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0EA5E9),
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/training/goals/${goal.id}/history');
                },
                icon: const Icon(Icons.history),
                label: const Text('View Training History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHistory(TrainingGoal goal) {
    final entriesAsync = ref.watch(progressEntriesProvider(goal.id));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress History',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.timeline,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No progress entries yet',
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildProgressEntryTile(entry, goal);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading history: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressEntryTile(ProgressEntry entry, TrainingGoal goal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle,
              color: Color(0xFF0EA5E9), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.progressValue} ${goal.customUnit ?? ''}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatDate(entry.recordedAt),
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.notes!,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _confirmDeleteEntry(entry.id),
          color: Colors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showAddProgressDialog(BuildContext context, TrainingGoal goal) {
    final valueController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Progress', style: GoogleFonts.spaceGrotesk()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Progress Value',
                suffixText: goal.customUnit ?? '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(valueController.text);
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }

              // Get swimmer ID from goal or selected swimmer
              final swimmerId = goal.swimmerId ??
                  await ref.read(selectedSwimmerIdProvider.future);
              if (swimmerId == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select a swimmer profile first')),
                );
                return;
              }

              final entry = ProgressEntry(
                id: '',
                goalId: goal.id,
                userId: goal.userId,
                swimmerId: swimmerId,
                progressValue: value,
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
                recordedAt: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                final repository = ref.read(progressEntryRepositoryProvider);
                await repository.createEntry(entry, swimmerId: swimmerId);
                ref.invalidate(progressEntriesProvider(goal.id));
                ref.invalidate(goalProgressProvider(goal.id));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress added successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(GoalStatus newStatus) async {
    try {
      final repository = ref.read(trainingGoalsRepositoryProvider);

      switch (newStatus) {
        case GoalStatus.paused:
          await repository.pauseGoal(widget.goalId);
          break;
        case GoalStatus.active:
          await repository.resumeGoal(widget.goalId);
          break;
        case GoalStatus.completed:
          await repository.completeGoal(widget.goalId);
          break;
        case GoalStatus.archived:
          break;
      }

      ref.invalidate(goalProvider(widget.goalId));
      ref.invalidate(activeGoalsProvider);
      ref.invalidate(goalsListProvider);
      ref.invalidate(allGoalsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal ${newStatus.value}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Goal', style: GoogleFonts.spaceGrotesk()),
        content: const Text(
            'Are you sure you want to delete this goal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(trainingGoalsRepositoryProvider);
                await repository.deleteGoal(widget.goalId);

                ref.invalidate(activeGoalsProvider);
                ref.invalidate(goalsListProvider);
                ref.invalidate(allGoalsProvider);

                if (!context.mounted) return;
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Go back to goals list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal deleted')),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry', style: GoogleFonts.spaceGrotesk()),
        content: const Text('Delete this progress entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(progressEntryRepositoryProvider);
                await repository.deleteEntry(entryId);
                ref.invalidate(progressEntriesProvider(widget.goalId));
                ref.invalidate(goalProgressProvider(widget.goalId));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entry deleted')),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, TrainingGoal goal) {
    if (goal.goalType == GoalType.time) {
      return _formatTime(value);
    } else if (goal.goalType == GoalType.custom) {
      return '${value.toStringAsFixed(1)} ${goal.customUnit ?? ''}';
    } else {
      return value.toInt().toString();
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
