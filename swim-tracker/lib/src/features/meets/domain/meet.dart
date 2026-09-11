class SwimMeet {
  final String id;
  final String userId;
  final String? swimmerId;
  final String meetName;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? poolType;
  final String? swimcloudMeetId;
  final String? meetType;
  final String? organization;
  final String? swimcloudUrl;

  SwimMeet({
    required this.id,
    required this.userId,
    this.swimmerId,
    required this.meetName,
    required this.startDate,
    this.endDate,
    this.location,
    this.poolType,
    this.swimcloudMeetId,
    this.meetType,
    this.organization,
    this.swimcloudUrl,
  });

  factory SwimMeet.fromJson(Map<String, dynamic> json) {
    return SwimMeet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      meetName: json['meet_name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      location: json['location'] as String?,
      poolType: json['pool_type'] as String?,
      swimcloudMeetId: json['swimcloud_meet_id'] as String?,
      meetType: json['meet_type'] as String?,
      organization: json['organization'] as String?,
      swimcloudUrl: json['swimcloud_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'meet_name': meetName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'pool_type': poolType,
      'swimcloud_meet_id': swimcloudMeetId,
      'meet_type': meetType,
      'organization': organization,
      'swimcloud_url': swimcloudUrl,
    };
  }
}
