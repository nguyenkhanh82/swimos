import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/training_goal.dart';
import '../../data/training_goals_repository.dart';
import '../../data/goal_suggestions_service.dart';
import '../../data/swimmers_repository.dart';

// Goal suggestion model
class GoalSuggestion {
  final String title;
  final String goalType;
  final String? stroke;
  final int? distance;
  final double? targetTimeSeconds;
  final int? targetDistance;
  final int? targetFrequency;
  final String? frequencyPeriod;
  final String? distancePeriod;
  final String? targetDate;
  final String rationale;
  final String priority;

  GoalSuggestion({
    required this.title,
    required this.goalType,
    this.stroke,
    this.distance,
    this.targetTimeSeconds,
    this.targetDistance,
    this.targetFrequency,
    this.frequencyPeriod,
    this.distancePeriod,
    this.targetDate,
    required this.rationale,
    required this.priority,
  });

  factory GoalSuggestion.fromJson(Map<String, dynamic> json) {
    return GoalSuggestion(
      title: json['title'] as String,
      goalType: json['goalType'] as String,
      stroke: json['stroke'] as String?,
      distance: json['distance'] as int?,
      targetTimeSeconds: json['targetTimeSeconds'] != null
          ? (json['targetTimeSeconds'] as num).toDouble()
          : null,
      targetDistance: json['targetDistance'] as int?,
      targetFrequency: json['targetFrequency'] as int?,
      frequencyPeriod: json['frequencyPeriod'] as String?,
      distancePeriod: json['distancePeriod'] as String?,
      targetDate: json['targetDate'] as String?,
      rationale: json['rationale'] as String,
      priority: json['priority'] as String,
    );
  }
}

// Provider for fetching AI suggestions
// Consider moving back to edge function for production (security, API key management)
final goalSuggestionsProvider =
    FutureProvider<List<GoalSuggestion>>((ref) async {
  debugPrint('🚀 goalSuggestionsProvider: Starting...');

  // Get selected swimmer ID
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) {
    debugPrint('⚠️ No swimmer selected, returning empty suggestions');
    return [];
  }

  final supabase = Supabase.instance.client;

  try {
    // Use local service instead of edge function for debugging
    final service = GoalSuggestionsService(supabase);
    final suggestions =
        await service.getSuggestions(swimmerId: selectedSwimmerId);

    debugPrint('✅ Got ${suggestions.length} suggestions');
    return suggestions;
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching goal suggestions: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
});

class GoalSuggestionsWidget extends ConsumerWidget {
  final VoidCallback? onGoalCreated;

  const GoalSuggestionsWidget({
    super.key,
    this.onGoalCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(goalSuggestionsProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFF0EA5E9), size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Goal Suggestions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.invalidate(goalSuggestionsProvider);
                  },
                  tooltip: 'Refresh suggestions',
                ),
              ],
            ),
            const SizedBox(height: 12),
            suggestionsAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: suggestions.map((suggestion) {
                    return _buildSuggestionCard(context, ref, suggestion);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorState(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    WidgetRef ref,
    GoalSuggestion suggestion,
  ) {
    final priorityColor = _getPriorityColor(suggestion.priority);
    final priorityIcon = _getPriorityIcon(suggestion.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(priorityIcon, color: priorityColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  _formatGoalType(suggestion.goalType),
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: priorityColor.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.rationale,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          if (suggestion.targetDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  'Target: ${_formatDate(suggestion.targetDate!)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _createGoalFromSuggestion(context, ref, suggestion),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create This Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.tips_and_updates_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No suggestions available yet',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete more training sessions to get personalized goal suggestions',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Unable to load suggestions',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createGoalFromSuggestion(
    BuildContext context,
    WidgetRef ref,
    GoalSuggestion suggestion,
  ) async {
    try {
      // Get selected swimmer ID
      final selectedSwimmerId =
          await ref.read(selectedSwimmerIdProvider.future);
      if (selectedSwimmerId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a swimmer profile first')),
          );
        }
        return;
      }

      final repository = ref.read(trainingGoalsRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Parse goal type
      final goalType = GoalType.fromString(suggestion.goalType);

      // Parse target date
      DateTime? targetDate;
      if (suggestion.targetDate != null) {
        try {
          targetDate = DateTime.parse(suggestion.targetDate!);
        } catch (e) {
          // If parsing fails, default to 2 months from now
          targetDate = DateTime.now().add(const Duration(days: 60));
        }
      }

      // Create the goal - only set fields relevant to the goal type
      final goal = TrainingGoal(
        id: '',
        userId: userId,
        swimmerId: selectedSwimmerId,
        goalType: goalType,
        title: suggestion.title,
        description: suggestion.rationale,
        stroke: goalType == GoalType.time ? suggestion.stroke : null,
        distance: goalType == GoalType.time ? suggestion.distance : null,
        poolType: goalType == GoalType.time
            ? null
            : null, // Can be set later if needed
        targetTimeSeconds:
            goalType == GoalType.time ? suggestion.targetTimeSeconds : null,
        targetDistance:
            goalType == GoalType.distance ? suggestion.targetDistance : null,
        distancePeriod:
            goalType == GoalType.distance ? suggestion.distancePeriod : null,
        targetFrequency:
            goalType == GoalType.frequency ? suggestion.targetFrequency : null,
        frequencyPeriod: goalType == GoalType.frequency &&
                suggestion.frequencyPeriod != null &&
                suggestion.frequencyPeriod!.isNotEmpty &&
                (suggestion.frequencyPeriod == 'weekly' ||
                    suggestion.frequencyPeriod == 'monthly')
            ? suggestion.frequencyPeriod
            : null,
        targetDate: targetDate,
        status: GoalStatus.active,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createGoal(goal, swimmerId: selectedSwimmerId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal created: ${suggestion.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Invalidate suggestions to refresh the list
      ref.invalidate(goalSuggestionsProvider);

      // Notify parent widget
      onGoalCreated?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444); // Red
      case 'medium':
        return const Color(0xFFF59E0B); // Amber
      case 'low':
        return const Color(0xFF10B981); // Green
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.flag;
    }
  }

  String _formatGoalType(String type) {
    switch (type.toLowerCase()) {
      case 'time':
        return 'Time Goal';
      case 'distance':
        return 'Distance Goal';
      case 'frequency':
        return 'Consistency Goal';
      case 'custom':
        return 'Custom Goal';
      default:
        return type;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
