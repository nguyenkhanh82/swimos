import 'package:freezed_annotation/freezed_annotation.dart';

part 'swimmer_profile.freezed.dart';
part 'swimmer_profile.g.dart';

@freezed
class SwimmerProfile with _$SwimmerProfile {
  const factory SwimmerProfile({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'swimcloud_id') required String swimcloudId,
    @JsonKey(name: 'swimcloud_person_id') String? swimcloudPersonId,
    @JsonKey(name: 'full_name') String? fullName,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    String? gender, // 'M' or 'F'
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    String? notes,
    @JsonKey(name: 'last_fetched_at') DateTime? lastFetchedAt,
    // New fields for comprehensive profile
    @JsonKey(name: 'weight_kg') double? weightKg,
    @JsonKey(name: 'height_cm') double? heightCm,
    @JsonKey(name: 'swim_usa_id') String? swimUsaId,
    String? allergies,
    @JsonKey(name: 'unit_preference') @Default('metric') String unitPreference, // 'imperial' or 'metric'
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _SwimmerProfile;

  factory SwimmerProfile.fromJson(Map<String, dynamic> json) =>
      _$SwimmerProfileFromJson(json);
}

extension SwimmerProfileExtension on SwimmerProfile {
  /// Calculate age from birth date
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}
