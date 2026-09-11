import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/swim_time.dart';
import '../../training/domain/stroke.dart';
import '../../training/data/swimmers_repository.dart';

class SwimTimesRepository {
  final SupabaseClient _supabase;

  SwimTimesRepository(this._supabase);

  // Get all swim times for a swimmer with optional filters
  Future<List<SwimTime>> getSwimTimes({
    required String swimmerId,
    Stroke? stroke,
    int? distance,
    String? course,
    DateTime? startDate,
    DateTime? endDate,
    String? meetName,
    bool? isPersonalBest,
  }) async {
    var query =
        _supabase.from('swim_times').select().eq('swimmer_id', swimmerId);

    if (stroke != null) {
      query = query.eq('stroke', stroke.value);
    }

    if (distance != null) {
      query = query.eq('distance', distance);
    }

    if (course != null) {
      query = query.eq('course', course);
    }

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    if (meetName != null) {
      query = query.eq('meet_name', meetName);
    }

    if (isPersonalBest != null) {
      query = query.eq('is_personal_best', isPersonalBest);
    }

    final data = await query.order('date', ascending: false);
    return (data as List).map((e) => SwimTime.fromJson(e)).toList();
  }

  // Get swim times for a specific event
  Future<List<SwimTime>> getSwimTimesForEvent({
    required String swimmerId,
    required Stroke stroke,
    required int distance,
    required String course,
  }) async {
    final data = await _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('stroke', stroke.value)
        .eq('distance', distance)
        .eq('course', course)
        .order('time_seconds', ascending: true);

    return (data as List).map((e) => SwimTime.fromJson(e)).toList();
  }

  // Get personal best for a specific event
  Future<SwimTime?> getPersonalBest({
    required String swimmerId,
    required Stroke stroke,
    required int distance,
    required String course,
  }) async {
    final data = await _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('stroke', stroke.value)
        .eq('distance', distance)
        .eq('course', course)
        .order('time_seconds', ascending: true)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return SwimTime.fromJson(data);
  }

  // Get all personal bests for a swimmer
  Future<List<SwimTime>> getPersonalBests({
    required String swimmerId,
    String? course,
  }) async {
    var query = _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('is_personal_best', true);

    if (course != null) {
      query = query.eq('course', course);
    }

    final data = await query.order('date', ascending: false);
    return (data as List).map((e) => SwimTime.fromJson(e)).toList();
  }

  // Get swim time by ID
  Future<SwimTime?> getSwimTimeById(String id) async {
    final data =
        await _supabase.from('swim_times').select().eq('id', id).maybeSingle();

    if (data == null) return null;
    return SwimTime.fromJson(data);
  }

  // Add a new swim time
  Future<SwimTime> addSwimTime({
    required String swimmerId,
    required Stroke stroke,
    required int distance,
    required double timeSeconds,
    required DateTime date,
    required String course,
    String? meetName,
    String? eventName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Generate event name if not provided
    final finalEventName = eventName ?? '$distance ${stroke.value}';

    final insertData = {
      'swimmer_id': swimmerId,
      'user_id': user.id,
      'stroke': stroke.value,
      'distance': distance,
      'time_seconds': timeSeconds,
      'date': date.toIso8601String().split('T')[0],
      'course': course,
      'meet_name': meetName,
      'event_name': finalEventName,
      'is_personal_best':
          false, // Will be updated by trigger or application logic
    };

    final data =
        await _supabase.from('swim_times').insert(insertData).select().single();

    final newTime = SwimTime.fromJson(data);

    // Check if this is a personal best and update accordingly
    await _updatePersonalBestStatus(
      swimmerId: swimmerId,
      stroke: stroke,
      distance: distance,
      course: course,
    );

    return newTime;
  }

  // Update swim time
  Future<void> updateSwimTime({
    required String id,
    Stroke? stroke,
    int? distance,
    double? timeSeconds,
    DateTime? date,
    String? course,
    String? meetName,
    String? eventName,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (stroke != null) updateData['stroke'] = stroke.value;
    if (distance != null) updateData['distance'] = distance;
    if (timeSeconds != null) updateData['time_seconds'] = timeSeconds;
    if (date != null) updateData['date'] = date.toIso8601String().split('T')[0];
    if (course != null) updateData['course'] = course;
    if (meetName != null) updateData['meet_name'] = meetName;
    if (eventName != null) updateData['event_name'] = eventName;

    await _supabase.from('swim_times').update(updateData).eq('id', id);

    // If time or event details changed, recalculate personal bests
    if (stroke != null ||
        distance != null ||
        course != null ||
        timeSeconds != null) {
      final swimTime = await getSwimTimeById(id);
      if (swimTime != null) {
        await _updatePersonalBestStatus(
          swimmerId: swimTime.swimmerId,
          stroke: swimTime.stroke,
          distance: swimTime.distance,
          course: swimTime.course,
        );
      }
    }
  }

  // Delete swim time
  Future<void> deleteSwimTime(String id) async {
    // Get swim time details before deleting for PB recalculation
    final swimTime = await getSwimTimeById(id);

    await _supabase.from('swim_times').delete().eq('id', id);

    // Recalculate personal bests for this event
    if (swimTime != null) {
      await _updatePersonalBestStatus(
        swimmerId: swimTime.swimmerId,
        stroke: swimTime.stroke,
        distance: swimTime.distance,
        course: swimTime.course,
      );
    }
  }

  // Internal method to update personal best status for an event
  Future<void> _updatePersonalBestStatus({
    required String swimmerId,
    required Stroke stroke,
    required int distance,
    required String course,
  }) async {
    // Get all times for this event
    final times = await getSwimTimesForEvent(
      swimmerId: swimmerId,
      stroke: stroke,
      distance: distance,
      course: course,
    );

    if (times.isEmpty) return;

    // First, clear all personal best flags for this event
    await _supabase
        .from('swim_times')
        .update({'is_personal_best': false})
        .eq('swimmer_id', swimmerId)
        .eq('stroke', stroke.value)
        .eq('distance', distance)
        .eq('course', course);

    // Set the fastest time as personal best
    final fastestTime = times.first;
    await _supabase
        .from('swim_times')
        .update({'is_personal_best': true}).eq('id', fastestTime.id);
  }

  // Get recent swim times (last N entries)
  Future<List<SwimTime>> getRecentSwimTimes({
    required String swimmerId,
    int limit = 10,
  }) async {
    final data = await _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', swimmerId)
        .order('date', ascending: false)
        .limit(limit);

    return (data as List).map((e) => SwimTime.fromJson(e)).toList();
  }

  // Get swim times by meet
  Future<List<SwimTime>> getSwimTimesByMeet({
    required String swimmerId,
    required String meetName,
  }) async {
    final data = await _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', swimmerId)
        .eq('meet_name', meetName)
        .order('date', ascending: false);

    return (data as List).map((e) => SwimTime.fromJson(e)).toList();
  }
}

// Provider for SwimTimesRepository
final swimTimesRepositoryProvider = Provider<SwimTimesRepository>((ref) {
  return SwimTimesRepository(Supabase.instance.client);
});

// Provider for all swim times for the selected swimmer
final swimTimesListProvider = FutureProvider<List<SwimTime>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) {
    return [];
  }

  final repository = ref.watch(swimTimesRepositoryProvider);
  return repository.getSwimTimes(swimmerId: selectedSwimmerId);
});

// Provider for recent swim times for the selected swimmer
final recentSwimTimesProvider = FutureProvider<List<SwimTime>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) {
    return [];
  }

  final repository = ref.watch(swimTimesRepositoryProvider);
  return repository.getRecentSwimTimes(swimmerId: selectedSwimmerId);
});

// Provider for personal bests for the selected swimmer
final personalBestsProvider = FutureProvider<List<SwimTime>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) {
    return [];
  }

  final repository = ref.watch(swimTimesRepositoryProvider);
  return repository.getPersonalBests(swimmerId: selectedSwimmerId);
});

// Family provider for swim times by event
final swimTimesByEventProvider =
    FutureProvider.family<List<SwimTime>, SwimTimeEventFilter>(
        (ref, filter) async {
  final repository = ref.watch(swimTimesRepositoryProvider);
  return repository.getSwimTimesForEvent(
    swimmerId: filter.swimmerId,
    stroke: filter.stroke,
    distance: filter.distance,
    course: filter.course,
  );
});

// Helper class for event filter
class SwimTimeEventFilter {
  final String swimmerId;
  final Stroke stroke;
  final int distance;
  final String course;

  const SwimTimeEventFilter({
    required this.swimmerId,
    required this.stroke,
    required this.distance,
    required this.course,
  });
}
