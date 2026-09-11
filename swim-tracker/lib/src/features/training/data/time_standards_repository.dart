import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/time_standard.dart';

class TimeStandardsRepository {
  final SupabaseClient _supabase;

  TimeStandardsRepository(this._supabase);

  /// Motivational standard levels only (B–AAAA). Excludes national tiers for correct card/bar display.
  static const List<String> motivationalLevels = ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA'];

  /// National-tier standard levels for badge display (Sectional, Futures, Junior National, National).
  static const List<String> nationalTierLevels = [
    'Sectional', 'Futures', 'Junior National Bonus', 'Junior National', 'National',
  ];

  Future<List<TimeStandard>> getStandards({
    String? gender,
    String? ageGroup,
    String? course,
    String? event,
    StandardLevel? standardLevel,
    bool motivationalOnly = true,
  }) async {
    var query = _supabase.from('time_standards').select();

    if (gender != null) {
      query = query.eq('gender', gender);
    }
    if (ageGroup != null) {
      query = query.eq('age_group', ageGroup);
    }
    if (course != null) {
      query = query.eq('course', course);
    }
    if (event != null) {
      query = query.eq('event', event);
    }
    if (standardLevel != null) {
      query = query.eq('standard_level', standardLevel.value);
    }
    if (motivationalOnly) {
      query = query.inFilter('standard_level', motivationalLevels);
    }

    // Order by event then time_seconds ascending so per-event order is correct (AAAA first, then ... B).
    final data = await query.order('event').order('time_seconds', ascending: true);
    return (data as List).map((e) => TimeStandard.fromJson(e)).toList();
  }

  Future<List<TimeStandard>> getStandardsForEvent({
    required String gender,
    required String ageGroup,
    required String course,
    required String event,
    bool motivationalOnly = true,
  }) async {
    var query = _supabase
        .from('time_standards')
        .select()
        .eq('gender', gender)
        .eq('age_group', ageGroup)
        .eq('course', course)
        .eq('event', event);

    if (motivationalOnly) {
      query = query.inFilter('standard_level', motivationalLevels);
    }

    final data = await query.order('time_seconds', ascending: false); // Slowest to fastest
    return (data as List).map((e) => TimeStandard.fromJson(e)).toList();
  }

  Future<TimeStandard?> getStandard({
    required String gender,
    required String ageGroup,
    required String course,
    required String event,
    required StandardLevel standardLevel,
  }) async {
    final data = await _supabase
        .from('time_standards')
        .select()
        .eq('gender', gender)
        .eq('age_group', ageGroup)
        .eq('course', course)
        .eq('event', event)
        .eq('standard_level', standardLevel.value)
        .maybeSingle();

    if (data == null) return null;
    return TimeStandard.fromJson(data);
  }

  /// Get all standards for a specific stroke, distance, and course.
  /// [motivationalOnly] when true (default) returns only B–AAAA for correct card/bar display.
  Future<List<TimeStandard>> getStandardsByStrokeDistance({
    required String gender,
    required String ageGroup,
    required String stroke,
    required int distance,
    required String course,
    bool motivationalOnly = true,
  }) async {
    var query = _supabase
        .from('time_standards')
        .select()
        .eq('gender', gender)
        .eq('age_group', ageGroup)
        .eq('stroke', stroke)
        .eq('distance', distance)
        .eq('course', course);

    if (motivationalOnly) {
      query = query.inFilter('standard_level', motivationalLevels);
    }

    final data = await query.order('time_seconds', ascending: false);
    return (data as List).map((e) => TimeStandard.fromJson(e)).toList();
  }

  /// Fetches national-tier cuts (Sectional, Futures, Junior National, National) for an event.
  /// [use18AndUnder] true for age &lt; 19 (use "18 & Under" + "All Age" for Sectional).
  /// Returns one cut per tier, ordered slowest (Sectional) to fastest (National).
  Future<List<NationalTierStandard>> getNationalTierStandardsForEvent({
    required String gender,
    required String course,
    required String event,
    required bool use18AndUnder,
  }) async {
    final ageGroups = use18AndUnder ? ['All Age', '18 & Under'] : ['All Age', '19 & Over'];
    final data = await _supabase
        .from('time_standards')
        .select('id, standard_level, time_seconds, age_group')
        .eq('gender', gender)
        .eq('course', course)
        .eq('event', event)
        .inFilter('standard_level', nationalTierLevels)
        .inFilter('age_group', ageGroups);

    final list = (data as List).cast<Map<String, dynamic>>();
    final byLevel = <String, NationalTierStandard>{};
    for (final row in list) {
      final level = row['standard_level'] as String?;
      final ageGroup = row['age_group'] as String?;
      if (level == null) continue;
      final useRow = level == 'Sectional'
          ? ageGroup == 'All Age'
          : (use18AndUnder ? ageGroup == '18 & Under' : ageGroup == '19 & Over');
      if (!useRow || byLevel.containsKey(level)) continue;
      final timeSeconds = (row['time_seconds'] as num?)?.toDouble();
      if (timeSeconds == null) continue;
      byLevel[level] = NationalTierStandard(
        id: row['id']?.toString() ?? '',
        name: level,
        timeSeconds: timeSeconds,
      );
    }
    final order = ['Sectional', 'Futures', 'Junior National Bonus', 'Junior National', 'National'];
    return order.where((l) => byLevel.containsKey(l)).map((l) => byLevel[l]!).toList();
  }

  /// Fetches national-tier cuts for all events (gender, course). Returns map eventName -> list of national tiers.
  /// Use when building records so Khloe 50 Free can show "Sectional" when her time meets the cut.
  Future<Map<String, List<NationalTierStandard>>> getNationalTierStandardsByCourse({
    required String gender,
    required String course,
    required bool use18AndUnder,
  }) async {
    final ageGroups = use18AndUnder ? ['All Age', '18 & Under'] : ['All Age', '19 & Over'];
    final data = await _supabase
        .from('time_standards')
        .select('id, standard_level, time_seconds, age_group, event')
        .eq('gender', gender)
        .eq('course', course)
        .inFilter('standard_level', nationalTierLevels)
        .inFilter('age_group', ageGroups);

    final list = (data as List).cast<Map<String, dynamic>>();
    final byEvent = <String, Map<String, NationalTierStandard>>{};
    for (final row in list) {
      final event = row['event'] as String?;
      final level = row['standard_level'] as String?;
      final ageGroup = row['age_group'] as String?;
      if (event == null || level == null) continue;
      final useRow = level == 'Sectional'
          ? ageGroup == 'All Age'
          : (use18AndUnder ? ageGroup == '18 & Under' : ageGroup == '19 & Over');
      if (!useRow) continue;
      byEvent.putIfAbsent(event, () => {});
      if (byEvent[event]!.containsKey(level)) continue;
      final timeSeconds = (row['time_seconds'] as num?)?.toDouble();
      if (timeSeconds == null) continue;
      byEvent[event]![level] = NationalTierStandard(
        id: row['id']?.toString() ?? '',
        name: level,
        timeSeconds: timeSeconds,
      );
    }
    final order = ['Sectional', 'Futures', 'Junior National Bonus', 'Junior National', 'National'];
    final result = <String, List<NationalTierStandard>>{};
    for (final entry in byEvent.entries) {
      result[entry.key] = order.where((l) => entry.value.containsKey(l)).map((l) => entry.value[l]!).toList();
    }
    return result;
  }
}

final timeStandardsRepositoryProvider = Provider<TimeStandardsRepository>((ref) {
  return TimeStandardsRepository(Supabase.instance.client);
});
