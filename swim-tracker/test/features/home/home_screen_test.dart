import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swim_tracker_mobile/src/app.dart';
import 'package:swim_tracker_mobile/src/features/authentication/data/auth_repository.dart';
import 'package:swim_tracker_mobile/src/features/meets/data/meets_repository.dart';
import 'package:swim_tracker_mobile/src/features/meets/domain/meet.dart';
import 'package:swim_tracker_mobile/src/features/profile/data/profile_repository.dart';
import 'package:swim_tracker_mobile/src/features/training/data/swim_times_sync_service.dart';
import '../../helpers/fake_swim_times_sync_service.dart';

// Mock Auth Repository
class MockAuthRepository extends Mock implements AuthRepository {
  final _authStateController = StreamController<AuthState>.broadcast();
  User? _currentUser;

  MockAuthRepository() {
    // Start as signed in
    const user = User(
      id: 'test-user-id',
      email: 'test@example.com',
      appMetadata: {},
      userMetadata: {'full_name': 'Test Swimmer'},
      aud: 'authenticated',
      createdAt: '2023-01-01T00:00:00.000000Z',
    );
     _currentUser = user;
    final session = Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: user,
    );
    
    // Emit signed in state immediately
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => _currentUser;
  
  @override
  Future<void> signOut() async {
     _currentUser = null;
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

void main() {
  testWidgets('Home Page Elements Verification', (tester) async {
    // 1. Setup Data
    final mockAuthRepo = MockAuthRepository();
    
    final List<SwimMeet> mockMeets = [
      SwimMeet(
        id: '1',
        userId: 'test-user-id',
        meetName: 'Summer Championship',
        startDate: DateTime.now().add(const Duration(days: 5)),
        location: 'City Pool',
      ),
       SwimMeet(
        id: '2',
        userId: 'test-user-id',
        meetName: 'Winter Qualifiers',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        location: 'Indoor Center',
      ),
    ];

    // 2. Pump App with Overrides
    // We override AuthRepo, meetsListProvider, and swimTimesSyncService (no Supabase in tests)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          profileProvider.overrideWith((ref) => Future.value({'full_name': 'Test Swimmer'})),
          meetsListProvider.overrideWith((ref) => Future.value(mockMeets)),
          swimTimesSyncServiceProvider.overrideWithValue(FakeSwimTimesSyncService()),
        ],
        child: const SwimTrackApp(),
      ),
    );
    
    // Wait for routing / async building
    await tester.pumpAndSettle();

    // 3. Verify Home Page Content
    
    // Check Header and Username
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Test Swimmer'), findsOneWidget); 
    
    // Check Stats Row (Streak)
    expect(find.text('Training Streak'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Check Chart Section
    expect(find.text('Weekly Training Volume'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);

    // Check Goals section (content may be "No active goals" or goal cards depending on overrides)
    expect(find.text('Current Goals'), findsOneWidget);

    // Check Recent Activity
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('New Personal Record!'), findsOneWidget);
    
    // Check Upcoming Meets
    expect(find.text('Upcoming Meets'), findsOneWidget);
    
    // Scroll to verify meets in list if needed (it's inside a scrollable column)
    // tester.ensureVisible helps scroll to it.
    await tester.scrollUntilVisible(find.text('Summer Championship'), 500);
    expect(find.text('Summer Championship'), findsOneWidget);
    
    // Verify "Next Meet" card content
    expect(find.text('Next Meet'), findsOneWidget);
    expect(find.textContaining('days'), findsAtLeastNWidgets(1)); // Days remaining in Next Meet and Streak message
  });
}
