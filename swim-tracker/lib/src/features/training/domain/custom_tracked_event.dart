import 'stroke.dart';

class CustomTrackedEvent {
  final String id;
  final String userId;
  final String? swimmerId;
  final String? teamId;
  final String eventName;
  final Stroke? stroke;
  final int? distance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomTrackedEvent({
    required this.id,
    required this.userId,
    this.swimmerId,
    this.teamId,
    required this.eventName,
    this.stroke,
    this.distance,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomTrackedEvent.fromJson(Map<String, dynamic> json) {
    return CustomTrackedEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      swimmerId: json['swimmer_id'] as String?,
      teamId: json['team_id'] as String?,
      eventName: json['event_name'] as String,
      stroke: json['stroke'] != null
          ? Stroke.fromString(json['stroke'] as String)
          : null,
      distance: json['distance'] as int?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'swimmer_id': swimmerId,
      'team_id': teamId,
      'event_name': eventName,
      'stroke': stroke?.value,
      'distance': distance,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

