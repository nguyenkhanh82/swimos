import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/team_member.dart';

void main() {
  group('TeamMember', () {
    test('fromJson creates TeamMember with all fields', () {
      final json = {
        'id': 'member-1',
        'user_id': 'user-1',
        'swimmer_id': 'swimmer-1',
        'swimcloud_id': '12345',
        'team_id': 'team-1',
        'status': 'active',
        'joined_date': '2024-01-01',
        'left_date': '2024-12-31',
        'role': 'swimmer',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final member = TeamMember.fromJson(json);

      expect(member.id, 'member-1');
      expect(member.userId, 'user-1');
      expect(member.swimmerId, 'swimmer-1');
      expect(member.swimcloudId, '12345');
      expect(member.teamId, 'team-1');
      expect(member.status, TeamMemberStatus.active);
      expect(member.joinedDate, DateTime.parse('2024-01-01'));
      expect(member.leftDate, DateTime.parse('2024-12-31'));
      expect(member.role, 'swimmer');
    });

    test('fromJson handles null leftDate', () {
      final json = {
        'id': 'member-1',
        'user_id': 'user-1',
        'swimmer_id': 'swimmer-1',
        'team_id': 'team-1',
        'status': 'active',
        'joined_date': '2024-01-01',
        'role': 'captain',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final member = TeamMember.fromJson(json);

      expect(member.leftDate, isNull);
      expect(member.role, 'captain');
    });

    test('fromJson defaults role to swimmer when null', () {
      final json = {
        'id': 'member-1',
        'user_id': 'user-1',
        'swimmer_id': 'swimmer-1',
        'team_id': 'team-1',
        'status': 'active',
        'joined_date': '2024-01-01',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final member = TeamMember.fromJson(json);

      expect(member.role, 'swimmer');
    });

    test('toJson converts TeamMember to JSON', () {
      final member = TeamMember(
        id: 'member-1',
        userId: 'user-1',
        swimmerId: 'swimmer-1',
        swimcloudId: '12345',
        teamId: 'team-1',
        status: TeamMemberStatus.past,
        joinedDate: DateTime.parse('2024-01-01'),
        leftDate: DateTime.parse('2024-12-31'),
        role: 'coach',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = member.toJson();

      expect(json['id'], 'member-1');
      expect(json['user_id'], 'user-1');
      expect(json['swimmer_id'], 'swimmer-1');
      expect(json['swimcloud_id'], '12345');
      expect(json['team_id'], 'team-1');
      expect(json['status'], 'past');
      expect(json['joined_date'], '2024-01-01');
      expect(json['left_date'], '2024-12-31');
      expect(json['role'], 'coach');
    });

    test('toJson handles null leftDate', () {
      final member = TeamMember(
        id: 'member-1',
        userId: 'user-1',
        swimmerId: 'swimmer-1',
        teamId: 'team-1',
        status: TeamMemberStatus.active,
        joinedDate: DateTime.parse('2024-01-01'),
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = member.toJson();

      expect(json['left_date'], isNull);
    });
  });

  group('TeamMemberStatus', () {
    test('fromString returns correct status for valid values', () {
      expect(TeamMemberStatus.fromString('active'), TeamMemberStatus.active);
      expect(TeamMemberStatus.fromString('past'), TeamMemberStatus.past);
    });

    test('fromString returns active as default for invalid values', () {
      expect(TeamMemberStatus.fromString('invalid'), TeamMemberStatus.active);
      expect(TeamMemberStatus.fromString(''), TeamMemberStatus.active);
    });

    test('value returns correct string representation', () {
      expect(TeamMemberStatus.active.value, 'active');
      expect(TeamMemberStatus.past.value, 'past');
    });
  });
}
