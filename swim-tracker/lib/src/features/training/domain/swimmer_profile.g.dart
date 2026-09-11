// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swimmer_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwimmerProfileImpl _$$SwimmerProfileImplFromJson(Map<String, dynamic> json) =>
    _$SwimmerProfileImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimcloudId: json['swimcloud_id'] as String,
      swimcloudPersonId: json['swimcloud_person_id'] as String?,
      fullName: json['full_name'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      notes: json['notes'] as String?,
      lastFetchedAt: json['last_fetched_at'] == null
          ? null
          : DateTime.parse(json['last_fetched_at'] as String),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      swimUsaId: json['swim_usa_id'] as String?,
      allergies: json['allergies'] as String?,
      unitPreference: json['unit_preference'] as String? ?? 'metric',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SwimmerProfileImplToJson(
        _$SwimmerProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'swimcloud_id': instance.swimcloudId,
      'swimcloud_person_id': instance.swimcloudPersonId,
      'full_name': instance.fullName,
      'birth_date': instance.birthDate?.toIso8601String(),
      'gender': instance.gender,
      'avatar_url': instance.avatarUrl,
      'is_primary': instance.isPrimary,
      'notes': instance.notes,
      'last_fetched_at': instance.lastFetchedAt?.toIso8601String(),
      'weight_kg': instance.weightKg,
      'height_cm': instance.heightCm,
      'swim_usa_id': instance.swimUsaId,
      'allergies': instance.allergies,
      'unit_preference': instance.unitPreference,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
