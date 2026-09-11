import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/scheduled_workout.dart';

class ScheduledWorkoutsRepository {
  final SupabaseClient _supabase;

  ScheduledWorkoutsRepository(this._supabase);

  Future<List<ScheduledWorkout>> getScheduledWorkouts({
    required String swimmerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('scheduled_workouts')
        .select()
        .eq('swimmer_id', swimmerId);

    if (startDate != null) {
      query = query.gte('target_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('target_date', endDate.toIso8601String());
    }

    final data = await query.order('target_date', ascending: true);
    return (data as List).map((e) => ScheduledWorkout.fromJson(e)).toList();
  }

  Future<void> createScheduledWorkouts(List<ScheduledWorkout> workouts) async {
    final List<Map<String, dynamic>> data = workouts.map((w) {
      final json = w.toJson();
      json.remove('id');
      json.remove('created_at');
      json.remove('updated_at');
      return json;
    }).toList();

    await _supabase.from('scheduled_workouts').insert(data);
  }

  Future<void> deleteScheduledWorkout(String id) async {
    await _supabase.from('scheduled_workouts').delete().eq('id', id);
  }

  Future<void> deleteGoalSchedule(String goalId) async {
    await _supabase.from('scheduled_workouts').delete().eq('goal_id', goalId);
  }
}

final scheduledWorkoutsRepositoryProvider =
    Provider<ScheduledWorkoutsRepository>((ref) {
  return ScheduledWorkoutsRepository(Supabase.instance.client);
});

final scheduledWorkoutsProvider = FutureProvider.family<
    List<ScheduledWorkout>,
    ({
      String swimmerId,
      DateTime? startDate,
      DateTime? endDate
    })>((ref, params) async {
  final repository = ref.watch(scheduledWorkoutsRepositoryProvider);
  return repository.getScheduledWorkouts(
    swimmerId: params.swimmerId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
