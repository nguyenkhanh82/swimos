import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/team.dart';
import '../domain/team_member.dart';
import '../domain/swimmer_profile.dart';
import 'swimmers_repository.dart';

class TeamsRepository {
  final SupabaseClient _supabase;

  TeamsRepository(this._supabase);

  // Get all teams for swimmer (teams swimmer is a member of, plus teams user created)
  Future<List<Team>> getTeamsForSwimmer(String swimmerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get teams user created
    final createdTeams = await _supabase
        .from('teams')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    // Get teams swimmer is a member of
    final memberTeams = await _supabase
        .from('team_members')
        .select('team_id')
        .eq('swimmer_id', swimmerId)
        .eq('status', 'active');

    final memberTeamIds = (memberTeams as List)
        .map((e) => e['team_id'] as String)
        .toSet();

    // Get team details for member teams
    List<dynamic> allTeams = List.from(createdTeams as List);
    if (memberTeamIds.isNotEmpty) {
      // Query each team individually (workaround for missing inFilter)
      for (final teamId in memberTeamIds) {
        try {
          final team = await _supabase
              .from('teams')
              .select()
              .eq('id', teamId)
              .single();
          allTeams.add(team);
                } catch (e) {
          // Team not found, skip
        }
      }
    }

    // Remove duplicates and map to Team objects
    final uniqueTeams = <String, Map<String, dynamic>>{};
    for (var team in allTeams) {
      uniqueTeams[team['id'] as String] = team as Map<String, dynamic>;
    }

    return uniqueTeams.values.map((e) => Team.fromJson(e)).toList();
  }

  // Get active teams for swimmer
  Future<List<Team>> getActiveTeamsForSwimmer(String swimmerId) async {
    final teams = await getTeamsForSwimmer(swimmerId);
    return teams.where((t) => t.isActive).toList();
  }

  // Legacy method for backward compatibility (gets all teams user created)
  Future<List<Team>> getTeams() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final createdTeams = await _supabase
        .from('teams')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    return (createdTeams as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Get active teams for current user
  Future<List<Team>> getActiveTeams() async {
    final teams = await getTeams();
    return teams.where((t) => t.isActive).toList();
  }

  // Get team by ID
  Future<Team?> getTeamById(String teamId) async {
    final data = await _supabase
        .from('teams')
        .select()
        .eq('id', teamId)
        .single();
    return Team.fromJson(data);
  }

  // Create team
  Future<Team> createTeam({
    required String name,
    String? location,
    required TeamType teamType,
    String? level,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase.from('teams').insert({
      'name': name,
      'location': location,
      'team_type': teamType.value,
      'level': level,
      'created_by': user.id,
      'is_active': true,
    }).select().single();

    return Team.fromJson(data);
  }

  // Update team
  Future<void> updateTeam(Team team) async {
    await _supabase.from('teams').update({
      'name': team.name,
      'location': team.location,
      'team_type': team.teamType.value,
      'level': team.level,
      'is_active': team.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', team.id);
  }

  // Delete team
  Future<void> deleteTeam(String teamId) async {
    await _supabase.from('teams').delete().eq('id', teamId);
  }

  // Add swimmer to team
  Future<void> addSwimmerToTeam(String swimmerId, String teamId) async {
    // Check if swimmer is already a member of this team
    final existing = await _supabase
        .from('team_members')
        .select('id, status')
        .eq('swimmer_id', swimmerId)
        .eq('team_id', teamId)
        .maybeSingle();

    if (existing != null) {
      // If already a member and active, do nothing
      if (existing['status'] == 'active') {
        return; // Already a member, no error
      }
      // If past member, reactivate them
      await _supabase
          .from('team_members')
          .update({
            'status': 'active',
            'joined_date': DateTime.now().toIso8601String().split('T')[0],
            'left_date': null,
          })
          .eq('id', existing['id']);
      return;
    }

    // New membership
    await _supabase.from('team_members').insert({
      'swimmer_id': swimmerId,
      'team_id': teamId,
      'status': 'active',
      'joined_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  // Remove swimmer from team
  Future<void> removeSwimmerFromTeam(String swimmerId, String teamId) async {
    await _supabase
        .from('team_members')
        .update({
          'status': 'past',
          'left_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('swimmer_id', swimmerId)
        .eq('team_id', teamId);
  }

  // Legacy methods for backward compatibility
  Future<void> joinTeam(String teamId) async {
    // This method is deprecated - use addSwimmerToTeam instead
    throw UnimplementedError('Use addSwimmerToTeam with swimmerId instead');
  }

  Future<void> leaveTeam(String teamId) async {
    // This method is deprecated - use removeSwimmerFromTeam instead
    throw UnimplementedError('Use removeSwimmerFromTeam with swimmerId instead');
  }

  // Get team members (swimmers in the team)
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final data = await _supabase
        .from('team_members')
        .select('''
          *,
          swimmers:swimmer_id (
            id,
            full_name,
            avatar_url,
            birth_date,
            gender
          )
        ''')
        .eq('team_id', teamId)
        .eq('status', 'active')
        .order('joined_date', ascending: false);
    
    return (data as List).map((e) => TeamMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Search teams by name (for regular teams from database)
  // Returns teams that are regular type (imported from SwimCloud)
  Future<List<Team>> searchTeams(String query, {int limit = 20}) async {
    debugPrint('[TeamsRepository] searchTeams called with query: "$query"');
    
    if (query.trim().isEmpty) {
      debugPrint('[TeamsRepository] Query is empty, returning empty list');
      return [];
    }

    final trimmedQuery = query.trim();
    debugPrint('[TeamsRepository] Searching for teams with:');
    debugPrint('  - team_type: regular');
    debugPrint('  - is_active: true');
    debugPrint('  - name: ILIKE "%$trimmedQuery%"');
    debugPrint('  - limit: $limit');
    debugPrint('  Note: Searching all regular teams');

    try {
      // First, let's check if there are any teams at all
      final allTeamsCheck = await _supabase
          .from('teams')
          .select('id, name, team_type, is_active')
          .limit(5);
      debugPrint('[TeamsRepository] Total teams in database (sample): ${(allTeamsCheck as List).length}');
      if ((allTeamsCheck as List).isNotEmpty) {
        debugPrint('[TeamsRepository] Sample teams:');
        for (var team in (allTeamsCheck as List).take(3)) {
          debugPrint('  - ${team['name']} (type: ${team['team_type']}, active: ${team['is_active']})');
        }
      }

      // Check regular teams
      final regularTeams = await _supabase
          .from('teams')
          .select('id, name, team_type, is_active')
          .eq('team_type', 'regular')
          .eq('is_active', true)
          .limit(5);
      debugPrint('[TeamsRepository] Regular active teams: ${(regularTeams as List).length}');
      if ((regularTeams as List).isNotEmpty) {
        debugPrint('[TeamsRepository] Sample regular teams:');
        for (var team in (regularTeams as List).take(3)) {
          debugPrint('  - ${team['name']}');
        }
      }

      // Now do the actual search
      // Search for regular teams (imported from SwimCloud)
      final data = await _supabase
          .from('teams')
          .select()
          .eq('team_type', 'regular')
          .ilike('name', '%$trimmedQuery%')
          .eq('is_active', true)
          .limit(limit)
          .order('name', ascending: true);

      debugPrint('[TeamsRepository] Search query executed');
      debugPrint('[TeamsRepository] Results count: ${(data as List).length}');
      
      if ((data as List).isNotEmpty) {
        debugPrint('[TeamsRepository] Found teams:');
        for (var team in data as List) {
          debugPrint('  - ${team['name']} (id: ${team['id']}, location: ${team['location']})');
        }
      } else {
        debugPrint('[TeamsRepository] No teams found matching criteria: "$trimmedQuery"');
        
        // Try searching for just the first word to see if partial matching would help
        final words = trimmedQuery.split(' ').where((w) => w.isNotEmpty).toList();
        if (words.length > 1) {
          debugPrint('[TeamsRepository] Query has multiple words, trying first word only: "${words[0]}"');
          final firstWordSearch = await _supabase
              .from('teams')
              .select('id, name, team_type, is_active')
              .eq('team_type', 'regular')
              .eq('is_active', true)
              .ilike('name', '%${words[0]}%')
              .limit(5);
          debugPrint('[TeamsRepository] First word search found: ${(firstWordSearch as List).length}');
          if ((firstWordSearch as List).isNotEmpty) {
            debugPrint('[TeamsRepository] Teams matching first word "${words[0]}":');
            for (var team in firstWordSearch as List) {
              debugPrint('  - ${team['name']}');
            }
          }
        }
        
        // Try a simpler search to debug
        final simpleSearch = await _supabase
            .from('teams')
            .select('id, name, team_type, is_active')
            .ilike('name', '%$trimmedQuery%')
            .limit(5);
        debugPrint('[TeamsRepository] Simple search (no filters) found: ${(simpleSearch as List).length}');
        if ((simpleSearch as List).isNotEmpty) {
          debugPrint('[TeamsRepository] Simple search results:');
          for (var team in simpleSearch as List) {
            debugPrint('  - ${team['name']} (type: ${team['team_type']}, active: ${team['is_active']})');
          }
        }
      }

      final results = (data as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
      debugPrint('[TeamsRepository] Returning ${results.length} teams');
      return results;
    } catch (e, stackTrace) {
      debugPrint('[TeamsRepository] ERROR in searchTeams: $e');
      debugPrint('[TeamsRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

}

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(Supabase.instance.client);
});

final teamsListProvider = FutureProvider<List<Team>>((ref) async {
  final repository = ref.watch(teamsRepositoryProvider);
  return repository.getTeams();
});

// Provider that gets teams for the current swimmer (created + joined)
final teamsForSwimmerProvider = FutureProvider<List<Team>>((ref) async {
  final repository = ref.watch(teamsRepositoryProvider);
  final swimmersRepo = ref.watch(swimmersRepositoryProvider);
  
  // Get current swimmer ID
  SwimmerProfile? swimmer;
  
  // Try primary first
  swimmer = await swimmersRepo.getPrimarySwimmer();
  
  // If no primary, try selected swimmer
  if (swimmer == null) {
    final selectedId = await swimmersRepo.getSelectedSwimmerId();
    if (selectedId != null) {
      swimmer = await swimmersRepo.getSwimmerById(selectedId);
    }
  }
  
  // If still no swimmer, get first available
  if (swimmer == null) {
    final allSwimmers = await swimmersRepo.getSwimmers();
    if (allSwimmers.isNotEmpty) {
      swimmer = allSwimmers.first;
    }
  }
  
  if (swimmer == null) {
    // No swimmer profile yet, return empty list
    return [];
  }
  
  return repository.getTeamsForSwimmer(swimmer.id);
});

final activeTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final repository = ref.watch(teamsRepositoryProvider);
  return repository.getActiveTeams();
});

final teamProvider = FutureProvider.family<Team?, String>((ref, teamId) async {
  final repository = ref.watch(teamsRepositoryProvider);
  return repository.getTeamById(teamId);
});
