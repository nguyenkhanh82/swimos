// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduledWorkout _$ScheduledWorkoutFromJson(Map<String, dynamic> json) {
  return _ScheduledWorkout.fromJson(json);
}

/// @nodoc
mixin _$ScheduledWorkout {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'swimmer_id')
  String get swimmerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_id')
  String? get goalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_date')
  DateTime get targetDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'focus_area')
  String get focusArea => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_distance')
  int? get targetDistance => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_duration_minutes')
  int? get targetDurationMinutes => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'practice_id')
  String? get practiceId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ScheduledWorkout to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScheduledWorkout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduledWorkoutCopyWith<ScheduledWorkout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduledWorkoutCopyWith<$Res> {
  factory $ScheduledWorkoutCopyWith(
          ScheduledWorkout value, $Res Function(ScheduledWorkout) then) =
      _$ScheduledWorkoutCopyWithImpl<$Res, ScheduledWorkout>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'swimmer_id') String swimmerId,
      @JsonKey(name: 'goal_id') String? goalId,
      @JsonKey(name: 'target_date') DateTime targetDate,
      @JsonKey(name: 'focus_area') String focusArea,
      @JsonKey(name: 'target_distance') int? targetDistance,
      @JsonKey(name: 'target_duration_minutes') int? targetDurationMinutes,
      String? notes,
      String status,
      @JsonKey(name: 'practice_id') String? practiceId,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ScheduledWorkoutCopyWithImpl<$Res, $Val extends ScheduledWorkout>
    implements $ScheduledWorkoutCopyWith<$Res> {
  _$ScheduledWorkoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduledWorkout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? swimmerId = null,
    Object? goalId = freezed,
    Object? targetDate = null,
    Object? focusArea = null,
    Object? targetDistance = freezed,
    Object? targetDurationMinutes = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? practiceId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      swimmerId: null == swimmerId
          ? _value.swimmerId
          : swimmerId // ignore: cast_nullable_to_non_nullable
              as String,
      goalId: freezed == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String?,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      focusArea: null == focusArea
          ? _value.focusArea
          : focusArea // ignore: cast_nullable_to_non_nullable
              as String,
      targetDistance: freezed == targetDistance
          ? _value.targetDistance
          : targetDistance // ignore: cast_nullable_to_non_nullable
              as int?,
      targetDurationMinutes: freezed == targetDurationMinutes
          ? _value.targetDurationMinutes
          : targetDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      practiceId: freezed == practiceId
          ? _value.practiceId
          : practiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduledWorkoutImplCopyWith<$Res>
    implements $ScheduledWorkoutCopyWith<$Res> {
  factory _$$ScheduledWorkoutImplCopyWith(_$ScheduledWorkoutImpl value,
          $Res Function(_$ScheduledWorkoutImpl) then) =
      __$$ScheduledWorkoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'swimmer_id') String swimmerId,
      @JsonKey(name: 'goal_id') String? goalId,
      @JsonKey(name: 'target_date') DateTime targetDate,
      @JsonKey(name: 'focus_area') String focusArea,
      @JsonKey(name: 'target_distance') int? targetDistance,
      @JsonKey(name: 'target_duration_minutes') int? targetDurationMinutes,
      String? notes,
      String status,
      @JsonKey(name: 'practice_id') String? practiceId,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$ScheduledWorkoutImplCopyWithImpl<$Res>
    extends _$ScheduledWorkoutCopyWithImpl<$Res, _$ScheduledWorkoutImpl>
    implements _$$ScheduledWorkoutImplCopyWith<$Res> {
  __$$ScheduledWorkoutImplCopyWithImpl(_$ScheduledWorkoutImpl _value,
      $Res Function(_$ScheduledWorkoutImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScheduledWorkout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? swimmerId = null,
    Object? goalId = freezed,
    Object? targetDate = null,
    Object? focusArea = null,
    Object? targetDistance = freezed,
    Object? targetDurationMinutes = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? practiceId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ScheduledWorkoutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      swimmerId: null == swimmerId
          ? _value.swimmerId
          : swimmerId // ignore: cast_nullable_to_non_nullable
              as String,
      goalId: freezed == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String?,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      focusArea: null == focusArea
          ? _value.focusArea
          : focusArea // ignore: cast_nullable_to_non_nullable
              as String,
      targetDistance: freezed == targetDistance
          ? _value.targetDistance
          : targetDistance // ignore: cast_nullable_to_non_nullable
              as int?,
      targetDurationMinutes: freezed == targetDurationMinutes
          ? _value.targetDurationMinutes
          : targetDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      practiceId: freezed == practiceId
          ? _value.practiceId
          : practiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduledWorkoutImpl implements _ScheduledWorkout {
  const _$ScheduledWorkoutImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'swimmer_id') required this.swimmerId,
      @JsonKey(name: 'goal_id') this.goalId,
      @JsonKey(name: 'target_date') required this.targetDate,
      @JsonKey(name: 'focus_area') required this.focusArea,
      @JsonKey(name: 'target_distance') this.targetDistance,
      @JsonKey(name: 'target_duration_minutes') this.targetDurationMinutes,
      this.notes,
      this.status = 'pending',
      @JsonKey(name: 'practice_id') this.practiceId,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$ScheduledWorkoutImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduledWorkoutImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'swimmer_id')
  final String swimmerId;
  @override
  @JsonKey(name: 'goal_id')
  final String? goalId;
  @override
  @JsonKey(name: 'target_date')
  final DateTime targetDate;
  @override
  @JsonKey(name: 'focus_area')
  final String focusArea;
  @override
  @JsonKey(name: 'target_distance')
  final int? targetDistance;
  @override
  @JsonKey(name: 'target_duration_minutes')
  final int? targetDurationMinutes;
  @override
  final String? notes;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'practice_id')
  final String? practiceId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ScheduledWorkout(id: $id, userId: $userId, swimmerId: $swimmerId, goalId: $goalId, targetDate: $targetDate, focusArea: $focusArea, targetDistance: $targetDistance, targetDurationMinutes: $targetDurationMinutes, notes: $notes, status: $status, practiceId: $practiceId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduledWorkoutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.swimmerId, swimmerId) ||
                other.swimmerId == swimmerId) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.focusArea, focusArea) ||
                other.focusArea == focusArea) &&
            (identical(other.targetDistance, targetDistance) ||
                other.targetDistance == targetDistance) &&
            (identical(other.targetDurationMinutes, targetDurationMinutes) ||
                other.targetDurationMinutes == targetDurationMinutes) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.practiceId, practiceId) ||
                other.practiceId == practiceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      swimmerId,
      goalId,
      targetDate,
      focusArea,
      targetDistance,
      targetDurationMinutes,
      notes,
      status,
      practiceId,
      createdAt,
      updatedAt);

  /// Create a copy of ScheduledWorkout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduledWorkoutImplCopyWith<_$ScheduledWorkoutImpl> get copyWith =>
      __$$ScheduledWorkoutImplCopyWithImpl<_$ScheduledWorkoutImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduledWorkoutImplToJson(
      this,
    );
  }
}

abstract class _ScheduledWorkout implements ScheduledWorkout {
  const factory _ScheduledWorkout(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'swimmer_id') required final String swimmerId,
          @JsonKey(name: 'goal_id') final String? goalId,
          @JsonKey(name: 'target_date') required final DateTime targetDate,
          @JsonKey(name: 'focus_area') required final String focusArea,
          @JsonKey(name: 'target_distance') final int? targetDistance,
          @JsonKey(name: 'target_duration_minutes')
          final int? targetDurationMinutes,
          final String? notes,
          final String status,
          @JsonKey(name: 'practice_id') final String? practiceId,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$ScheduledWorkoutImpl;

  factory _ScheduledWorkout.fromJson(Map<String, dynamic> json) =
      _$ScheduledWorkoutImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'swimmer_id')
  String get swimmerId;
  @override
  @JsonKey(name: 'goal_id')
  String? get goalId;
  @override
  @JsonKey(name: 'target_date')
  DateTime get targetDate;
  @override
  @JsonKey(name: 'focus_area')
  String get focusArea;
  @override
  @JsonKey(name: 'target_distance')
  int? get targetDistance;
  @override
  @JsonKey(name: 'target_duration_minutes')
  int? get targetDurationMinutes;
  @override
  String? get notes;
  @override
  String get status;
  @override
  @JsonKey(name: 'practice_id')
  String? get practiceId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ScheduledWorkout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduledWorkoutImplCopyWith<_$ScheduledWorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
