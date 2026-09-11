import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }

  // Update default team
  Future<void> setDefaultTeam(String? teamId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Check if profile exists
    final existing = await getProfile();
    
    if (existing != null) {
      // Update existing profile
      await _supabase
          .from('profiles')
          .update({'default_team_id': teamId})
          .eq('user_id', user.id);
    } else {
      // Create profile with default team
      await _supabase.from('profiles').insert({
        'user_id': user.id,
        'default_team_id': teamId,
      });
    }
  }

  // Get default team ID
  Future<String?> getDefaultTeamId() async {
    final profile = await getProfile();
    if (profile == null) return null;
    final teamId = profile['default_team_id'];
    if (teamId is String) return teamId;
    return null;
  }

  // Update profile
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? teamName,
    String? coachName,
    DateTime? dateOfBirth,
    String? primaryStroke,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (teamName != null) updates['team_name'] = teamName;
    if (coachName != null) updates['coach_name'] = coachName;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
    if (primaryStroke != null) updates['primary_stroke'] = primaryStroke;

    if (updates.isEmpty) return;

    final existing = await getProfile();
    if (existing != null) {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('user_id', user.id);
    } else {
      updates['user_id'] = user.id;
      await _supabase.from('profiles').insert(updates);
    }
  }

  // Update user role (parent/swimmer)
  Future<void> updateRole(String role) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    if (role != 'parent' && role != 'swimmer') {
      throw Exception('Invalid role. Must be "parent" or "swimmer"');
    }

    final existing = await getProfile();
    if (existing != null) {
      await _supabase
          .from('profiles')
          .update({'role': role})
          .eq('user_id', user.id);
    } else {
      // Create profile with role if it doesn't exist
      await _supabase.from('profiles').insert({
        'user_id': user.id,
        'role': role,
      });
    }
  }

  // Get user role
  Future<String?> getRole() async {
    final profile = await getProfile();
    if (profile == null) return null;
    final role = profile['role'];
    if (role is String) return role;
    return null;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});

final defaultTeamIdProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getDefaultTeamId();
});
