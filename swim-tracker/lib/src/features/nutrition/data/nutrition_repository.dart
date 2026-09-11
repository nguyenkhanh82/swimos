import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/nutrition_log.dart';
import '../domain/daily_macro_target.dart';
import '../../training/data/swimmers_repository.dart';

class NutritionRepository {
  final SupabaseClient _supabase;

  NutritionRepository(this._supabase);

  Future<DailyMacroTarget?> getNutritionTarget(String swimmerId) async {
    final response = await _supabase
        .from('nutrition_targets')
        .select()
        .eq('swimmer_id', swimmerId)
        .maybeSingle();

    if (response == null) return null;
    return DailyMacroTarget.fromJson(response);
  }

  Future<DailyMacroTarget> upsertNutritionTarget({
    required String swimmerId,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int sugar,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final payload = {
      'user_id': userId,
      'swimmer_id': swimmerId,
      'calories_target': calories,
      'protein_target': protein,
      'carbs_target': carbs,
      'fat_target': fat,
      'sugar_target': sugar,
    };

    final response = await _supabase
        .from('nutrition_targets')
        .upsert(payload, onConflict: 'swimmer_id')
        .select()
        .single();

    return DailyMacroTarget.fromJson(response);
  }

  Future<List<NutritionLog>> getLogsForDateRange(
      String swimmerId, DateTime start, DateTime end) async {
    final response = await _supabase
        .from('nutrition_logs')
        .select()
        .eq('swimmer_id', swimmerId)
        .gte('log_date', start.toIso8601String().split('T')[0])
        .lte('log_date', end.toIso8601String().split('T')[0])
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => NutritionLog.fromJson(json))
        .toList();
  }

  Future<String?> uploadFoodImage(
      String swimmerId, Uint8List imageBytes) async {
    final userId = _supabase.auth.currentUser!.id;
    final ext = 'jpg';
    final path =
        '$userId/$swimmerId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage.from('food_images').uploadBinary(
          path,
          imageBytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final urlResponse =
        _supabase.storage.from('food_images').getPublicUrl(path);
    return urlResponse;
  }

  Future<Map<String, dynamic>> analyzeNutrition({
    String? description,
    String? base64Image,
  }) async {
    final response = await _supabase.functions.invoke(
      'analyze-nutrition',
      body: {
        if (description != null) 'description': description,
        if (base64Image != null) 'image_base64': base64Image,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  Future<NutritionLog> addNutritionLog({
    required String swimmerId,
    required DateTime logDate,
    required String mealType,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int sugar,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final payload = {
      'user_id': userId,
      'swimmer_id': swimmerId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'meal_type': mealType,
      'description': description,
      'image_url': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
    };

    final response = await _supabase
        .from('nutrition_logs')
        .insert(payload)
        .select()
        .single();

    return NutritionLog.fromJson(response);
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(Supabase.instance.client);
});

final nutritionTargetProvider = FutureProvider<DailyMacroTarget?>((ref) async {
  final swimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (swimmerId == null) return null;
  return ref.read(nutritionRepositoryProvider).getNutritionTarget(swimmerId);
});

// A provider that fetches the last 7 days of logs + today.
// Can be adjusted to fetch ALL-TIME or specific dates using parameters.
class NutritionDateRange {
  final DateTime start;
  final DateTime end;
  NutritionDateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionDateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

final nutritionLogsProvider =
    FutureProvider.family<List<NutritionLog>, NutritionDateRange>(
        (ref, range) async {
  final swimmerId = await ref.watch(selectedSwimmerIdProvider.future);
  if (swimmerId == null) return [];
  return ref
      .read(nutritionRepositoryProvider)
      .getLogsForDateRange(swimmerId, range.start, range.end);
});
