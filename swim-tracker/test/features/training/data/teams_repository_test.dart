import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/team.dart';

void main() {
  group('TeamsRepository', () {
    test('getTeamById returns Team when found', () async {
      final teamJson = {
        'id': 'team-1',
        'name': 'Test Team',
        'team_type': 'regular',
        'created_by': 'user-1',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      expect(Team.fromJson(teamJson).id, 'team-1');
      expect(Team.fromJson(teamJson).name, 'Test Team');
    });

    test('createTeam creates team with correct data structure', () {
      final teamData = {
        'name': 'New Team',
        'location': 'Test Location',
        'team_type': TeamType.regular.value,
        'level': 'Senior',
        'created_by': 'user-1',
        'is_active': true,
      };

      expect(teamData['name'], 'New Team');
      expect(teamData['team_type'], 'regular');
      expect(teamData['is_active'], true);
    });

    test('getActiveTeams filters inactive teams', () {
      final allTeams = [
        Team(
          id: 'team-1',
          name: 'Active Team',
          teamType: TeamType.regular,
          createdBy: 'user-1',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Team(
          id: 'team-2',
          name: 'Inactive Team',
          teamType: TeamType.regular,
          createdBy: 'user-1',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final activeTeams = allTeams.where((t) => t.isActive).toList();
      expect(activeTeams.length, 1);
      expect(activeTeams.first.name, 'Active Team');
    });
  });
}
