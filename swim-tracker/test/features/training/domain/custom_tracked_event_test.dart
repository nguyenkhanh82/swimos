import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/custom_tracked_event.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/stroke.dart';

void main() {
  group('CustomTrackedEvent', () {
    test('fromJson creates CustomTrackedEvent with all fields', () {
      final json = {
        'id': 'event-1',
        'user_id': 'user-1',
        'team_id': 'team-1',
        'event_name': '100m Freestyle',
        'stroke': 'Free',
        'distance': 100,
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final event = CustomTrackedEvent.fromJson(json);

      expect(event.id, 'event-1');
      expect(event.userId, 'user-1');
      expect(event.teamId, 'team-1');
      expect(event.eventName, '100m Freestyle');
      expect(event.stroke, Stroke.free);
      expect(event.distance, 100);
      expect(event.isActive, true);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'event-1',
        'user_id': 'user-1',
        'event_name': 'Custom Event',
        'is_active': false,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final event = CustomTrackedEvent.fromJson(json);

      expect(event.teamId, isNull);
      expect(event.stroke, isNull);
      expect(event.distance, isNull);
      expect(event.isActive, false);
    });

    test('fromJson defaults isActive to true when null', () {
      final json = {
        'id': 'event-1',
        'user_id': 'user-1',
        'event_name': 'Custom Event',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final event = CustomTrackedEvent.fromJson(json);

      expect(event.isActive, true);
    });

    test('toJson converts CustomTrackedEvent to JSON', () {
      final event = CustomTrackedEvent(
        id: 'event-1',
        userId: 'user-1',
        teamId: 'team-1',
        eventName: '200m Backstroke',
        stroke: Stroke.back,
        distance: 200,
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = event.toJson();

      expect(json['id'], 'event-1');
      expect(json['user_id'], 'user-1');
      expect(json['team_id'], 'team-1');
      expect(json['event_name'], '200m Backstroke');
      expect(json['stroke'], 'Back');
      expect(json['distance'], 200);
      expect(json['is_active'], true);
    });

    test('toJson handles null optional fields', () {
      final event = CustomTrackedEvent(
        id: 'event-1',
        userId: 'user-1',
        eventName: 'Custom Event',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = event.toJson();

      expect(json['team_id'], isNull);
      expect(json['stroke'], isNull);
      expect(json['distance'], isNull);
    });
  });
}
