import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/team.dart';

void main() {
  group('Team', () {
    test('fromJson creates Team with all fields', () {
      final json = {
        'id': 'team-1',
        'name': 'Test Team',
        'location': 'Test Location',
        'team_type': 'regular',
        'level': 'Senior',
        'created_by': 'user-1',
        'is_active': true,
        'sportengines_id': 'se-123',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final team = Team.fromJson(json);

      expect(team.id, 'team-1');
      expect(team.name, 'Test Team');
      expect(team.location, 'Test Location');
      expect(team.teamType, TeamType.regular);
      expect(team.level, 'Senior');
      expect(team.createdBy, 'user-1');
      expect(team.isActive, true);
      expect(team.sportenginesId, 'se-123');
      expect(team.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(team.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'team-1',
        'name': 'Test Team',
        'team_type': 'camp',
        'created_by': 'user-1',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final team = Team.fromJson(json);

      expect(team.location, isNull);
      expect(team.level, isNull);
      expect(team.sportenginesId, isNull);
      expect(team.isActive, true); // Default value
    });

    test('toJson converts Team to JSON', () {
      final team = Team(
        id: 'team-1',
        name: 'Test Team',
        location: 'Test Location',
        teamType: TeamType.privateCoach,
        level: 'Elite',
        createdBy: 'user-1',
        isActive: false,
        sportenginesId: 'se-456',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = team.toJson();

      expect(json['id'], 'team-1');
      expect(json['name'], 'Test Team');
      expect(json['location'], 'Test Location');
      expect(json['team_type'], 'private_coach');
      expect(json['level'], 'Elite');
      expect(json['created_by'], 'user-1');
      expect(json['is_active'], false);
      expect(json['sportengines_id'], 'se-456');
    });

    test('toJson and fromJson are inverse operations', () {
      final original = Team(
        id: 'team-1',
        name: 'Test Team',
        location: 'Test Location',
        teamType: TeamType.self,
        level: 'Intermediate',
        createdBy: 'user-1',
        isActive: true,
        sportenginesId: 'se-789',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = original.toJson();
      final recreated = Team.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.name, original.name);
      expect(recreated.location, original.location);
      expect(recreated.teamType, original.teamType);
      expect(recreated.level, original.level);
      expect(recreated.createdBy, original.createdBy);
      expect(recreated.isActive, original.isActive);
      expect(recreated.sportenginesId, original.sportenginesId);
    });
  });

  group('TeamType', () {
    test('fromString returns correct TeamType for valid values', () {
      expect(TeamType.fromString('regular'), TeamType.regular);
      expect(TeamType.fromString('camp'), TeamType.camp);
      expect(TeamType.fromString('private_coach'), TeamType.privateCoach);
      expect(TeamType.fromString('self'), TeamType.self);
    });

    test('fromString returns regular as default for invalid values', () {
      expect(TeamType.fromString('invalid'), TeamType.regular);
      expect(TeamType.fromString(''), TeamType.regular);
    });

    test('value returns correct string representation', () {
      expect(TeamType.regular.value, 'regular');
      expect(TeamType.camp.value, 'camp');
      expect(TeamType.privateCoach.value, 'private_coach');
      expect(TeamType.self.value, 'self');
    });
  });
}
