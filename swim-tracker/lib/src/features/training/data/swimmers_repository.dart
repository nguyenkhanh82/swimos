import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/swimmer_profile.dart';

class SwimmersRepository {
  final SupabaseClient _supabase;
  static const String _selectedSwimmerKey = 'selected_swimmer_id';

  SwimmersRepository(this._supabase);

  // Get all swimmers for current user
  Future<List<SwimmerProfile>> getSwimmers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase
        .from('swimmers')
        .select()
        .eq('user_id', user.id)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => SwimmerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get swimmer by ID
  Future<SwimmerProfile?> getSwimmerById(String swimmerId) async {
    final data = await _supabase
        .from('swimmers')
        .select()
        .eq('id', swimmerId)
        .maybeSingle();

    if (data == null) return null;
    return SwimmerProfile.fromJson(data);
  }

  // Get primary swimmer
  Future<SwimmerProfile?> getPrimarySwimmer() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase
        .from('swimmers')
        .select()
        .eq('user_id', user.id)
        .eq('is_primary', true)
        .maybeSingle();

    if (data == null) return null;
    return SwimmerProfile.fromJson(data);
  }

  // Create swimmer profile
  Future<SwimmerProfile> createSwimmer({
    required String swimcloudId,
    String? swimcloudPersonId,
    String? fullName,
    DateTime? birthDate,
    String? gender,
    String? avatarUrl,
    String? notes,
    bool isPrimary = false,
    // New fields
    double? weightKg,
    double? heightCm,
    String? swimUsaId,
    String? allergies,
    String? unitPreference,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // If this is set as primary, unset other primary swimmers
    if (isPrimary) {
      await _supabase
          .from('swimmers')
          .update({'is_primary': false})
          .eq('user_id', user.id)
          .eq('is_primary', true);
    }

    final data = await _supabase.from('swimmers').insert({
      'user_id': user.id,
      'swimcloud_id': swimcloudId,
      'swimcloud_person_id': swimcloudPersonId,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'gender': gender,
      'avatar_url': avatarUrl,
      'is_primary': isPrimary,
      'notes': notes,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'swim_usa_id': swimUsaId,
      'allergies': allergies,
      'unit_preference': unitPreference ?? 'metric',
    }).select().single();

    return SwimmerProfile.fromJson(data);
  }

  // Update swimmer profile
  Future<SwimmerProfile> updateSwimmer(
    String swimmerId, {
    String? swimcloudId,
    String? swimcloudPersonId,
    String? fullName,
    DateTime? birthDate,
    String? gender,
    String? avatarUrl,
    bool? isPrimary,
    String? notes,
    // New fields
    double? weightKg,
    double? heightCm,
    String? swimUsaId,
    String? allergies,
    String? unitPreference,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    if (swimcloudId != null) updates['swimcloud_id'] = swimcloudId;
    if (swimcloudPersonId != null) updates['swimcloud_person_id'] = swimcloudPersonId;
    if (fullName != null) updates['full_name'] = fullName;
    if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String().split('T')[0];
    if (gender != null) updates['gender'] = gender;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (isPrimary != null) updates['is_primary'] = isPrimary;
    if (notes != null) updates['notes'] = notes;
    // New fields
    if (weightKg != null) updates['weight_kg'] = weightKg;
    if (heightCm != null) updates['height_cm'] = heightCm;
    if (swimUsaId != null) updates['swim_usa_id'] = swimUsaId;
    if (allergies != null) updates['allergies'] = allergies;
    if (unitPreference != null) updates['unit_preference'] = unitPreference;

    // If setting as primary, unset other primary swimmers
    if (isPrimary == true) {
      await _supabase
          .from('swimmers')
          .update({'is_primary': false})
          .eq('user_id', user.id)
          .eq('is_primary', true)
          .neq('id', swimmerId);
    }

    final data = await _supabase
        .from('swimmers')
        .update(updates)
        .eq('id', swimmerId)
        .eq('user_id', user.id) // Security: ensure user owns this swimmer
        .select()
        .single();

    return SwimmerProfile.fromJson(data);
  }

  // Delete swimmer profile
  Future<void> deleteSwimmer(String swimmerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('swimmers')
        .delete()
        .eq('id', swimmerId)
        .eq('user_id', user.id); // Security: ensure user owns this swimmer
  }

  // Get or set selected swimmer ID (persisted)
  Future<String?> getSelectedSwimmerId() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedSwimmerKey);
    
    if (selectedId != null) {
      // Verify swimmer still exists and user owns it
      final swimmer = await getSwimmerById(selectedId);
      if (swimmer != null) {
        return selectedId;
      } else {
        // Swimmer no longer exists, clear selection
        await prefs.remove(_selectedSwimmerKey);
      }
    }
    
    // If no selection, try to get primary swimmer
    final primary = await getPrimarySwimmer();
    if (primary != null) {
      await setSelectedSwimmerId(primary.id);
      return primary.id;
    }
    
    return null;
  }

  Future<void> setSelectedSwimmerId(String swimmerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSwimmerKey, swimmerId);
  }

  Future<void> clearSelectedSwimmer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedSwimmerKey);
  }
}

// Riverpod Providers
final swimmersRepositoryProvider = Provider<SwimmersRepository>((ref) {
  return SwimmersRepository(Supabase.instance.client);
});

final swimmersListProvider = FutureProvider<List<SwimmerProfile>>((ref) async {
  final repository = ref.watch(swimmersRepositoryProvider);
  return repository.getSwimmers();
});

final primarySwimmerProvider = FutureProvider<SwimmerProfile?>((ref) async {
  final repository = ref.watch(swimmersRepositoryProvider);
  return repository.getPrimarySwimmer();
});

// Selected swimmer provider (with persistence)
final selectedSwimmerIdProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(swimmersRepositoryProvider);
  return repository.getSelectedSwimmerId();
});

final selectedSwimmerProvider = FutureProvider<SwimmerProfile?>((ref) async {
  final selectedId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedId == null) return null;
  
  final repository = ref.watch(swimmersRepositoryProvider);
  return repository.getSwimmerById(selectedId);
});
