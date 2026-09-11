// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swim_time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwimTimeImpl _$$SwimTimeImplFromJson(Map<String, dynamic> json) =>
    _$SwimTimeImpl(
      id: json['id'] as String,
      swimmerId: json['swimmer_id'] as String,
      userId: json['user_id'] as String,
      eventName: json['event_name'] as String?,
      stroke: $enumDecode(_$StrokeEnumMap, json['stroke']),
      distance: (json['distance'] as num).toInt(),
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      meetName: json['meet_name'] as String?,
      course: json['course'] as String,
      isPersonalBest: json['is_personal_best'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SwimTimeImplToJson(_$SwimTimeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'swimmer_id': instance.swimmerId,
      'user_id': instance.userId,
      'event_name': instance.eventName,
      'stroke': _$StrokeEnumMap[instance.stroke]!,
      'distance': instance.distance,
      'time_seconds': instance.timeSeconds,
      'date': instance.date.toIso8601String(),
      'meet_name': instance.meetName,
      'course': instance.course,
      'is_personal_best': instance.isPersonalBest,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$StrokeEnumMap = {
  Stroke.free: 'free',
  Stroke.back: 'back',
  Stroke.breast: 'breast',
  Stroke.fly: 'fly',
  Stroke.im: 'im',
};
