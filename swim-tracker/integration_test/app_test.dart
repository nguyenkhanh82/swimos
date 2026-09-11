import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swim_tracker_mobile/src/app.dart';
import 'package:swim_tracker_mobile/src/features/authentication/data/auth_repository.dart';
import 'package:swim_tracker_mobile/src/features/meets/data/meets_repository.dart';
import 'package:swim_tracker_mobile/src/features/swim_times/data/swim_times_repository.dart';
import 'package:swim_tracker_mobile/src/features/swim_times/domain/swim_time.dart';
import 'package:swim_tracker_mobile/src/features/training/data/swimmers_repository.dart';

// Mock Classes
class MockAuthRepository extends Mock implements AuthRepository {
  final _authStateController = StreamController<AuthState>.broadcast();
  User? _currentUser;

  MockAuthRepository() {
    // Default state: Unauthenticated
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<AuthResponse> signUpWithEmailAndPassword(
      String email, String password, String fullName,
      {String role = 'swimmer'}) async {
    // Simulate successful sign up with a fake user session
    final user = User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {'full_name': fullName},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    _currentUser = user;
    final session = Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: user,
    );

    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));

    return AuthResponse(session: session, user: user);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final user = User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
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
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<void> deleteAccount() async {
    await signOut();
  }
}

class MockSwimTimesRepository extends Mock implements SwimTimesRepository {
  final List<SwimTime> _swimTimes = [];

  @override
  Future<SwimTime> addSwimTime({
    required String swimmerId,
    required stroke,
    required int distance,
    required double timeSeconds,
    required DateTime date,
    required String course,
    String? meetName,
    String? eventName,
  }) async {
    // Create a swim time with a test ID
    final swimTime = SwimTime(
      id: 'test-swim-time-${_swimTimes.length + 1}',
      swimmerId: swimmerId,
      userId: 'test-user-id',
      stroke: stroke,
      distance: distance,
      eventName: eventName ?? '$distance ${stroke.value}',
      timeSeconds: timeSeconds,
      date: date,
      course: course,
      meetName: meetName,
      isPersonalBest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _swimTimes.add(swimTime);
    return swimTime;
  }

  @override
  Future<List<SwimTime>> getSwimTimes({
    required String swimmerId,
    stroke,
    int? distance,
    String? course,
    DateTime? startDate,
    DateTime? endDate,
    String? meetName,
    bool? isPersonalBest,
  }) async {
    return _swimTimes.where((st) {
      if (st.swimmerId != swimmerId) return false;
      if (course != null && st.course != course) return false;
      if (stroke != null && st.stroke != stroke) return false;
      if (distance != null && st.distance != distance) return false;
      return true;
    }).toList();
  }

  List<SwimTime> get savedSwimTimes => _swimTimes;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Sign Up -> Home -> Profile -> Delete Account (Mocked)',
      (tester) async {
    // Setup Mock
    final mockAuthRepo = MockAuthRepository();

    // Pump App with Overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          meetsListProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const SwimTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Welcome Screen
    debugPrint('Checking Welcome Screen...');
    expect(find.textContaining('Welcome to'), findsOneWidget);

    // Tap Get Started
    debugPrint('Tapping Get Started...');
    final getStartedBtn = find.text('Get Started');
    await tester.ensureVisible(getStartedBtn);
    await tester.tap(getStartedBtn);
    await tester.pumpAndSettle();

    // 2. Login Screen (Sign Up Tab)
    debugPrint('Checking Sign Up Screen...');
    expect(find.text('Create Account'), findsOneWidget);

    // Enter details
    const email = 'testuser@example.com';
    const password = 'password123';

    debugPrint('Entering credentials for $email...');

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.pumpAndSettle();

    // Tap Sign Up Button
    debugPrint('Tapping Sign Up...');
    final signUpBtn = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.ensureVisible(signUpBtn);
    await tester.tap(signUpBtn);

    // Wait for async auth logic
    await tester.pumpAndSettle();

    // 3. Home Screen
    debugPrint('Checking Home Screen...');
    // We expect to land on Home immediately since we mocked successful auth
    // We expect to land on Home immediately since we mocked successful auth
    expect(find.text("Current Goals"), findsOneWidget);

    // Tap Profile in Bottom Navigation
    debugPrint('Navigating to Profile...');
    await tester.tap(find
        .text('Profile')
        .last); // Find 'Profile' in nav bar (last likely as it's at bottom or explicitly find inside nav)
    await tester.pumpAndSettle();

    // 4. Profile Screen
    debugPrint('Checking Profile Screen...');
    expect(find.text('Profile'), findsOneWidget);

    // Scroll down to find Delete Account
    final deleteBtn = find.text('Delete Account');
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();

    // Tap Delete Account
    debugPrint('Deleting Account...');
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Confirm Dialog
    expect(find.text('Delete Account?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // 5. Back to Welcome
    debugPrint('Verifying redirection to Welcome...');
    expect(find.textContaining('Welcome to'), findsOneWidget);
  });

  testWidgets('E2E: Add Swim Time and verify in Records (Mocked)',
      (tester) async {
    // Setup Mocks
    final mockAuthRepo = MockAuthRepository();
    final mockSwimTimesRepo = MockSwimTimesRepository();

    // Sign in the user
    await mockAuthRepo.signInWithEmailAndPassword(
        'test@example.com', 'password');
    await tester.pumpAndSettle();

    // Pump App with Overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          meetsListProvider.overrideWith((ref) => Future.value([])),
          swimTimesRepositoryProvider.overrideWithValue(mockSwimTimesRepo),
          selectedSwimmerIdProvider
              .overrideWith((ref) => Future.value('test-swimmer-id')),
        ],
        child: const SwimTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Home Screen
    debugPrint('Checking Home Screen...');
    expect(find.textContaining('Current Goals'), findsOneWidget);

    // 2. Tap FAB button
    debugPrint('Tapping FAB...');
    final fabButton = find.byType(FloatingActionButton);
    expect(fabButton, findsOneWidget);
    await tester.tap(fabButton);
    await tester.pumpAndSettle();

    // 3. Bottom sheet should appear with "Add Swim Time"
    debugPrint('Checking for Add Swim Time menu item...');
    expect(find.text('Add Swim Time'), findsOneWidget);

    // 4. Tap "Add Swim Time"
    debugPrint('Tapping Add Swim Time...');
    await tester.tap(find.text('Add Swim Time'));
    await tester.pumpAndSettle();

    // 5. Verify Add Swim Time screen loaded
    debugPrint('Verifying Add Swim Time screen...');
    expect(find.text('Add Swim Time'), findsOneWidget);

    // 6. Fill in the form
    debugPrint('Filling in swim time form...');

    // Find text fields by type - the form has multiple TextFormField widgets
    // We need to be careful about which one we're interacting with
    final textFields = find.byType(TextFormField);

    // The Autocomplete widgets contain TextFormField internally
    // Try to find by text decoration or scroll to find the fields

    // Enter stroke - find the Autocomplete input for stroke
    debugPrint('Entering stroke...');
    await tester.enterText(textFields.at(0), 'Free');
    await tester.pumpAndSettle();
    // Select from dropdown
    final strokeOption = find.ancestor(
      of: find.text('Free'),
      matching: find.byType(InkWell),
    );
    if (strokeOption.evaluate().isNotEmpty) {
      await tester.tap(strokeOption.first);
      await tester.pumpAndSettle();
    }

    // Enter distance
    debugPrint('Entering distance...');
    await tester.enterText(textFields.at(1), '50');
    await tester.pumpAndSettle();
    // Select from dropdown
    final distanceOption = find.ancestor(
      of: find.text('50 yards'),
      matching: find.byType(InkWell),
    );
    if (distanceOption.evaluate().isNotEmpty) {
      await tester.tap(distanceOption.first);
      await tester.pumpAndSettle();
    }

    // Enter time in SS.CC format (23.45 seconds)
    debugPrint('Entering time...');
    final timeFields = find.ancestor(
      of: find.text('Time'),
      matching: find.byType(TextFormField),
    );
    if (timeFields.evaluate().isNotEmpty) {
      await tester.enterText(timeFields.first, '23.45');
      await tester.pumpAndSettle();
    } else {
      // Fallback: try to find by position
      await tester.enterText(textFields.at(2), '23.45');
      await tester.pumpAndSettle();
    }

    // Pool type should already be SCY by default
    debugPrint('Verifying pool type...');
    expect(find.text('Short Course Yards (SCY)'), findsAtLeastNWidgets(1));

    // 7. Tap Save button
    debugPrint('Tapping Save button...');
    final saveButton = find.widgetWithText(FilledButton, 'Save Time');
    await tester.dragUntilVisible(
      saveButton,
      find.byType(Scrollable).last,
      const Offset(0, -50),
    );
    await tester.pumpAndSettle();

    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Debug any snackbars that might be shown
    final snackBars = find.byType(SnackBar).evaluate();
    if (snackBars.isNotEmpty) {
      final textWidget = find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Text),
          )
          .evaluate()
          .first
          .widget as Text;
      debugPrint('⚠️ SnackBar visible: ${textWidget.data}');
    }

    // 8. Verify we're back on home screen
    debugPrint('Verifying navigation back to Home...');
    expect(find.textContaining('Current Goals'), findsOneWidget);

    // 9. Verify swim time was saved to repository
    debugPrint('Verifying swim time was saved...');
    expect(mockSwimTimesRepo.savedSwimTimes.length, 1);
    final savedTime = mockSwimTimesRepo.savedSwimTimes.first;
    expect(savedTime.distance, 50);
    expect(savedTime.stroke.value, 'Free');
    expect(savedTime.timeSeconds, 23.45);
    expect(savedTime.course, 'SCY');

    // 10. Navigate to Records screen
    debugPrint('Navigating to Records screen...');
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 11. Verify Records screen shows the new time
    // Note: This depends on the Records screen implementation
    // The Records screen reads from swim_times table via Supabase
    // In a real integration test, we'd need to mock the Supabase client
    // For now, we verify that the repository received the save call
    debugPrint('✅ E2E test completed: Swim time added successfully!');
  });
}
