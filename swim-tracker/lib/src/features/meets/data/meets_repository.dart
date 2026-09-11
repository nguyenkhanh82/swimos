import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/meet.dart';
import '../domain/meet_entry.dart';
import '../../training/data/swimmers_repository.dart';

class MeetsRepository {
  final SupabaseClient _supabase;

  MeetsRepository(this._supabase);

  Future<List<SwimMeet>> getMeets({required String swimmerId}) async {
    final data = await _supabase
        .from('swim_meets')
        .select()
        .eq('swimmer_id', swimmerId)
        .order('start_date', ascending: false);
    
    return (data as List).map((e) => SwimMeet.fromJson(e)).toList();
  }

  // Add Meet
  Future<SwimMeet> addMeet({
    required String swimmerId,
    required String name,
    required DateTime date,
    DateTime? endDate,
    String? location,
    String? poolType,
    String? swimcloudMeetId,
    String? meetType,
    String? organization,
    String? swimcloudUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = await _supabase.from('swim_meets').insert({
      'swimmer_id': swimmerId,
      'user_id': user.id,
      'meet_name': name,
      'start_date': date.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'location': location,
      'pool_type': poolType,
      'swimcloud_meet_id': swimcloudMeetId,
      'meet_type': meetType,
      'organization': organization,
      'swimcloud_url': swimcloudUrl,
    }).select().single();

    return SwimMeet.fromJson(data);
  }

  // Sync meet from SwimCloud times data
  // Creates or updates a meet based on meet_name from swim_times
  Future<SwimMeet?> syncMeetFromSwimCloudTimes({
    required String swimmerId,
    required String meetName,
    String? location,
    String? poolType,
    String? swimcloudMeetId,
    String? meetType,
    String? organization,
    String? swimcloudUrl,
    DateTime? meetDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Check if meet already exists by name and swimmer
    final existing = await _supabase
        .from('swim_meets')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('meet_name', meetName)
        .maybeSingle();

    if (existing != null) {
      // Update existing meet with SwimCloud data if provided
      final updateData = <String, dynamic>{};
      if (swimcloudMeetId != null) updateData['swimcloud_meet_id'] = swimcloudMeetId;
      if (meetType != null) updateData['meet_type'] = meetType;
      if (organization != null) updateData['organization'] = organization;
      if (swimcloudUrl != null) updateData['swimcloud_url'] = swimcloudUrl;
      if (location != null) updateData['location'] = location;
      if (poolType != null) updateData['pool_type'] = poolType;
      if (meetDate != null) updateData['start_date'] = meetDate.toIso8601String().split('T')[0];

      if (updateData.isNotEmpty) {
        final updated = await _supabase
            .from('swim_meets')
            .update(updateData)
            .eq('id', existing['id'])
            .select()
            .single();

        return SwimMeet.fromJson(updated);
      }

      return SwimMeet.fromJson(existing);
    }

    // Create new meet
    return await addMeet(
      swimmerId: swimmerId,
      name: meetName,
      date: meetDate ?? DateTime.now(),
      location: location,
      poolType: poolType,
      swimcloudMeetId: swimcloudMeetId,
      meetType: meetType,
      organization: organization,
      swimcloudUrl: swimcloudUrl,
    );
  }

  // Link existing meet with SwimCloud meet ID
  Future<void> linkMeetWithSwimCloud({
    required String meetId,
    required String swimcloudMeetId,
    String? swimcloudUrl,
  }) async {
    final updateData = <String, dynamic>{
      'swimcloud_meet_id': swimcloudMeetId,
    };
    if (swimcloudUrl != null) {
      updateData['swimcloud_url'] = swimcloudUrl;
    }

    await _supabase
        .from('swim_meets')
        .update(updateData)
        .eq('id', meetId);
  }

  Future<List<MeetEntry>> getMeetEntries(String meetId) async {
    final data = await _supabase
        .from('meet_entries')
        .select()
        .eq('meet_id', meetId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => MeetEntry.fromJson(e)).toList();
  }
  
  Future<void> addMeetEntry({
    required String swimmerId,
    required Map<String, dynamic> entryData,
  }) async {
    await _supabase.from('meet_entries').insert({
      ...entryData,
      'swimmer_id': swimmerId,
    });
  }
}

final meetsRepositoryProvider = Provider<MeetsRepository>((ref) {
  return MeetsRepository(Supabase.instance.client);
});

final meetsListProvider = FutureProvider<List<SwimMeet>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) {
    debugPrint('⚠️ No swimmer selected - cannot fetch meets');
    return [];
  }
  
  debugPrint('📅 Fetching meets for swimmer: $selectedSwimmerId');
  final repository = ref.watch(meetsRepositoryProvider);
  try {
    final meets = await repository.getMeets(swimmerId: selectedSwimmerId);
    debugPrint('✅ Found ${meets.length} meets');
    return meets;
  } catch (e) {
    debugPrint('❌ Error fetching meets: $e');
    rethrow;
  }
});

final meetEntriesProvider = FutureProvider.family<List<MeetEntry>, String>((ref, meetId) async {
  return ref.read(meetsRepositoryProvider).getMeetEntries(meetId);
});
