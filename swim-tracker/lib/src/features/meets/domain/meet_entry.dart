class MeetEntry {
  final String id;
  final String userId;
  final String? swimmerId;
  final String meetId;
  final String eventName;
  final double? seedTimeSeconds;
  final double? finalTimeSeconds;
  final int? place;
  final bool isPersonalBest;
  final int? heat;
  final int? lane;
  final String? notes;
  final DateTime createdAt;

  MeetEntry({
    required this.id,
    required this.userId,
    this.swimmerId,
    required this.meetId,
    required this.eventName,
    this.seedTimeSeconds,
    this.finalTimeSeconds,
    this.place,
    this.isPersonalBest = false,
    this.heat,
    this.lane,
    this.notes,
    required this.createdAt,
  });

  factory MeetEntry.fromJson(Map<String, dynamic> json) {
    return MeetEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      meetId: json['meet_id'] as String,
      eventName: json['event_name'] as String,
      seedTimeSeconds: (json['seed_time_seconds'] as num?)?.toDouble(),
      finalTimeSeconds: (json['final_time_seconds'] as num?)?.toDouble(),
      place: json['place'] as int?,
      isPersonalBest: json['is_personal_best'] as bool? ?? false,
      heat: json['heat'] as int?,
      lane: json['lane'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
