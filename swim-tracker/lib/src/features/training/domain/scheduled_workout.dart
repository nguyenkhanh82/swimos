import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_workout.freezed.dart';
part 'scheduled_workout.g.dart';

@freezed
class ScheduledWorkout with _$ScheduledWorkout {
  const factory ScheduledWorkout({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'swimmer_id') required String swimmerId,
    @JsonKey(name: 'goal_id') String? goalId,
    @JsonKey(name: 'target_date') required DateTime targetDate,
    @JsonKey(name: 'focus_area') required String focusArea,
    @JsonKey(name: 'target_distance') int? targetDistance,
    @JsonKey(name: 'target_duration_minutes') int? targetDurationMinutes,
    String? notes,
    @Default('pending') String status,
    @JsonKey(name: 'practice_id') String? practiceId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ScheduledWorkout;

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) =>
      _$ScheduledWorkoutFromJson(json);
}
