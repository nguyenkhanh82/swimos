import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/coach.dart';

class CoachesRepository {
  final SupabaseClient _supabase;

  CoachesRepository(this._supabase);

  // Get all coaches (created by user or associated with user's teams)
  Future<List<Coach>> getCoaches() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get coaches created by user
    final createdCoaches = await _supabase
        .from('coaches')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    // Get coaches from user's teams
    final memberTeams = await _supabase
        .from('team_members')
        .select('team_id')
        .eq('user_id', user.id)
        .eq('status', 'active');

    final teamIds = (memberTeams as List).map((e) => e['team_id'] as String).toList();

    List<dynamic> allCoaches = List.from(createdCoaches as List);
    if (teamIds.isNotEmpty) {
      // Query team coaches for each team (workaround for missing inFilter)
      final Set<String> coachIds = {};
      for (final teamId in teamIds) {
        try {
          final teamCoaches = await _supabase
              .from('team_coaches')
              .select('coach_id')
              .eq('team_id', teamId);
          final ids = (teamCoaches as List)
              .map((e) => e['coach_id'] as String)
              .toList();
          coachIds.addAll(ids);
        } catch (e) {
          // Skip if error
        }
      }

      if (coachIds.isNotEmpty) {
        // Query each coach individually (workaround for missing inFilter)
        for (final coachId in coachIds) {
          try {
            final coach = await _supabase
                .from('coaches')
                .select()
                .eq('id', coachId)
                .single();
            allCoaches.add(coach);
                    } catch (e) {
            // Coach not found, skip
          }
        }
      }
    }

    // Remove duplicates
    final uniqueCoaches = <String, Map<String, dynamic>>{};
    for (var coach in allCoaches) {
      uniqueCoaches[coach['id'] as String] = coach as Map<String, dynamic>;
    }

    return uniqueCoaches.values.map((e) => Coach.fromJson(e)).toList();
  }

  // Get coaches for a specific team
  Future<List<Coach>> getTeamCoaches(String teamId) async {
    final teamCoaches = await _supabase
        .from('team_coaches')
        .select('coach_id')
        .eq('team_id', teamId);

    final coachIds = (teamCoaches as List)
        .map((e) => e['coach_id'] as String)
        .toList();

    if (coachIds.isEmpty) return [];

    // Query each coach individually (workaround for missing inFilter)
    final List<Map<String, dynamic>> coaches = [];
    for (final coachId in coachIds) {
      try {
        final coach = await _supabase
            .from('coaches')
            .select()
            .eq('id', coachId)
            .single();
        coaches.add(coach);
            } catch (e) {
        // Coach not found, skip
      }
    }

    return coaches.map((e) => Coach.fromJson(e)).toList();
  }

  // Create coach
  Future<Coach> createCoach({
    required String name,
    String? email,
    String? phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase.from('coaches').insert({
      'name': name,
      'email': email,
      'phone': phone,
      'created_by': user.id,
    }).select().single();

    return Coach.fromJson(data);
  }

  // Update coach
  Future<void> updateCoach(Coach coach) async {
    await _supabase.from('coaches').update({
      'name': coach.name,
      'email': coach.email,
      'phone': coach.phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', coach.id);
  }

  // Delete coach
  Future<void> deleteCoach(String coachId) async {
    await _supabase.from('coaches').delete().eq('id', coachId);
  }

  // Add coach to team
  Future<void> addCoachToTeam(String teamId, String coachId, {bool isPrimary = false}) async {
    await _supabase.from('team_coaches').insert({
      'team_id': teamId,
      'coach_id': coachId,
      'is_primary': isPrimary,
    });
  }

  // Remove coach from team
  Future<void> removeCoachFromTeam(String teamId, String coachId) async {
    await _supabase
        .from('team_coaches')
        .delete()
        .eq('team_id', teamId)
        .eq('coach_id', coachId);
  }
}

final coachesRepositoryProvider = Provider<CoachesRepository>((ref) {
  return CoachesRepository(Supabase.instance.client);
});

final coachesListProvider = FutureProvider<List<Coach>>((ref) async {
  final repository = ref.watch(coachesRepositoryProvider);
  return repository.getCoaches();
});

final teamCoachesProvider = FutureProvider.family<List<Coach>, String>((ref, teamId) async {
  final repository = ref.watch(coachesRepositoryProvider);
  return repository.getTeamCoaches(teamId);
});
