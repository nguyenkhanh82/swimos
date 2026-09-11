import 'package:swim_tracker_mobile/src/features/training/data/swim_times_sync_service.dart';

/// No-op implementation for tests that pump the full app without Supabase.
class FakeSwimTimesSyncService implements SwimTimesSyncService {
  @override
  Future<bool> fetchSwimmerTimes(String swimmerId, {bool forceRefresh = false}) async => true;

  @override
  Future<bool> fetchCurrentSwimmerTimes({bool forceRefresh = false}) async => true;

  @override
  Future<void> fetchAllSwimmerTimes({bool forceRefresh = false}) async {}
}
