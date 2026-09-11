import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/training/presentation/goal_history_screen.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/meets/presentation/meets_screen.dart';
import '../features/meets/presentation/meet_details_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/meets/domain/meet.dart';

import '../features/nutrition/presentation/log_meal_screen.dart';
import '../features/training/presentation/training_screen.dart';
import '../features/training/presentation/team_management_screen.dart';
import '../features/training/presentation/create_team_screen.dart';
import '../features/training/presentation/custom_events_screen.dart';
import '../features/training/presentation/create_practice_screen.dart';
import '../features/training/presentation/build_macro_plan_screen.dart';
import '../features/training/presentation/practice_detail_screen.dart';
import '../features/training/presentation/create_goal_screen.dart';
import '../features/training/presentation/goal_detail_screen.dart';
import '../features/training/presentation/goal_practice_screen.dart';
import '../features/training/presentation/swimmer_profile_screen.dart';
import '../features/training/presentation/timed_set_screen.dart';
import '../features/training/presentation/relog_manual_screen.dart';
import '../features/training/presentation/set_progress_screen.dart';
import '../features/training/presentation/exercise_drill_screen.dart';
import '../features/training/domain/training_session.dart';
import '../features/swim_times/presentation/add_swim_time_screen.dart';

// GoRouter configuration provided by Riverpod
final goRouterProvider = Provider<GoRouter>((ref) {
  // Read auth repository (don't watch to avoid recreating router)
  final authRepo = ref.read(authRepositoryProvider);

  // Create a refresh listenable for auth state changes
  final refreshListenable = GoRouterRefreshStream(
    authRepo.authStateChanges,
  );

  // Keep the router alive to prevent recreation
  ref.keepAlive();

  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      try {
        // Get current user from auth repository
        final currentUser = authRepo.currentUser;
        final isLoggedIn = currentUser != null;
        final path = state.uri.path;
        final isLoggingIn = path == '/login';
        final isWelcome = path == '/welcome';
        final isRoot = path == '/';

        debugPrint('🔀 Router Redirect Check:');
        debugPrint('  Path: $path');
        debugPrint('  User: ${currentUser?.email ?? "null"}');
        debugPrint('  IsLoggedIn: $isLoggedIn');

        // Handle root path
        if (isRoot) {
          debugPrint('  ✅ Root path, redirecting to /welcome');
          return '/welcome';
        }

        if (!isLoggedIn) {
          // If not logged in and not on login or welcome page, redirect to welcome
          if (!isLoggingIn && !isWelcome) {
            debugPrint('  ✅ Not logged in, redirecting to /welcome');
            return '/welcome';
          }
          // Allow welcome and login pages
          debugPrint('  ⏭️  Allowing access to $path (not logged in)');
          return null;
        } else {
          // If logged in and on login or welcome page, redirect to home
          if (isLoggingIn || isWelcome) {
            debugPrint('  ✅ Logged in, redirecting from $path to /home');
            return '/home';
          }
          // Allow other pages for logged in users
          debugPrint('  ⏭️  Allowing access to $path (logged in)');
          return null;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error in redirect: $e');
        debugPrint('Stack trace: $stackTrace');
        // On error, allow navigation to continue
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/welcome',
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final isSignUp = tab == 'signup';
          return LoginScreen(isSignUp: isSignUp);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/nutrition/log',
        builder: (context, state) => const LogMealScreen(),
      ),
      GoRoute(
        path: '/add-swim-time',
        builder: (context, state) {
          // For new entries, pass no parameters (null timeToEdit)
          // For edit mode, would need to fetch SwimTime by ID from repository
          return const AddSwimTimeScreen();
        },
      ),
      // Keep /meets available if needed strictly, or remove it as it's now a tab
      GoRoute(
        path: '/meets',
        builder: (context, state) => const MeetsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              // Pass the meet object via extra if available, or fetch it (fetching not implemented here yet)
              // For now, we assume extra is passed or we show error/loading
              // Ideally, we'd use a provider to get the meet by ID from the cache
              final meet = state.extra as SwimMeet?;
              if (meet == null) {
                return const Scaffold(
                    body: Center(child: Text('Meet not found')));
              }
              return MeetDetailsScreen(meet: meet);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) => const TrainingScreen(),
        routes: [
          GoRoute(
            path: 'create-practice',
            builder: (context, state) => const CreatePracticeScreen(),
          ),
          GoRoute(
            path: 'practices/:id',
            builder: (context, state) {
              final practiceId = state.pathParameters['id'] ?? '';
              return PracticeDetailScreen(practiceId: practiceId);
            },
          ),
          GoRoute(
            path: 'teams',
            builder: (context, state) => const TeamManagementScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateTeamScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) {
              final teamId = state.uri.queryParameters['teamId'];
              return CustomEventsScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: 'goals',
            redirect: (context, state) {
              if (state.uri.path == '/training/goals') {
                return '/training'; // Redirect exact path to training screen
              }
              return null;
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateGoalScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final goalId = state.pathParameters['id'] ?? '';
                  return GoalDetailScreen(goalId: goalId);
                },
                routes: [
                  GoRoute(
                    path: 'practice',
                    builder: (context, state) {
                      final goalId = state.pathParameters['id'] ?? '';
                      final extra = state.extra as Map<String, dynamic>?;
                      final swimmerId = extra?['swimmerId'] as String? ?? '';
                      return GoalPracticeScreen(
                        goalId: goalId,
                        swimmerId: swimmerId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      final goalId = state.pathParameters['id'] ?? '';
                      return GoalHistoryScreen(goalId: goalId);
                    },
                  ),
                  GoRoute(
                    path: 'build-macro-plan',
                    builder: (context, state) {
                      final goalId = state.pathParameters['id'] ?? '';
                      final extra = state.extra as Map<String, dynamic>?;
                      final swimmerId = extra?['swimmerId'] as String? ?? '';
                      return BuildMacroPlanScreen(
                        goalId: goalId,
                        swimmerId: swimmerId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'timed-set',
            builder: (context, state) {
              final extra = state.extra;
              TrainingSession? template;
              DateTime? trainingDate;
              if (extra is Map) {
                template = extra['template'] as TrainingSession?;
                trainingDate = extra['trainingDate'] as DateTime?;
              } else {
                template = extra as TrainingSession?;
              }
              if (template == null) {
                return const Scaffold(
                  body: Center(child: Text('Set template required')),
                );
              }
              return TimedSetScreen(
                  setTemplate: template, trainingDate: trainingDate);
            },
          ),
          GoRoute(
            path: 'relog-manual',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final template = extra?['template'] as TrainingSession?;
              final date =
                  extra?['trainingDate'] as DateTime? ?? DateTime.now();
              if (template == null) {
                return const Scaffold(
                  body: Center(child: Text('Set template required')),
                );
              }
              return RelogManualScreen(
                  setTemplate: template, trainingDate: date);
            },
          ),
          GoRoute(
            path: 'set-progress',
            builder: (context, state) {
              final extra = state.extra;
              TrainingSession? template;
              if (extra is Map) {
                template =
                    TrainingSession.fromJson(extra as Map<String, dynamic>);
              } else {
                template = extra as TrainingSession?;
              }
              if (template == null) {
                return const Scaffold(
                  body: Center(child: Text('Set required')),
                );
              }
              return SetProgressScreen(setTemplate: template);
            },
          ),
          GoRoute(
            path: 'exercise-drill',
            builder: (context, state) {
              final extra = state.extra;
              TrainingSession? template;
              if (extra is Map) {
                template =
                    TrainingSession.fromJson(extra as Map<String, dynamic>);
              } else {
                template = extra as TrainingSession?;
              }
              if (template == null) {
                return const Scaffold(
                  body: Center(child: Text('Set required')),
                );
              }
              return ExerciseDrillScreen(setTemplate: template);
            },
          ),
          GoRoute(
            path: 'swimmers',
            redirect: (context, state) {
              if (state.uri.path == '/training/swimmers') {
                return '/training';
              }
              return null;
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const SwimmerProfileScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final swimmerId = state.pathParameters['id'] ?? '';
                  return SwimmerProfileScreen(swimmerId: swimmerId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Helper for converting Stream to Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Don't notify immediately - let the router initialize first
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) {
        debugPrint('🔄 Auth state changed, refreshing router');
        notifyListeners();
      },
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
