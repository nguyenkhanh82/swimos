import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/training_goal.dart';
import '../domain/scheduled_workout.dart';

class MacroPlanGenerationService {
  final SupabaseClient _supabase;

  MacroPlanGenerationService(this._supabase);

  Future<List<ScheduledWorkout>> generateMacroPlan({
    required TrainingGoal goal,
    required String swimmerId,
    required int daysPerWeek,
    required int weeks,
    required int targetVolumeMin,
    required int targetVolumeMax,
    required DateTime startDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'generate-macro-plan',
        body: {
          'goal': {
            'title': goal.title,
            'description': goal.description,
            'goal_type': goal.goalType.value,
          },
          'daysPerWeek': daysPerWeek,
          'weeks': weeks,
          'targetVolumeMin': targetVolumeMin,
          'targetVolumeMax': targetVolumeMax,
        },
      );

      final List<dynamic> planData = response.data;
      final List<ScheduledWorkout> workouts = [];

      int currentDayIndex = 0;
      // simplified spacing array based on daysPerWeek, distributing workouts evenly
      List<int> validDaysOfWeek;
      if (daysPerWeek == 1)
        validDaysOfWeek = [3];
      else if (daysPerWeek == 2)
        validDaysOfWeek = [2, 5];
      else if (daysPerWeek == 3)
        validDaysOfWeek = [1, 3, 5];
      else if (daysPerWeek == 4)
        validDaysOfWeek = [1, 2, 4, 5];
      else if (daysPerWeek == 5)
        validDaysOfWeek = [1, 2, 3, 4, 5];
      else if (daysPerWeek == 6)
        validDaysOfWeek = [1, 2, 3, 4, 5, 6];
      else
        validDaysOfWeek = [1, 2, 3, 4, 5, 6, 7];

      for (int w = 0; w < weeks; w++) {
        for (int d = 0; d < 7; d++) {
          final currentDate = startDate.add(Duration(days: (w * 7) + d));
          if (validDaysOfWeek.contains(currentDate.weekday)) {
            if (currentDayIndex < planData.length) {
              final dayData = planData[currentDayIndex];
              workouts.add(ScheduledWorkout(
                  id: '',
                  userId: goal.userId,
                  swimmerId: swimmerId,
                  goalId: goal.id,
                  targetDate: currentDate,
                  focusArea: dayData['focus_area'] ?? 'Training',
                  targetDistance: dayData['target_distance'],
                  targetDurationMinutes: dayData['target_duration_minutes'],
                  notes: dayData['notes'],
                  status: 'pending'));
              currentDayIndex++;
            }
          }
        }
      }

      return workouts;
    } catch (e) {
      debugPrint('Error generating macro plan: $e');
      rethrow;
    }
  }
}

final macroPlanGenerationServiceProvider =
    Provider<MacroPlanGenerationService>((ref) {
  return MacroPlanGenerationService(Supabase.instance.client);
});
