import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'swimmers_repository.dart';

/// Service to automatically sync swim times from SwimCloud
class SwimTimesSyncService {
  final SupabaseClient _supabase;
  final SwimmersRepository _swimmersRepository;

  SwimTimesSyncService(this._supabase, this._swimmersRepository);

  /// Check if swimmer data needs to be refreshed (older than 24 hours)
  bool _needsRefresh(DateTime? lastFetchedAt) {
    if (lastFetchedAt == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastFetchedAt);
    return difference.inHours >= 24;
  }

  /// Fetch swim times for a swimmer by their swimcloud_id
  /// Only fetches if data is older than 24 hours or missing
  /// Set forceRefresh to true to bypass the 24-hour check
  /// Returns true if successful, false otherwise
  Future<bool> fetchSwimmerTimes(String swimmerId, {bool forceRefresh = false}) async {
    try {
      // Get swimmer profile to find swimcloud_id and last_fetched_at
      final swimmer = await _swimmersRepository.getSwimmerById(swimmerId);
      if (swimmer == null) {
        debugPrint('⚠️ Swimmer not found: $swimmerId');
        return false;
      }

      if (swimmer.swimcloudId.isEmpty) {
        debugPrint('⚠️ Swimmer has no swimcloud_id: $swimmerId');
        return false;
      }

      // Check if we need to refresh
      if (!forceRefresh && !_needsRefresh(swimmer.lastFetchedAt)) {
        final hoursSinceFetch = DateTime.now().difference(swimmer.lastFetchedAt!).inHours;
        debugPrint('ℹ️ Data is fresh (fetched ${hoursSinceFetch}h ago). Skipping fetch.');
        return true; // Data is fresh, no need to fetch
      }

      debugPrint('🔄 Fetching swim times for swimmer: ${swimmer.fullName} (SwimCloud ID: ${swimmer.swimcloudId})');

      // Call the edge function
      final response = await _supabase.functions.invoke(
        'fetch-swimmer-times-swimcloud',
        body: {
          'swimmer_id': int.parse(swimmer.swimcloudId),
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        final eventsFound = data?['events_found'] as int? ?? 0;
        final timesFound = data?['times_found'] as int? ?? 0;
        final swimmerFound = data?['swimmer_found'] as bool? ?? true;
        final insertError = data?['insert_error'] as String?;
        final message = data?['message'] as String?;
        if (message != null && message.isNotEmpty) {
          debugPrint('✅ $message');
        } else {
          debugPrint('✅ Fetched $timesFound times for $eventsFound events');
        }
        if (!swimmerFound) {
          debugPrint('⚠️ Swimmer not found in database (swimcloud_id). Ensure SwimCloud ID is set on the swimmer profile.');
        }
        if (insertError != null && insertError.isNotEmpty) {
          debugPrint('⚠️ Insert error: $insertError');
        }
        return true; // Request succeeded; times_found may be 0 if swimmer not found or inserts failed
      } else {
        final error = response.data?['error'] as String? ?? 'Unknown error';
        debugPrint('❌ Error fetching swim times: $error');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception fetching swim times: $e');
      return false;
    }
  }

  /// Fetch swim times for the currently selected swimmer
  /// Set forceRefresh to true to bypass the 24-hour check
  Future<bool> fetchCurrentSwimmerTimes({bool forceRefresh = false}) async {
    try {
      final selectedId = await _swimmersRepository.getSelectedSwimmerId();
      if (selectedId == null) {
        debugPrint('⚠️ No swimmer selected');
        return false;
      }
      return await fetchSwimmerTimes(selectedId, forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('❌ Exception fetching current swimmer times: $e');
      return false;
    }
  }

  /// Fetch swim times for all swimmers of the current user
  /// Only fetches if data is older than 24 hours
  /// Set forceRefresh to true to bypass the 24-hour check
  Future<void> fetchAllSwimmerTimes({bool forceRefresh = false}) async {
    try {
      final swimmers = await _swimmersRepository.getSwimmers();
      for (final swimmer in swimmers) {
        if (swimmer.swimcloudId.isNotEmpty) {
          await fetchSwimmerTimes(swimmer.id, forceRefresh: forceRefresh);
          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      debugPrint('❌ Exception fetching all swimmer times: $e');
    }
  }
}

final swimTimesSyncServiceProvider = Provider<SwimTimesSyncService>((ref) {
  final supabase = Supabase.instance.client;
  final swimmersRepo = ref.watch(swimmersRepositoryProvider);
  return SwimTimesSyncService(supabase, swimmersRepo);
});
