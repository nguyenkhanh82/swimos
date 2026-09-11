// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swimmer_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwimmerProfile _$SwimmerProfileFromJson(Map<String, dynamic> json) {
  return _SwimmerProfile.fromJson(json);
}

/// @nodoc
mixin _$SwimmerProfile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'swimcloud_id')
  String get swimcloudId => throw _privateConstructorUsedError;
  @JsonKey(name: 'swimcloud_person_id')
  String? get swimcloudPersonId => throw _privateConstructorUsedError;
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  @JsonKey(name: 'birth_date')
  DateTime? get birthDate => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError; // 'M' or 'F'
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_primary')
  bool get isPrimary => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_fetched_at')
  DateTime? get lastFetchedAt =>
      throw _privateConstructorUsedError; // New fields for comprehensive profile
  @JsonKey(name: 'weight_kg')
  double? get weightKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'height_cm')
  double? get heightCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'swim_usa_id')
  String? get swimUsaId => throw _privateConstructorUsedError;
  String? get allergies => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_preference')
  String get unitPreference =>
      throw _privateConstructorUsedError; // 'imperial' or 'metric'
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SwimmerProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwimmerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwimmerProfileCopyWith<SwimmerProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwimmerProfileCopyWith<$Res> {
  factory $SwimmerProfileCopyWith(
          SwimmerProfile value, $Res Function(SwimmerProfile) then) =
      _$SwimmerProfileCopyWithImpl<$Res, SwimmerProfile>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'swimcloud_id') String swimcloudId,
      @JsonKey(name: 'swimcloud_person_id') String? swimcloudPersonId,
      @JsonKey(name: 'full_name') String? fullName,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      String? gender,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_primary') bool isPrimary,
      String? notes,
      @JsonKey(name: 'last_fetched_at') DateTime? lastFetchedAt,
      @JsonKey(name: 'weight_kg') double? weightKg,
      @JsonKey(name: 'height_cm') double? heightCm,
      @JsonKey(name: 'swim_usa_id') String? swimUsaId,
      String? allergies,
      @JsonKey(name: 'unit_preference') String unitPreference,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$SwimmerProfileCopyWithImpl<$Res, $Val extends SwimmerProfile>
    implements $SwimmerProfileCopyWith<$Res> {
  _$SwimmerProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwimmerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? swimcloudId = null,
    Object? swimcloudPersonId = freezed,
    Object? fullName = freezed,
    Object? birthDate = freezed,
    Object? gender = freezed,
    Object? avatarUrl = freezed,
    Object? isPrimary = null,
    Object? notes = freezed,
    Object? lastFetchedAt = freezed,
    Object? weightKg = freezed,
    Object? heightCm = freezed,
    Object? swimUsaId = freezed,
    Object? allergies = freezed,
    Object? unitPreference = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      swimcloudId: null == swimcloudId
          ? _value.swimcloudId
          : swimcloudId // ignore: cast_nullable_to_non_nullable
              as String,
      swimcloudPersonId: freezed == swimcloudPersonId
          ? _value.swimcloudPersonId
          : swimcloudPersonId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      lastFetchedAt: freezed == lastFetchedAt
          ? _value.lastFetchedAt
          : lastFetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      heightCm: freezed == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double?,
      swimUsaId: freezed == swimUsaId
          ? _value.swimUsaId
          : swimUsaId // ignore: cast_nullable_to_non_nullable
              as String?,
      allergies: freezed == allergies
          ? _value.allergies
          : allergies // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPreference: null == unitPreference
          ? _value.unitPreference
          : unitPreference // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$SwimmerProfileImplCopyWith<$Res>
    implements $SwimmerProfileCopyWith<$Res> {
  factory _$$SwimmerProfileImplCopyWith(_$SwimmerProfileImpl value,
          $Res Function(_$SwimmerProfileImpl) then) =
      __$$SwimmerProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'swimcloud_id') String swimcloudId,
      @JsonKey(name: 'swimcloud_person_id') String? swimcloudPersonId,
      @JsonKey(name: 'full_name') String? fullName,
      @JsonKey(name: 'birth_date') DateTime? birthDate,
      String? gender,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_primary') bool isPrimary,
      String? notes,
      @JsonKey(name: 'last_fetched_at') DateTime? lastFetchedAt,
      @JsonKey(name: 'weight_kg') double? weightKg,
      @JsonKey(name: 'height_cm') double? heightCm,
      @JsonKey(name: 'swim_usa_id') String? swimUsaId,
      String? allergies,
      @JsonKey(name: 'unit_preference') String unitPreference,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$SwimmerProfileImplCopyWithImpl<$Res>
    extends _$SwimmerProfileCopyWithImpl<$Res, _$SwimmerProfileImpl>
    implements _$$SwimmerProfileImplCopyWith<$Res> {
  __$$SwimmerProfileImplCopyWithImpl(
      _$SwimmerProfileImpl _value, $Res Function(_$SwimmerProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwimmerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? swimcloudId = null,
    Object? swimcloudPersonId = freezed,
    Object? fullName = freezed,
    Object? birthDate = freezed,
    Object? gender = freezed,
    Object? avatarUrl = freezed,
    Object? isPrimary = null,
    Object? notes = freezed,
    Object? lastFetchedAt = freezed,
    Object? weightKg = freezed,
    Object? heightCm = freezed,
    Object? swimUsaId = freezed,
    Object? allergies = freezed,
    Object? unitPreference = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SwimmerProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      swimcloudId: null == swimcloudId
          ? _value.swimcloudId
          : swimcloudId // ignore: cast_nullable_to_non_nullable
              as String,
      swimcloudPersonId: freezed == swimcloudPersonId
          ? _value.swimcloudPersonId
          : swimcloudPersonId // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      lastFetchedAt: freezed == lastFetchedAt
          ? _value.lastFetchedAt
          : lastFetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      heightCm: freezed == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double?,
      swimUsaId: freezed == swimUsaId
          ? _value.swimUsaId
          : swimUsaId // ignore: cast_nullable_to_non_nullable
              as String?,
      allergies: freezed == allergies
          ? _value.allergies
          : allergies // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPreference: null == unitPreference
          ? _value.unitPreference
          : unitPreference // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$SwimmerProfileImpl implements _SwimmerProfile {
  const _$SwimmerProfileImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'swimcloud_id') required this.swimcloudId,
      @JsonKey(name: 'swimcloud_person_id') this.swimcloudPersonId,
      @JsonKey(name: 'full_name') this.fullName,
      @JsonKey(name: 'birth_date') this.birthDate,
      this.gender,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'is_primary') this.isPrimary = false,
      this.notes,
      @JsonKey(name: 'last_fetched_at') this.lastFetchedAt,
      @JsonKey(name: 'weight_kg') this.weightKg,
      @JsonKey(name: 'height_cm') this.heightCm,
      @JsonKey(name: 'swim_usa_id') this.swimUsaId,
      this.allergies,
      @JsonKey(name: 'unit_preference') this.unitPreference = 'metric',
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$SwimmerProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwimmerProfileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'swimcloud_id')
  final String swimcloudId;
  @override
  @JsonKey(name: 'swimcloud_person_id')
  final String? swimcloudPersonId;
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  @override
  final String? gender;
// 'M' or 'F'
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'last_fetched_at')
  final DateTime? lastFetchedAt;
// New fields for comprehensive profile
  @override
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  @override
  @JsonKey(name: 'height_cm')
  final double? heightCm;
  @override
  @JsonKey(name: 'swim_usa_id')
  final String? swimUsaId;
  @override
  final String? allergies;
  @override
  @JsonKey(name: 'unit_preference')
  final String unitPreference;
// 'imperial' or 'metric'
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'SwimmerProfile(id: $id, userId: $userId, swimcloudId: $swimcloudId, swimcloudPersonId: $swimcloudPersonId, fullName: $fullName, birthDate: $birthDate, gender: $gender, avatarUrl: $avatarUrl, isPrimary: $isPrimary, notes: $notes, lastFetchedAt: $lastFetchedAt, weightKg: $weightKg, heightCm: $heightCm, swimUsaId: $swimUsaId, allergies: $allergies, unitPreference: $unitPreference, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwimmerProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.swimcloudId, swimcloudId) ||
                other.swimcloudId == swimcloudId) &&
            (identical(other.swimcloudPersonId, swimcloudPersonId) ||
                other.swimcloudPersonId == swimcloudPersonId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.lastFetchedAt, lastFetchedAt) ||
                other.lastFetchedAt == lastFetchedAt) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.swimUsaId, swimUsaId) ||
                other.swimUsaId == swimUsaId) &&
            (identical(other.allergies, allergies) ||
                other.allergies == allergies) &&
            (identical(other.unitPreference, unitPreference) ||
                other.unitPreference == unitPreference) &&
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
      swimcloudId,
      swimcloudPersonId,
      fullName,
      birthDate,
      gender,
      avatarUrl,
      isPrimary,
      notes,
      lastFetchedAt,
      weightKg,
      heightCm,
      swimUsaId,
      allergies,
      unitPreference,
      createdAt,
      updatedAt);

  /// Create a copy of SwimmerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwimmerProfileImplCopyWith<_$SwimmerProfileImpl> get copyWith =>
      __$$SwimmerProfileImplCopyWithImpl<_$SwimmerProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwimmerProfileImplToJson(
      this,
    );
  }
}

abstract class _SwimmerProfile implements SwimmerProfile {
  const factory _SwimmerProfile(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'swimcloud_id') required final String swimcloudId,
          @JsonKey(name: 'swimcloud_person_id') final String? swimcloudPersonId,
          @JsonKey(name: 'full_name') final String? fullName,
          @JsonKey(name: 'birth_date') final DateTime? birthDate,
          final String? gender,
          @JsonKey(name: 'avatar_url') final String? avatarUrl,
          @JsonKey(name: 'is_primary') final bool isPrimary,
          final String? notes,
          @JsonKey(name: 'last_fetched_at') final DateTime? lastFetchedAt,
          @JsonKey(name: 'weight_kg') final double? weightKg,
          @JsonKey(name: 'height_cm') final double? heightCm,
          @JsonKey(name: 'swim_usa_id') final String? swimUsaId,
          final String? allergies,
          @JsonKey(name: 'unit_preference') final String unitPreference,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$SwimmerProfileImpl;

  factory _SwimmerProfile.fromJson(Map<String, dynamic> json) =
      _$SwimmerProfileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'swimcloud_id')
  String get swimcloudId;
  @override
  @JsonKey(name: 'swimcloud_person_id')
  String? get swimcloudPersonId;
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  @JsonKey(name: 'birth_date')
  DateTime? get birthDate;
  @override
  String? get gender; // 'M' or 'F'
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'is_primary')
  bool get isPrimary;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'last_fetched_at')
  DateTime? get lastFetchedAt; // New fields for comprehensive profile
  @override
  @JsonKey(name: 'weight_kg')
  double? get weightKg;
  @override
  @JsonKey(name: 'height_cm')
  double? get heightCm;
  @override
  @JsonKey(name: 'swim_usa_id')
  String? get swimUsaId;
  @override
  String? get allergies;
  @override
  @JsonKey(name: 'unit_preference')
  String get unitPreference; // 'imperial' or 'metric'
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of SwimmerProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwimmerProfileImplCopyWith<_$SwimmerProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
