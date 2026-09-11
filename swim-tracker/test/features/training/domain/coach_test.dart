import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/coach.dart';

void main() {
  group('Coach', () {
    test('fromJson creates Coach with all fields', () {
      final json = {
        'id': 'coach-1',
        'name': 'John Coach',
        'email': 'john@example.com',
        'phone': '123-456-7890',
        'created_by': 'user-1',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final coach = Coach.fromJson(json);

      expect(coach.id, 'coach-1');
      expect(coach.name, 'John Coach');
      expect(coach.email, 'john@example.com');
      expect(coach.phone, '123-456-7890');
      expect(coach.createdBy, 'user-1');
      expect(coach.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(coach.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'coach-1',
        'name': 'Jane Coach',
        'created_by': 'user-1',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final coach = Coach.fromJson(json);

      expect(coach.email, isNull);
      expect(coach.phone, isNull);
    });

    test('toJson converts Coach to JSON', () {
      final coach = Coach(
        id: 'coach-1',
        name: 'John Coach',
        email: 'john@example.com',
        phone: '123-456-7890',
        createdBy: 'user-1',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = coach.toJson();

      expect(json['id'], 'coach-1');
      expect(json['name'], 'John Coach');
      expect(json['email'], 'john@example.com');
      expect(json['phone'], '123-456-7890');
      expect(json['created_by'], 'user-1');
    });

    test('toJson and fromJson are inverse operations', () {
      final original = Coach(
        id: 'coach-1',
        name: 'John Coach',
        email: 'john@example.com',
        phone: '123-456-7890',
        createdBy: 'user-1',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = original.toJson();
      final recreated = Coach.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.name, original.name);
      expect(recreated.email, original.email);
      expect(recreated.phone, original.phone);
      expect(recreated.createdBy, original.createdBy);
    });
  });
}
