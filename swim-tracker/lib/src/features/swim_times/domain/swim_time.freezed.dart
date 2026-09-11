// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swim_time.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwimTime _$SwimTimeFromJson(Map<String, dynamic> json) {
  return _SwimTime.fromJson(json);
}

/// @nodoc
mixin _$SwimTime {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'swimmer_id')
  String get swimmerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_name')
  String? get eventName => throw _privateConstructorUsedError;
  Stroke get stroke => throw _privateConstructorUsedError;
  int get distance => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_seconds')
  double get timeSeconds => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'meet_name')
  String? get meetName => throw _privateConstructorUsedError;
  String get course =>
      throw _privateConstructorUsedError; // 'SCY', 'SCM', or 'LCM'
  @JsonKey(name: 'is_personal_best')
  bool get isPersonalBest => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SwimTime to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwimTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwimTimeCopyWith<SwimTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwimTimeCopyWith<$Res> {
  factory $SwimTimeCopyWith(SwimTime value, $Res Function(SwimTime) then) =
      _$SwimTimeCopyWithImpl<$Res, SwimTime>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'swimmer_id') String swimmerId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'event_name') String? eventName,
      Stroke stroke,
      int distance,
      @JsonKey(name: 'time_seconds') double timeSeconds,
      DateTime date,
      @JsonKey(name: 'meet_name') String? meetName,
      String course,
      @JsonKey(name: 'is_personal_best') bool isPersonalBest,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$SwimTimeCopyWithImpl<$Res, $Val extends SwimTime>
    implements $SwimTimeCopyWith<$Res> {
  _$SwimTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwimTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? swimmerId = null,
    Object? userId = null,
    Object? eventName = freezed,
    Object? stroke = null,
    Object? distance = null,
    Object? timeSeconds = null,
    Object? date = null,
    Object? meetName = freezed,
    Object? course = null,
    Object? isPersonalBest = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      swimmerId: null == swimmerId
          ? _value.swimmerId
          : swimmerId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: freezed == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String?,
      stroke: null == stroke
          ? _value.stroke
          : stroke // ignore: cast_nullable_to_non_nullable
              as Stroke,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as int,
      timeSeconds: null == timeSeconds
          ? _value.timeSeconds
          : timeSeconds // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      meetName: freezed == meetName
          ? _value.meetName
          : meetName // ignore: cast_nullable_to_non_nullable
              as String?,
      course: null == course
          ? _value.course
          : course // ignore: cast_nullable_to_non_nullable
              as String,
      isPersonalBest: null == isPersonalBest
          ? _value.isPersonalBest
          : isPersonalBest // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwimTimeImplCopyWith<$Res>
    implements $SwimTimeCopyWith<$Res> {
  factory _$$SwimTimeImplCopyWith(
          _$SwimTimeImpl value, $Res Function(_$SwimTimeImpl) then) =
      __$$SwimTimeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'swimmer_id') String swimmerId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'event_name') String? eventName,
      Stroke stroke,
      int distance,
      @JsonKey(name: 'time_seconds') double timeSeconds,
      DateTime date,
      @JsonKey(name: 'meet_name') String? meetName,
      String course,
      @JsonKey(name: 'is_personal_best') bool isPersonalBest,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$SwimTimeImplCopyWithImpl<$Res>
    extends _$SwimTimeCopyWithImpl<$Res, _$SwimTimeImpl>
    implements _$$SwimTimeImplCopyWith<$Res> {
  __$$SwimTimeImplCopyWithImpl(
      _$SwimTimeImpl _value, $Res Function(_$SwimTimeImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwimTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? swimmerId = null,
    Object? userId = null,
    Object? eventName = freezed,
    Object? stroke = null,
    Object? distance = null,
    Object? timeSeconds = null,
    Object? date = null,
    Object? meetName = freezed,
    Object? course = null,
    Object? isPersonalBest = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SwimTimeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      swimmerId: null == swimmerId
          ? _value.swimmerId
          : swimmerId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: freezed == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String?,
      stroke: null == stroke
          ? _value.stroke
          : stroke // ignore: cast_nullable_to_non_nullable
              as Stroke,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as int,
      timeSeconds: null == timeSeconds
          ? _value.timeSeconds
          : timeSeconds // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      meetName: freezed == meetName
          ? _value.meetName
          : meetName // ignore: cast_nullable_to_non_nullable
              as String?,
      course: null == course
          ? _value.course
          : course // ignore: cast_nullable_to_non_nullable
              as String,
      isPersonalBest: null == isPersonalBest
          ? _value.isPersonalBest
          : isPersonalBest // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwimTimeImpl implements _SwimTime {
  const _$SwimTimeImpl(
      {required this.id,
      @JsonKey(name: 'swimmer_id') required this.swimmerId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'event_name') this.eventName,
      required this.stroke,
      required this.distance,
      @JsonKey(name: 'time_seconds') required this.timeSeconds,
      required this.date,
      @JsonKey(name: 'meet_name') this.meetName,
      required this.course,
      @JsonKey(name: 'is_personal_best') this.isPersonalBest = false,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$SwimTimeImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwimTimeImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'swimmer_id')
  final String swimmerId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'event_name')
  final String? eventName;
  @override
  final Stroke stroke;
  @override
  final int distance;
  @override
  @JsonKey(name: 'time_seconds')
  final double timeSeconds;
  @override
  final DateTime date;
  @override
  @JsonKey(name: 'meet_name')
  final String? meetName;
  @override
  final String course;
// 'SCY', 'SCM', or 'LCM'
  @override
  @JsonKey(name: 'is_personal_best')
  final bool isPersonalBest;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'SwimTime(id: $id, swimmerId: $swimmerId, userId: $userId, eventName: $eventName, stroke: $stroke, distance: $distance, timeSeconds: $timeSeconds, date: $date, meetName: $meetName, course: $course, isPersonalBest: $isPersonalBest, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwimTimeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.swimmerId, swimmerId) ||
                other.swimmerId == swimmerId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.stroke, stroke) || other.stroke == stroke) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.timeSeconds, timeSeconds) ||
                other.timeSeconds == timeSeconds) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.meetName, meetName) ||
                other.meetName == meetName) &&
            (identical(other.course, course) || other.course == course) &&
            (identical(other.isPersonalBest, isPersonalBest) ||
                other.isPersonalBest == isPersonalBest) &&
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
      swimmerId,
      userId,
      eventName,
      stroke,
      distance,
      timeSeconds,
      date,
      meetName,
      course,
      isPersonalBest,
      createdAt,
      updatedAt);

  /// Create a copy of SwimTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwimTimeImplCopyWith<_$SwimTimeImpl> get copyWith =>
      __$$SwimTimeImplCopyWithImpl<_$SwimTimeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwimTimeImplToJson(
      this,
    );
  }
}

abstract class _SwimTime implements SwimTime {
  const factory _SwimTime(
          {required final String id,
          @JsonKey(name: 'swimmer_id') required final String swimmerId,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'event_name') final String? eventName,
          required final Stroke stroke,
          required final int distance,
          @JsonKey(name: 'time_seconds') required final double timeSeconds,
          required final DateTime date,
          @JsonKey(name: 'meet_name') final String? meetName,
          required final String course,
          @JsonKey(name: 'is_personal_best') final bool isPersonalBest,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$SwimTimeImpl;

  factory _SwimTime.fromJson(Map<String, dynamic> json) =
      _$SwimTimeImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'swimmer_id')
  String get swimmerId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'event_name')
  String? get eventName;
  @override
  Stroke get stroke;
  @override
  int get distance;
  @override
  @JsonKey(name: 'time_seconds')
  double get timeSeconds;
  @override
  DateTime get date;
  @override
  @JsonKey(name: 'meet_name')
  String? get meetName;
  @override
  String get course; // 'SCY', 'SCM', or 'LCM'
  @override
  @JsonKey(name: 'is_personal_best')
  bool get isPersonalBest;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of SwimTime
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwimTimeImplCopyWith<_$SwimTimeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
