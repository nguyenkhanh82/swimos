import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/training_goal.dart';
import '../domain/goal_progress.dart';
import 'goal_progress_service.dart';
import 'swimmers_repository.dart';

class TrainingGoalsRepository {
  final SupabaseClient _supabase;

  TrainingGoalsRepository(this._supabase);

  // Get all goals for swimmer
  Future<List<TrainingGoal>> getGoals({
    required String swimmerId,
    String? teamId,
    GoalStatus? status,
    GoalType? goalType,
  }) async {
    var query =
        _supabase.from('training_goals').select().eq('swimmer_id', swimmerId);

    if (teamId != null) {
      query = query.eq('team_id', teamId);
    } else {
      // If no teamId specified, get both personal (null team_id) and all team goals
      // We'll filter in memory for now
    }

    if (status != null) {
      query = query.eq('status', status.value);
    }

    if (goalType != null) {
      query = query.eq('goal_type', goalType.value);
    }

    final data = await query.order('created_at', ascending: false);
    final allGoals =
        (data as List).map((e) => TrainingGoal.fromJson(e)).toList();

    // Filter by teamId if specified (to get only null team_id or specific team)
    if (teamId != null) {
      return allGoals.where((g) => g.teamId == teamId).toList();
    }

    return allGoals;
  }

  // Get active goals only
  Future<List<TrainingGoal>> getActiveGoals(
      {required String swimmerId, String? teamId}) async {
    return getGoals(
        swimmerId: swimmerId, teamId: teamId, status: GoalStatus.active);
  }

  // Get goal by ID
  Future<TrainingGoal?> getGoalById(String goalId) async {
    final data = await _supabase
        .from('training_goals')
        .select()
        .eq('id', goalId)
        .maybeSingle();

    if (data == null) return null;
    return TrainingGoal.fromJson(data);
  }

  // Get goal with current best time
  Future<GoalWithCurrentTime> getGoalWithCurrentTime(
      String goalId, String swimmerId) async {
    final goal = await getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    if (goal.goalType != GoalType.time ||
        goal.stroke == null ||
        goal.distance == null) {
      throw Exception(
          'Goal is not a time-based goal or missing required fields');
    }

    final eventName = '${goal.distance} ${goal.stroke}';
    final poolType = goal.poolType ?? 'SCY';

    final bestTimeData = await _supabase
        .from('swim_times')
        .select('time_seconds')
        .eq('swimmer_id', swimmerId)
        .eq('event_name', eventName)
        .eq('pool_type', poolType)
        .order('time_seconds', ascending: true)
        .limit(1)
        .maybeSingle();

    final currentBestTime = (bestTimeData?['time_seconds'] as num?)?.toDouble();

    return GoalWithCurrentTime(
      goal: goal,
      currentBestTime: currentBestTime,
      improvementNeeded:
          currentBestTime != null && goal.targetTimeSeconds != null
              ? currentBestTime - goal.targetTimeSeconds!
              : null,
      percentImprovement: currentBestTime != null &&
              goal.targetTimeSeconds != null
          ? ((currentBestTime - goal.targetTimeSeconds!) / currentBestTime) *
              100
          : null,
    );
  }

  // Create goal
  Future<TrainingGoal> createGoal(TrainingGoal goal,
      {required String swimmerId}) async {
    final userId =
        goal.userId.isNotEmpty ? goal.userId : _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User must be signed in to create a goal');
    }
    // Build insert data, only including relevant fields based on goal type
    final insertData = <String, dynamic>{
      'user_id': userId,
      'swimmer_id': swimmerId,
      'team_id': goal.teamId,
      'goal_type': goal.goalType.value,
      'title': goal.title,
      'description': goal.description,
      'target_date': goal.targetDate?.toIso8601String().split('T')[0],
      'status': goal.status.value,
      'is_active': goal.isActive,
    };

    // Only include fields relevant to the goal type
    switch (goal.goalType) {
      case GoalType.time:
        insertData['stroke'] = goal.stroke;
        insertData['distance'] = goal.distance;
        insertData['pool_type'] = goal.poolType;
        insertData['target_time_seconds'] = goal.targetTimeSeconds;
        break;
      case GoalType.distance:
        insertData['target_distance'] = goal.targetDistance;
        insertData['distance_period'] = goal.distancePeriod;
        break;
      case GoalType.frequency:
        insertData['target_frequency'] = goal.targetFrequency;
        // Only set frequency_period if it's a valid value ('weekly' or 'monthly')
        if (goal.frequencyPeriod != null &&
            goal.frequencyPeriod!.isNotEmpty &&
            (goal.frequencyPeriod == 'weekly' ||
                goal.frequencyPeriod == 'monthly')) {
          insertData['frequency_period'] = goal.frequencyPeriod;
        }
        break;
      case GoalType.custom:
        insertData['custom_target_value'] = goal.customTargetValue;
        insertData['custom_unit'] = goal.customUnit;
        break;
    }

    final data = await _supabase
        .from('training_goals')
        .insert(insertData)
        .select()
        .single();

    return TrainingGoal.fromJson(data);
  }

  // Update goal
  Future<void> updateGoal(TrainingGoal goal) async {
    // Build update data, only including relevant fields based on goal type
    final updateData = <String, dynamic>{
      'team_id': goal.teamId,
      'goal_type': goal.goalType.value,
      'title': goal.title,
      'description': goal.description,
      'target_date': goal.targetDate?.toIso8601String().split('T')[0],
      'status': goal.status.value,
      'is_active': goal.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only include fields relevant to the goal type
    switch (goal.goalType) {
      case GoalType.time:
        updateData['stroke'] = goal.stroke;
        updateData['distance'] = goal.distance;
        updateData['pool_type'] = goal.poolType;
        updateData['target_time_seconds'] = goal.targetTimeSeconds;
        // Clear other goal type fields
        updateData['target_distance'] = null;
        updateData['distance_period'] = null;
        updateData['target_frequency'] = null;
        updateData['frequency_period'] = null;
        updateData['custom_target_value'] = null;
        updateData['custom_unit'] = null;
        break;
      case GoalType.distance:
        updateData['target_distance'] = goal.targetDistance;
        updateData['distance_period'] = goal.distancePeriod;
        // Clear other goal type fields
        updateData['stroke'] = null;
        updateData['distance'] = null;
        updateData['pool_type'] = null;
        updateData['target_time_seconds'] = null;
        updateData['target_frequency'] = null;
        updateData['frequency_period'] = null;
        updateData['custom_target_value'] = null;
        updateData['custom_unit'] = null;
        break;
      case GoalType.frequency:
        updateData['target_frequency'] = goal.targetFrequency;
        // Only set frequency_period if it's a valid value
        if (goal.frequencyPeriod != null &&
            goal.frequencyPeriod!.isNotEmpty &&
            (goal.frequencyPeriod == 'weekly' ||
                goal.frequencyPeriod == 'monthly')) {
          updateData['frequency_period'] = goal.frequencyPeriod;
        } else {
          updateData['frequency_period'] = null;
        }
        // Clear other goal type fields
        updateData['stroke'] = null;
        updateData['distance'] = null;
        updateData['pool_type'] = null;
        updateData['target_time_seconds'] = null;
        updateData['target_distance'] = null;
        updateData['distance_period'] = null;
        updateData['custom_target_value'] = null;
        updateData['custom_unit'] = null;
        break;
      case GoalType.custom:
        updateData['custom_target_value'] = goal.customTargetValue;
        updateData['custom_unit'] = goal.customUnit;
        // Clear other goal type fields
        updateData['stroke'] = null;
        updateData['distance'] = null;
        updateData['pool_type'] = null;
        updateData['target_time_seconds'] = null;
        updateData['target_distance'] = null;
        updateData['distance_period'] = null;
        updateData['target_frequency'] = null;
        updateData['frequency_period'] = null;
        break;
    }

    await _supabase.from('training_goals').update(updateData).eq('id', goal.id);
  }

  // Delete goal
  Future<void> deleteGoal(String goalId) async {
    await _supabase.from('training_goals').delete().eq('id', goalId);
  }

  // Complete goal
  Future<void> completeGoal(String goalId) async {
    await _supabase.from('training_goals').update({
      'status': GoalStatus.completed.value,
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }

  // Pause goal
  Future<void> pauseGoal(String goalId) async {
    await _supabase.from('training_goals').update({
      'status': GoalStatus.paused.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }

  // Resume goal
  Future<void> resumeGoal(String goalId) async {
    await _supabase.from('training_goals').update({
      'status': GoalStatus.active.value,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }
}

// Riverpod Providers
final trainingGoalsRepositoryProvider =
    Provider<TrainingGoalsRepository>((ref) {
  return TrainingGoalsRepository(Supabase.instance.client);
});

final goalsListProvider = FutureProvider<List<TrainingGoal>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingGoalsRepositoryProvider);
  return repository.getGoals(swimmerId: selectedSwimmerId);
});

final activeGoalsProvider = FutureProvider<List<TrainingGoal>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingGoalsRepositoryProvider);
  return repository.getActiveGoals(swimmerId: selectedSwimmerId);
});

final allGoalsProvider = FutureProvider<List<TrainingGoal>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingGoalsRepositoryProvider);
  return repository.getGoals(swimmerId: selectedSwimmerId);
});

final teamGoalsProvider =
    FutureProvider.family<List<TrainingGoal>, String?>((ref, teamId) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingGoalsRepositoryProvider);
  return repository.getActiveGoals(
      swimmerId: selectedSwimmerId, teamId: teamId);
});

final goalProvider =
    FutureProvider.family<TrainingGoal?, String>((ref, goalId) async {
  final repository = ref.watch(trainingGoalsRepositoryProvider);
  return repository.getGoalById(goalId);
});

// Goal Progress Provider
final goalProgressServiceProvider = Provider<GoalProgressService>((ref) {
  return GoalProgressService(Supabase.instance.client);
});

final goalProgressProvider =
    FutureProvider.family<GoalProgress, String>((ref, goalId) async {
  final goal = await ref.watch(goalProvider(goalId).future);
  if (goal == null) {
    throw Exception('Goal not found');
  }
  final service = ref.watch(goalProgressServiceProvider);
  return service.calculateProgress(goal);
});

class GoalWithCurrentTime {
  final TrainingGoal goal;
  final double? currentBestTime;
  final double? improvementNeeded;
  final double? percentImprovement;

  GoalWithCurrentTime({
    required this.goal,
    this.currentBestTime,
    this.improvementNeeded,
    this.percentImprovement,
  });
}
