import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Current User
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of Auth State Changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign In
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up
  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName, {
    String role = 'parent', // 'parent' or 'swimmer'
  }) async {
    try {
      // Attempt signup - Supabase will handle duplicate detection
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role, // Pass role in metadata so trigger can use it
        },
      );

      // Check for duplicates: If session is null, verify it's not a duplicate
      // by checking if user/profile was created recently
      // New users: created within last 1 second
      // Existing users: created more than 1 second ago
      if (response.user != null && response.session == null) {
        // Wait a moment for the trigger to complete
        await Future.delayed(const Duration(milliseconds: 500));

        bool isDuplicate = false;

        // Check user creation time
        final userCreatedAtStr = response.user!.createdAt;
        try {
          final userCreatedAt = DateTime.parse(userCreatedAtStr);
          final timeDiff = DateTime.now().difference(userCreatedAt);

          // If user was created more than 1 second ago, it's likely an existing user
          if (timeDiff.inSeconds > 1) {
            debugPrint(
                '🔍 Duplicate detected: User created ${timeDiff.inSeconds} seconds ago');
            isDuplicate = true;
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing user createdAt: $e');
        }

        // Double-check by looking at profile creation time
        if (!isDuplicate) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('user_id, created_at')
                .eq('user_id', response.user!.id)
                .maybeSingle();

            if (profile != null) {
              try {
                final profileCreatedAt =
                    DateTime.parse(profile['created_at'] as String);
                final profileTimeDiff =
                    DateTime.now().difference(profileCreatedAt);

                // If profile was created more than 1 second ago, it's likely a duplicate
                if (profileTimeDiff.inSeconds > 1) {
                  debugPrint(
                      '🔍 Duplicate detected: Profile created ${profileTimeDiff.inSeconds} seconds ago');
                  isDuplicate = true;
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing profile createdAt: $e');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error checking profile: $e');
          }
        }

        // If duplicate detected, throw exception
        if (isDuplicate) {
          throw const AuthException(
              'An account with this email already exists. Please sign in instead.');
        }

        // If not a duplicate, try to update the profile with the correct role
        // (in case trigger used default)
        try {
          await _supabase.from('profiles').update({
            'role': role,
            'full_name': fullName,
          }).eq('user_id', response.user!.id);
        } catch (e) {
          // If update fails, log but don't fail (profile might have been created by trigger)
          debugPrint('⚠️ Error updating profile: $e');
        }
      }

      return response;
    } on AuthException catch (e) {
      // Handle Supabase auth errors - check for duplicate email
      final message = e.message.toLowerCase();
      if (message.contains('user already registered') ||
          message.contains('email already exists') ||
          message.contains('already registered') ||
          message.contains('user already exists')) {
        throw const AuthException(
            'An account with this email already exists. Please sign in instead.');
      }
      // Re-throw other auth exceptions as-is
      rethrow;
    } on PostgrestException catch (e) {
      // Handle database errors (e.g., unique constraint violations)
      final message = e.message.toLowerCase();
      if (message.contains('duplicate') ||
          message.contains('unique') ||
          message.contains('already exists') ||
          e.code == '23505') {
        // PostgreSQL unique violation code
        throw const AuthException(
            'An account with this email already exists. Please sign in instead.');
      }
      throw AuthException('Failed to create account: ${e.message}');
    } catch (e) {
      // Handle any other errors
      if (e is AuthException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('already registered') ||
          errorStr.contains('user already') ||
          errorStr.contains('email already exists') ||
          errorStr.contains('duplicate')) {
        throw const AuthException(
            'An account with this email already exists. Please sign in instead.');
      }
      throw AuthException('Failed to create account: ${e.toString()}');
    }
  }

  // Reset Password (Forgot Password)
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: null, // You can set a custom redirect URL if needed
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user');
    await signOut(); // Ensure local session is cleared
  }
}

// Data Source Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Stream Provider for Auth State
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
