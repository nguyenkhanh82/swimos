import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/custom_tracked_event.dart';
import 'swimmers_repository.dart';

class CustomEventsRepository {
  final SupabaseClient _supabase;

  CustomEventsRepository(this._supabase);

  // Get all custom events for swimmer
  Future<List<CustomTrackedEvent>> getCustomEvents({
    required String swimmerId,
    String? teamId,
  }) async {
    var query = _supabase
        .from('custom_tracked_events')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('is_active', true);

    if (teamId != null) {
      query = query.or('team_id.is.null,team_id.eq.$teamId');
    } else {
      query = query.isFilter('team_id', null);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => CustomTrackedEvent.fromJson(e)).toList();
  }

  // Create custom event
  Future<CustomTrackedEvent> createCustomEvent({
    required String swimmerId,
    required String eventName,
    String? teamId,
    String? stroke,
    int? distance,
  }) async {
    final data = await _supabase.from('custom_tracked_events').insert({
      'swimmer_id': swimmerId,
      'team_id': teamId,
      'event_name': eventName,
      'stroke': stroke,
      'distance': distance,
      'is_active': true,
    }).select().single();

    return CustomTrackedEvent.fromJson(data);
  }

  // Update custom event
  Future<void> updateCustomEvent(CustomTrackedEvent event) async {
    await _supabase.from('custom_tracked_events').update({
      'event_name': event.eventName,
      'team_id': event.teamId,
      'stroke': event.stroke?.value,
      'distance': event.distance,
      'is_active': event.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', event.id);
  }

  // Delete custom event (soft delete by setting is_active to false)
  Future<void> deleteCustomEvent(String eventId) async {
    await _supabase.from('custom_tracked_events').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }
}

final customEventsRepositoryProvider = Provider<CustomEventsRepository>((ref) {
  return CustomEventsRepository(Supabase.instance.client);
});

final customEventsProvider = FutureProvider.family<List<CustomTrackedEvent>, String?>((ref, teamId) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];
  
  final repository = ref.watch(customEventsRepositoryProvider);
  return repository.getCustomEvents(swimmerId: selectedSwimmerId, teamId: teamId);
});
