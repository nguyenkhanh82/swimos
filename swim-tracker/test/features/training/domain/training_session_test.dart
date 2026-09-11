import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/training_session.dart';

void main() {
  group('TrainingSession', () {
    test('fromJson creates TrainingSession with all fields', () {
      final json = {
        'id': 'session-1',
        'user_id': 'user-1',
        'training_date': '2024-01-01',
        'set_description': '10x100 Free',
        'stroke': 'freestyle',
        'distance_per_rep': 100,
        'number_of_reps': 10,
        'total_distance': 1000,
        'rest_seconds': 30,
        'pool_type': 'SCY',
        'intensity': 'moderate',
        'notes': 'Good practice',
        'team_id': 'team-1',
        'rpe': 7,
        'day_of_week': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final session = TrainingSession.fromJson(json);

      expect(session.id, 'session-1');
      expect(session.userId, 'user-1');
      expect(session.trainingDate, DateTime.parse('2024-01-01'));
      expect(session.setDescription, '10x100 Free');
      expect(session.stroke, 'freestyle');
      expect(session.distancePerRep, 100);
      expect(session.numberOfReps, 10);
      expect(session.totalDistance, 1000);
      expect(session.restSeconds, 30);
      expect(session.poolType, 'SCY');
      expect(session.intensity, 'moderate');
      expect(session.notes, 'Good practice');
      expect(session.teamId, 'team-1');
      expect(session.rpe, 7);
      expect(session.dayOfWeek, 1);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'session-1',
        'user_id': 'user-1',
        'training_date': '2024-01-01',
        'set_description': 'Warm up',
        'stroke': 'freestyle',
        'distance_per_rep': 50,
        'number_of_reps': 4,
        'total_distance': 200,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final session = TrainingSession.fromJson(json);

      expect(session.restSeconds, isNull);
      expect(session.notes, isNull);
      expect(session.teamId, isNull);
      expect(session.rpe, isNull);
      expect(session.dayOfWeek, isNull);
      expect(session.poolType, 'SCY'); // Default value
      expect(session.intensity, 'moderate'); // Default value
    });

    test('fromJson uses default values for poolType and intensity', () {
      final json = {
        'id': 'session-1',
        'user_id': 'user-1',
        'training_date': '2024-01-01',
        'set_description': 'Test',
        'stroke': 'freestyle',
        'distance_per_rep': 50,
        'number_of_reps': 4,
        'total_distance': 200,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final session = TrainingSession.fromJson(json);

      expect(session.poolType, 'SCY');
      expect(session.intensity, 'moderate');
    });

    test('toJson converts TrainingSession to JSON', () {
      final session = TrainingSession(
        id: 'session-1',
        userId: 'user-1',
        trainingDate: DateTime.parse('2024-01-01'),
        setDescription: '10x100 Free',
        stroke: 'freestyle',
        distancePerRep: 100,
        numberOfReps: 10,
        totalDistance: 1000,
        restSeconds: 30,
        poolType: 'LCM',
        intensity: 'hard',
        notes: 'Great practice',
        teamId: 'team-1',
        rpe: 8,
        dayOfWeek: 2,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = session.toJson();

      expect(json['id'], 'session-1');
      expect(json['user_id'], 'user-1');
      expect(json['training_date'], '2024-01-01');
      expect(json['set_description'], '10x100 Free');
      expect(json['stroke'], 'freestyle');
      expect(json['distance_per_rep'], 100);
      expect(json['number_of_reps'], 10);
      expect(json['total_distance'], 1000);
      expect(json['rest_seconds'], 30);
      expect(json['pool_type'], 'LCM');
      expect(json['intensity'], 'hard');
      expect(json['notes'], 'Great practice');
      expect(json['team_id'], 'team-1');
      expect(json['rpe'], 8);
      expect(json['day_of_week'], 2);
    });

    test('toJson handles null optional fields', () {
      final session = TrainingSession(
        id: 'session-1',
        userId: 'user-1',
        trainingDate: DateTime.parse('2024-01-01'),
        setDescription: 'Warm up',
        stroke: 'freestyle',
        distancePerRep: 50,
        numberOfReps: 4,
        totalDistance: 200,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = session.toJson();

      expect(json['rest_seconds'], isNull);
      expect(json['notes'], isNull);
      expect(json['team_id'], isNull);
      expect(json['rpe'], isNull);
      expect(json['day_of_week'], isNull);
    });

    group('isIntervalSet', () {
      TrainingSession createSessionWithDescription(String setDescription) {
        return TrainingSession(
          id: 'test-id',
          userId: 'user-1',
          trainingDate: DateTime.parse('2024-01-01'),
          setDescription: setDescription,
          stroke: 'freestyle',
          distancePerRep: 100,
          numberOfReps: 5,
          totalDistance: 500,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );
      }

      test('returns true for interval set with minutes:seconds format', () {
        final session = createSessionWithDescription('5x100 on 1:10');
        expect(session.isIntervalSet(), isTrue);
      });

      test('returns true for interval set with only seconds format', () {
        final session = createSessionWithDescription('10x50 on :45');
        expect(session.isIntervalSet(), isTrue);
      });

      test('returns true for interval set with 2+ minutes', () {
        final session = createSessionWithDescription('3x200 on 2:30');
        expect(session.isIntervalSet(), isTrue);
      });

      test('returns false for continuous set without interval notation', () {
        final session = createSessionWithDescription('400 IM');
        expect(session.isIntervalSet(), isFalse);
      });

      test('returns false for set description without interval', () {
        final session = createSessionWithDescription('8x100 Free');
        expect(session.isIntervalSet(), isFalse);
      });

      test('returns false for empty set description', () {
        final session = createSessionWithDescription('');
        expect(session.isIntervalSet(), isFalse);
      });
    });

    group('getIntervalSeconds', () {
      TrainingSession createSessionWithDescription(String setDescription) {
        return TrainingSession(
          id: 'test-id',
          userId: 'user-1',
          trainingDate: DateTime.parse('2024-01-01'),
          setDescription: setDescription,
          stroke: 'freestyle',
          distancePerRep: 100,
          numberOfReps: 5,
          totalDistance: 500,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );
      }

      test('returns correct seconds for minutes:seconds format', () {
        final session = createSessionWithDescription('5x100 on 1:10');
        expect(session.getIntervalSeconds(), 70);
      });

      test('returns correct seconds for only seconds format', () {
        final session = createSessionWithDescription('10x50 on :45');
        expect(session.getIntervalSeconds(), 45);
      });

      test('returns correct seconds for 2+ minutes format', () {
        final session = createSessionWithDescription('3x200 on 2:30');
        expect(session.getIntervalSeconds(), 150);
      });

      test('returns null for continuous set without interval notation', () {
        final session = createSessionWithDescription('400 IM');
        expect(session.getIntervalSeconds(), isNull);
      });

      test('returns null for set description without interval', () {
        final session = createSessionWithDescription('8x100 Free');
        expect(session.getIntervalSeconds(), isNull);
      });

      test('returns null for empty set description', () {
        final session = createSessionWithDescription('');
        expect(session.getIntervalSeconds(), isNull);
      });

      test('parses case-insensitive interval notation', () {
        final session = createSessionWithDescription('5x100 ON 1:00');
        expect(session.getIntervalSeconds(), 60);
      });
    });
  });
}
