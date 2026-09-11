// Minimal smoke test: app builds without crashing.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swim_tracker_mobile/src/app.dart';
import 'package:swim_tracker_mobile/src/features/authentication/data/auth_repository.dart';
import 'package:swim_tracker_mobile/src/features/training/data/swim_times_sync_service.dart';
import 'helpers/fake_swim_times_sync_service.dart';

/// Minimal auth fake for smoke test: signed out, no Supabase.
class FakeAuthRepository implements AuthRepository {
  final _authStateController = StreamController<AuthState>.broadcast();

  FakeAuthRepository() {
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}

  @override
  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName, {
    String role = 'parent',
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  testWidgets('App builds and shows material app', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          swimTimesSyncServiceProvider.overrideWithValue(FakeSwimTimesSyncService()),
        ],
        child: const SwimTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
