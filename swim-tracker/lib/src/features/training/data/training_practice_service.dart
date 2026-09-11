import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/training_practice.dart';
import '../domain/training_goal.dart';
import 'training_goals_repository.dart';

class TrainingPracticeService {
  final SupabaseClient _supabase;
  final TrainingGoalsRepository _goalsRepository;

  TrainingPracticeService(this._supabase, this._goalsRepository);

  /// Generate training practice sets from a goal
  /// Fetches goal details, current best time, and calls Groq API to generate practice sets
  Future<List<TrainingPractice>> generatePracticeFromGoal(
    String swimmerId,
    String goalId,
  ) async {
    // 1. Get goal details
    final goal = await _goalsRepository.getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    if (goal.goalType != GoalType.time) {
      throw Exception('Practice generation is only available for time-based goals');
    }

    if (goal.stroke == null || goal.distance == null || goal.targetTimeSeconds == null) {
      throw Exception('Goal is missing required fields (stroke, distance, target_time_seconds)');
    }

    // 2. Get current best time from swim_times
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
    if (currentBestTime == null) {
      throw Exception('No current best time found for this event. Please record some times first.');
    }

    // 3. Call Groq Edge Function
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await _supabase.functions.invoke(
      'generate-practice-from-goal',
      body: {
        'swimmer_id': swimmerId,
        'goal_id': goalId,
        'current_time': currentBestTime,
        'target_time': goal.targetTimeSeconds,
        'stroke': goal.stroke,
        'distance': goal.distance,
        'pool_type': poolType,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] as String? ?? 'Unknown error';
      throw Exception('Failed to generate practice: $error');
    }

    final responseData = response.data as Map<String, dynamic>;
    final suggestions = responseData['suggestions'] as List<dynamic>?;

    if (suggestions == null || suggestions.isEmpty) {
      throw Exception('No practice suggestions returned');
    }

    // 4. Convert API response to TrainingPractice objects
    final practices = <TrainingPractice>[];
    for (int i = 0; i < suggestions.length; i++) {
      final suggestion = suggestions[i] as Map<String, dynamic>;
      practices.add(
        TrainingPractice(
          id: '', // Will be set when saved
          goalId: goalId,
          swimmerId: swimmerId,
          setDescription: suggestion['set_description'] as String? ?? '',
          stroke: suggestion['stroke'] as String? ?? goal.stroke!,
          distancePerRep: (suggestion['distance_per_rep'] as num?)?.toInt() ?? 0,
          numberOfReps: (suggestion['number_of_reps'] as num?)?.toInt() ?? 0,
          totalDistance: (suggestion['total_distance'] as num?)?.toInt() ?? 0,
          restSeconds: (suggestion['rest_seconds'] as num?)?.toInt() ?? 0,
          intensity: suggestion['intensity'] as String? ?? 'moderate',
          rationale: suggestion['rationale'] as String? ?? '',
          createdAt: DateTime.now(),
        ),
      );
    }

    return practices;
  }
}

final trainingPracticeServiceProvider = Provider<TrainingPracticeService>((ref) {
  final supabase = Supabase.instance.client;
  final goalsRepo = ref.watch(trainingGoalsRepositoryProvider);
  return TrainingPracticeService(supabase, goalsRepo);
});
