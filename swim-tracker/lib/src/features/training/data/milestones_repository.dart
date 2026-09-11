import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/goal_milestone.dart';
import '../domain/training_goal.dart';

class MilestonesRepository {
  final SupabaseClient _supabase;

  MilestonesRepository(this._supabase);

  Future<List<GoalMilestone>> getMilestonesByGoalId(String goalId) async {
    final data = await _supabase
        .from('goal_milestones')
        .select()
        .eq('goal_id', goalId)
        .order('sort_order', ascending: true);

    return (data as List).map((e) => GoalMilestone.fromJson(e)).toList();
  }

  Future<GoalMilestone> createMilestone(GoalMilestone milestone) async {
    final data = await _supabase
        .from('goal_milestones')
        .insert({
          'goal_id': milestone.goalId,
          'title': milestone.title,
          'target_value': milestone.targetValue,
          'target_date': milestone.targetDate?.toIso8601String().split('T')[0],
          'is_completed': milestone.isCompleted,
          'sort_order': milestone.sortOrder,
        })
        .select()
        .single();

    return GoalMilestone.fromJson(data);
  }

  Future<void> updateMilestone(GoalMilestone milestone) async {
    await _supabase.from('goal_milestones').update({
      'title': milestone.title,
      'target_value': milestone.targetValue,
      'target_date': milestone.targetDate?.toIso8601String().split('T')[0],
      'is_completed': milestone.isCompleted,
      'completed_at': milestone.completedAt?.toIso8601String(),
      'sort_order': milestone.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', milestone.id);
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await _supabase.from('goal_milestones').delete().eq('id', milestoneId);
  }

  Future<void> completeMilestone(String milestoneId) async {
    await _supabase.from('goal_milestones').update({
      'is_completed': true,
      'completed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', milestoneId);
  }

  Future<void> uncompleteMilestone(String milestoneId) async {
    await _supabase.from('goal_milestones').update({
      'is_completed': false,
      'completed_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', milestoneId);
  }

  // Auto-generate milestones for a goal (25%, 50%, 75%, 100%)
  Future<List<GoalMilestone>> generateMilestonesForGoal(
      TrainingGoal goal) async {
    final milestones = <GoalMilestone>[];
    final percentages = [0.25, 0.50, 0.75, 1.0];

    double targetValue = 0;

    switch (goal.goalType) {
      case GoalType.time:
        if (goal.targetTimeSeconds == null) return [];
        targetValue = goal.targetTimeSeconds!;
        break;
      case GoalType.distance:
        if (goal.targetDistance == null) return [];
        targetValue = goal.targetDistance!.toDouble();
        break;
      case GoalType.frequency:
        if (goal.targetFrequency == null) return [];
        targetValue = goal.targetFrequency!.toDouble();
        break;
      case GoalType.custom:
        if (goal.customTargetValue == null) return [];
        targetValue = goal.customTargetValue!;
        break;
    }

    for (int i = 0; i < percentages.length; i++) {
      final percentage = percentages[i];
      final milestoneValue = targetValue * percentage;
      final milestoneTitle = '${(percentage * 100).toInt()}% Milestone';

      final milestone = GoalMilestone(
        id: '',
        goalId: goal.id,
        title: milestoneTitle,
        targetValue: milestoneValue,
        targetDate: goal.targetDate,
        sortOrder: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await createMilestone(milestone);
      milestones.add(created);
    }

    return milestones;
  }
}

final milestonesRepositoryProvider = Provider<MilestonesRepository>((ref) {
  return MilestonesRepository(Supabase.instance.client);
});

final milestonesByGoalProvider =
    FutureProvider.family<List<GoalMilestone>, String>((ref, goalId) async {
  final repository = ref.watch(milestonesRepositoryProvider);
  return repository.getMilestonesByGoalId(goalId);
});
