import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swim_tracker_mobile/src/app.dart';
import 'package:swim_tracker_mobile/src/features/authentication/data/auth_repository.dart';
import 'package:swim_tracker_mobile/src/features/training/data/teams_repository.dart';
import 'package:swim_tracker_mobile/src/features/training/data/swim_times_sync_service.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/team.dart';
import '../../../helpers/fake_swim_times_sync_service.dart';

// Mock Auth Repository
class MockAuthRepository extends Mock implements AuthRepository {
  final _authStateController = StreamController<AuthState>.broadcast();
  User? _currentUser;

  MockAuthRepository() {
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
  testWidgets('TrainingScreen shows empty state when no teams', (tester) async {
    final mockAuthRepo = MockAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          teamsListProvider.overrideWith((ref) => Future.value([])),
          teamsForSwimmerProvider.overrideWith((ref) => Future.value([])),
          swimTimesSyncServiceProvider.overrideWithValue(FakeSwimTimesSyncService()),
        ],
        child: const SwimTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Training tab
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();

    // Verify empty state elements
    expect(find.text('No Teams Yet'), findsOneWidget);
    expect(find.text('Create or import a team to start tracking your training'), findsOneWidget);
    expect(find.text('Create Team'), findsOneWidget);
  });

  testWidgets('TrainingScreen shows teams when available', (tester) async {
    final mockAuthRepo = MockAuthRepository();
    final mockTeams = [
      Team(
        id: 'team-1',
        name: 'Test Team',
        teamType: TeamType.regular,
        createdBy: 'test-user-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          teamsListProvider.overrideWith((ref) => Future.value(mockTeams)),
          teamsForSwimmerProvider.overrideWith((ref) => Future.value(mockTeams)),
          swimTimesSyncServiceProvider.overrideWithValue(FakeSwimTimesSyncService()),
        ],
        child: const SwimTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Training tab
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();

    // Verify main content: tab labels (Log History + Goals)
    expect(find.text('Log History'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    // Header shows either "Select Teams" or "1 team selected" depending on restored selection
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Select Teams' || (w.data ?? '').contains('selected')),
      ),
      findsWidgets,
    );
  });

  testWidgets('TrainingScreen has correct app bar actions', (tester) async {
    final mockAuthRepo = MockAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          teamsListProvider.overrideWith((ref) => Future.value([])),
          swimTimesSyncServiceProvider.overrideWithValue(FakeSwimTimesSyncService()),
        ],
        child: const SwimTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Training tab
    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();

    // Verify app bar has manage teams and custom events buttons
    expect(find.byIcon(Icons.group), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
  });
}
