import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/practice.dart';
import '../domain/training_session.dart';
import '../domain/training_set_split.dart';
import '../domain/training_set_split_row.dart';
import 'swimmers_repository.dart';

class TrainingRepository {
  final SupabaseClient _supabase;

  TrainingRepository(this._supabase);

  // Get all training sessions for swimmer
  Future<List<TrainingSession>> getTrainingSessions({
    required String swimmerId,
    String? teamId,
    String? stroke,
    int? distance,
    DateTime? startDate,
    DateTime? endDate,
    String? goalId,
  }) async {
    var query =
        _supabase.from('training_sets').select().eq('swimmer_id', swimmerId);

    if (teamId != null) {
      query = query.eq('team_id', teamId);
    }

    if (stroke != null) {
      query = query.eq('stroke', stroke);
    }

    if (goalId != null) {
      query = query.eq('goal_id', goalId);
    }

    if (distance != null) {
      query = query.eq('distance_per_rep', distance);
    }

    if (startDate != null) {
      query =
          query.gte('training_date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query =
          query.lte('training_date', endDate.toIso8601String().split('T')[0]);
    }

    final data = await query.order('training_date', ascending: false);
    return (data as List).map((e) => TrainingSession.fromJson(e)).toList();
  }

  // Get training session by ID
  Future<TrainingSession?> getTrainingSessionById(String id) async {
    final data =
        await _supabase.from('training_sets').select().eq('id', id).single();
    return TrainingSession.fromJson(data);
  }

  // Get all practices for swimmer
  Future<List<Practice>> getPractices({
    required String swimmerId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? goalId,
  }) async {
    var query = _supabase
        .from('practices')
        .select('*, training_sets(*)')
        .eq('swimmer_id', swimmerId);

    if (teamId != null) {
      query = query.eq('team_id', teamId);
    }
    if (goalId != null) {
      query = query.eq('goal_id', goalId);
    }
    if (startDate != null) {
      query =
          query.gte('practice_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query =
          query.lte('practice_date', endDate.toIso8601String().split('T')[0]);
    }

    // Apply sorting to the parent and the referenced table
    final data = await query
        .order('practice_date', ascending: false)
        .order('created_at', ascending: true, referencedTable: 'training_sets');

    return (data as List).map((e) => Practice.fromJson(e)).toList();
  }

  Future<Practice?> getPracticeById(String id) async {
    final data = await _supabase
        .from('practices')
        .select('*, training_sets(*)')
        .eq('id', id)
        .order('created_at', ascending: true, referencedTable: 'training_sets')
        .single();
    return Practice.fromJson(data);
  }

  Future<void> deletePractice(String id) async {
    await _supabase.from('practices').delete().eq('id', id);
  }

  /// Create a practice (session) that can hold multiple sets.
  Future<Practice> createPractice({
    required String swimmerId,
    required DateTime practiceDate,
    String? name,
    String? teamId,
    String? goalId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be signed in to create practice');
    }
    final data = await _supabase
        .from('practices')
        .insert({
          'user_id': userId,
          'swimmer_id': swimmerId,
          'practice_date': practiceDate.toIso8601String().split('T')[0],
          'name': name,
          'team_id': teamId,
          'goal_id': goalId,
        })
        .select()
        .single();
    return Practice.fromJson(data);
  }

  // Create training session (set); optionally link to a practice.
  Future<TrainingSession> createTrainingSession({
    required String swimmerId,
    required DateTime trainingDate,
    required String setDescription,
    required String stroke,
    required int distancePerRep,
    required int numberOfReps,
    required int totalDistance,
    int? restSeconds,
    String? poolType,
    String? intensity,
    String? notes,
    String? teamId,
    int? rpe,
    int? dayOfWeek,
    String? practiceId,
    String? goalId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be signed in to log practice');
    }
    final payload = {
      'user_id': userId,
      'swimmer_id': swimmerId,
      'training_date': trainingDate.toIso8601String().split('T')[0],
      'set_description': setDescription,
      'stroke': stroke,
      'distance_per_rep': distancePerRep,
      'number_of_reps': numberOfReps,
      'total_distance': totalDistance,
      'rest_seconds': restSeconds,
      'pool_type': poolType ?? 'SCY',
      'intensity': intensity ?? 'moderate',
      'notes': notes,
      'team_id': teamId,
      'rpe': rpe,
      'day_of_week': dayOfWeek,
    };
    if (practiceId != null) {
      payload['practice_id'] = practiceId;
    }
    if (goalId != null) {
      payload['goal_id'] = goalId;
    }
    final data =
        await _supabase.from('training_sets').insert(payload).select().single();
    return TrainingSession.fromJson(data);
  }

  /// Insert split rows for a set. Used when user logs times (stopwatch or manual).
  Future<void> createSplitsForSet({
    required String trainingSetId,
    required String swimmerId,
    required List<TrainingSetSplitRow> splits,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be signed in to log splits');
    }
    if (splits.isEmpty) return;
    final rows = splits.map((s) {
      final row = <String, dynamic>{
        'training_set_id': trainingSetId,
        'user_id': userId,
        'swimmer_id': swimmerId,
        'rep_number': s.repNumber,
        'time_seconds': s.timeSeconds,
      };
      if (s.segmentIndex != null) row['segment_index'] = s.segmentIndex;
      if (s.strokeLeg != null) row['stroke_leg'] = s.strokeLeg;
      if (s.distancePerSegment != null) {
        row['distance_per_segment'] = s.distancePerSegment;
      }
      return row;
    }).toList();
    await _supabase.from('training_set_splits').insert(rows);
  }

  /// Search sets for current swimmer (description, stroke, date range). For "log again".
  Future<List<TrainingSession>> searchSets({
    required String swimmerId,
    String? query,
    String? stroke,
    DateTime? from,
    DateTime? to,
    int limit = 30,
  }) async {
    var q =
        _supabase.from('training_sets').select().eq('swimmer_id', swimmerId);
    if (query != null && query.trim().isNotEmpty) {
      q = q.ilike('set_description', '%${query.trim()}%');
    }
    if (stroke != null) {
      q = q.eq('stroke', stroke);
    }
    if (from != null) {
      q = q.gte('training_date', from.toIso8601String().split('T')[0]);
    }
    if (to != null) {
      q = q.lte('training_date', to.toIso8601String().split('T')[0]);
    }
    final data = await q.order('training_date', ascending: false).limit(100);
    final unique = <String, TrainingSession>{};
    for (final json in data as List) {
      final s = TrainingSession.fromJson(json);
      final key =
          '${s.setDescription.trim().toLowerCase()}|${s.stroke.trim().toLowerCase()}|${s.distancePerRep}|${s.numberOfReps}';
      if (!unique.containsKey(key)) {
        unique[key] = s;
        if (unique.length >= limit) break;
      }
    }
    return unique.values.toList();
  }

  /// Recent sets for selected swimmer (e.g. last 15). For "previous practice" list.
  Future<List<TrainingSession>> getRecentSetsForSwimmer({
    required String swimmerId,
    int limit = 15,
  }) async {
    final data = await _supabase
        .from('training_sets')
        .select()
        .eq('swimmer_id', swimmerId)
        .order('training_date', ascending: false)
        .limit(100);
    final unique = <String, TrainingSession>{};
    for (final json in data as List) {
      final s = TrainingSession.fromJson(json);
      final key =
          '${s.setDescription.trim().toLowerCase()}|${s.stroke.trim().toLowerCase()}|${s.distancePerRep}|${s.numberOfReps}';
      if (!unique.containsKey(key)) {
        unique[key] = s;
        if (unique.length >= limit) break;
      }
    }
    return unique.values.toList();
  }

  /// Get all sessions matching a set "signature" (same description, stroke, distance, reps) for progress chart.
  Future<List<TrainingSession>> getSessionsForSetSignature({
    required String swimmerId,
    required String setDescription,
    required String stroke,
    required int distancePerRep,
    required int numberOfReps,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _supabase
        .from('training_sets')
        .select()
        .eq('swimmer_id', swimmerId)
        .ilike('set_description', setDescription)
        .ilike('stroke', stroke)
        .eq('distance_per_rep', distancePerRep)
        .eq('number_of_reps', numberOfReps)
        .gte('training_date', from.toIso8601String().split('T')[0])
        .lte('training_date', to.toIso8601String().split('T')[0])
        .order('training_date', ascending: true);
    return (data as List).map((e) => TrainingSession.fromJson(e)).toList();
  }

  /// Get splits for a set (for history breakdown: IM by stroke, every 50/100).
  Future<List<TrainingSetSplit>> getSplitsForSet(String trainingSetId) async {
    final data = await _supabase
        .from('training_set_splits')
        .select(
            'id, rep_number, time_seconds, segment_index, stroke_leg, distance_per_segment')
        .eq('training_set_id', trainingSetId)
        .order('rep_number')
        .order('segment_index');
    return (data as List).map((e) => TrainingSetSplit.fromJson(e)).toList();
  }

  // Update training session
  Future<void> updateTrainingSession(TrainingSession session) async {
    await _supabase.from('training_sets').update({
      'training_date': session.trainingDate.toIso8601String().split('T')[0],
      'set_description': session.setDescription,
      'stroke': session.stroke,
      'distance_per_rep': session.distancePerRep,
      'number_of_reps': session.numberOfReps,
      'total_distance': session.totalDistance,
      'rest_seconds': session.restSeconds,
      'pool_type': session.poolType,
      'intensity': session.intensity,
      'notes': session.notes,
      'team_id': session.teamId,
      'goal_id': session.goalId,
      'rpe': session.rpe,
      'day_of_week': session.dayOfWeek,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', session.id);
  }

  // Delete training session
  Future<void> deleteTrainingSession(String id) async {
    await _supabase.from('training_sets').delete().eq('id', id);
  }

  // Delete all training sessions for a specific goal
  Future<void> deleteTrainingSessionsByGoalId(String goalId) async {
    // Both training_sets and practices are cascaded to training_goals,
    // but the user wants to delete all SETS & PRACTICES generated for this goal,
    // Note that the schema has `ON DELETE CASCADE` from goal to practices and from practice to training_sets.
    // However, if we just want to delete the particular practice logs for the goal, we can just delete from practices manually since it'll cascade down to the sets or we can just delete from training_sets manually.
    await _supabase.from('training_sets').delete().eq('goal_id', goalId);
    await _supabase.from('practices').delete().eq('goal_id', goalId);
  }
}

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  return TrainingRepository(Supabase.instance.client);
});

final trainingSessionsProvider =
    FutureProvider<List<TrainingSession>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getTrainingSessions(swimmerId: selectedSwimmerId);
});

final practicesProvider = FutureProvider<List<Practice>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];

  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getPractices(swimmerId: selectedSwimmerId);
});

/// Recent sets for the selected swimmer (for "previous practice" / "log again").
final recentSetsForSwimmerProvider =
    FutureProvider<List<TrainingSession>>((ref) async {
  final selectedSwimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (selectedSwimmerId == null) return [];
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getRecentSetsForSwimmer(
      swimmerId: selectedSwimmerId, limit: 15);
});
