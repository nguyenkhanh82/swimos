// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduledWorkoutImpl _$$ScheduledWorkoutImplFromJson(
        Map<String, dynamic> json) =>
    _$ScheduledWorkoutImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String,
      goalId: json['goal_id'] as String?,
      targetDate: DateTime.parse(json['target_date'] as String),
      focusArea: json['focus_area'] as String,
      targetDistance: (json['target_distance'] as num?)?.toInt(),
      targetDurationMinutes: (json['target_duration_minutes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      practiceId: json['practice_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ScheduledWorkoutImplToJson(
        _$ScheduledWorkoutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'swimmer_id': instance.swimmerId,
      'goal_id': instance.goalId,
      'target_date': instance.targetDate.toIso8601String(),
      'focus_area': instance.focusArea,
      'target_distance': instance.targetDistance,
      'target_duration_minutes': instance.targetDurationMinutes,
      'notes': instance.notes,
      'status': instance.status,
      'practice_id': instance.practiceId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
