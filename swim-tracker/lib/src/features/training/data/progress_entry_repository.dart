import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/progress_entry.dart';

class ProgressEntryRepository {
  final SupabaseClient _supabase;

  ProgressEntryRepository(this._supabase);

  Future<List<ProgressEntry>> getEntriesByGoalId(String goalId) async {
    final data = await _supabase
        .from('goal_progress_entries')
        .select()
        .eq('goal_id', goalId)
        .order('recorded_at', ascending: false);

    return (data as List).map((e) => ProgressEntry.fromJson(e)).toList();
  }

  Future<ProgressEntry> createEntry(ProgressEntry entry, {required String swimmerId}) async {
    final data = await _supabase.from('goal_progress_entries').insert({
      'goal_id': entry.goalId,
      'swimmer_id': swimmerId,
      'progress_value': entry.progressValue,
      'notes': entry.notes,
      'recorded_at': entry.recordedAt.toIso8601String(),
    }).select().single();

    return ProgressEntry.fromJson(data);
  }

  Future<void> updateEntry(ProgressEntry entry) async {
    await _supabase.from('goal_progress_entries').update({
      'progress_value': entry.progressValue,
      'notes': entry.notes,
      'recorded_at': entry.recordedAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', entry.id);
  }

  Future<void> deleteEntry(String entryId) async {
    await _supabase.from('goal_progress_entries').delete().eq('id', entryId);
  }

  Future<ProgressEntry?> getLatestEntry(String goalId) async {
    final data = await _supabase
        .from('goal_progress_entries')
        .select()
        .eq('goal_id', goalId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return ProgressEntry.fromJson(data);
  }
}

final progressEntryRepositoryProvider = Provider<ProgressEntryRepository>((ref) {
  return ProgressEntryRepository(Supabase.instance.client);
});

final progressEntriesProvider = FutureProvider.family<List<ProgressEntry>, String>((ref, goalId) async {
  final repository = ref.watch(progressEntryRepositoryProvider);
  return repository.getEntriesByGoalId(goalId);
});
