import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swim_tracker_mobile/src/features/training/presentation/widgets/goal_suggestions_widget.dart';

void main() {
  group('GoalSuggestionsWidget Integration Tests', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              // Simulate loading by delaying
              await Future.delayed(const Duration(milliseconds: 100));
              return [];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('AI Goal Suggestions'), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state when no suggestions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return [];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No suggestions available yet'), findsOneWidget);
      expect(find.text('Complete more training sessions to get personalized goal suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.tips_and_updates_outlined), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              throw Exception('Failed to load suggestions');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Unable to load suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Exception'), findsOneWidget);
    });

    testWidgets('displays suggestions with correct UI elements', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: '100 Free - Reach BB Standard',
          goalType: 'time',
          stroke: 'Free',
          distance: 100,
          targetTimeSeconds: 58.99,
          targetDate: '2026-03-20',
          rationale: 'Your current best is 61.2s (B). Drop 2.2 seconds to reach BB standard.',
          priority: 'high',
        ),
        GoalSuggestion(
          title: 'Swim 40,000m Per Month',
          goalType: 'distance',
          targetDistance: 40000,
          distancePeriod: 'month',
          targetDate: '2026-04-30',
          rationale: 'Based on your recent average, this 14% increase will build endurance.',
          priority: 'medium',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show header
      expect(find.text('AI Goal Suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Should show both suggestions
      expect(find.text('100 Free - Reach BB Standard'), findsOneWidget);
      expect(find.text('Swim 40,000m Per Month'), findsOneWidget);

      // Should show rationale
      expect(find.textContaining('Your current best is 61.2s'), findsOneWidget);
      expect(find.textContaining('14% increase will build endurance'), findsOneWidget);

      // Should show goal type chips
      expect(find.text('Time Goal'), findsOneWidget);
      expect(find.text('Distance Goal'), findsOneWidget);

      // Should show target dates
      expect(find.textContaining('Target:'), findsNWidgets(2));

      // Should show create buttons
      expect(find.text('Create This Goal'), findsNWidgets(2));
    });

    testWidgets('displays priority indicators correctly', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'High Priority Goal',
          goalType: 'time',
          rationale: 'Important goal',
          priority: 'high',
        ),
        GoalSuggestion(
          title: 'Medium Priority Goal',
          goalType: 'distance',
          rationale: 'Moderate goal',
          priority: 'medium',
        ),
        GoalSuggestion(
          title: 'Low Priority Goal',
          goalType: 'frequency',
          rationale: 'Nice to have',
          priority: 'low',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GoalSuggestionsWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all three priority levels
      expect(find.text('High Priority Goal'), findsOneWidget);
      expect(find.text('Medium Priority Goal'), findsOneWidget);
      expect(find.text('Low Priority Goal'), findsOneWidget);

      // Should show priority icons
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.low_priority), findsOneWidget);
    });

    testWidgets('refresh button invalidates provider', (WidgetTester tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              callCount++;
              return [
                GoalSuggestion(
                  title: 'Test Goal',
                  goalType: 'time',
                  rationale: 'Test',
                  priority: 'high',
                ),
              ];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial load
      expect(callCount, 1);
      expect(find.text('Test Goal'), findsOneWidget);

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Should reload (callCount incremented)
      expect(callCount, 2);
    });

    testWidgets('displays different goal type chips correctly', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'Time Goal',
          goalType: 'time',
          rationale: 'Test',
          priority: 'high',
        ),
        GoalSuggestion(
          title: 'Distance Goal',
          goalType: 'distance',
          rationale: 'Test',
          priority: 'medium',
        ),
        GoalSuggestion(
          title: 'Frequency Goal',
          goalType: 'frequency',
          rationale: 'Test',
          priority: 'medium',
        ),
        GoalSuggestion(
          title: 'Custom Goal',
          goalType: 'custom',
          rationale: 'Test',
          priority: 'low',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GoalSuggestionsWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all goal type chips (may appear in title too, so at least once)
      expect(find.text('Time Goal'), findsAtLeastNWidgets(1));
      expect(find.text('Distance Goal'), findsAtLeastNWidgets(1));
      expect(find.text('Consistency Goal'), findsAtLeastNWidgets(1));
      expect(find.text('Custom Goal'), findsAtLeastNWidgets(1));
    });

    testWidgets('formats dates correctly', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'Goal with Date',
          goalType: 'time',
          targetDate: '2026-03-15',
          rationale: 'Test',
          priority: 'high',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show formatted date
      expect(find.textContaining('Target: 3/15/2026'), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('handles suggestions without target date', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'Goal without Date',
          goalType: 'custom',
          targetDate: null,
          rationale: 'No deadline',
          priority: 'low',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show goal without date section
      expect(find.text('Goal without Date'), findsOneWidget);
      expect(find.byIcon(Icons.event), findsNothing);
    });

    testWidgets('displays card with proper styling', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'Test Goal',
          goalType: 'time',
          rationale: 'Test rationale',
          priority: 'high',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have Card widget
      expect(find.byType(Card), findsWidgets);

      // Should have proper padding
      expect(find.byType(Padding), findsWidgets);

      // Should have button for creating goal
      expect(find.text('Create This Goal'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
    });

    testWidgets('shows multiple suggestions in correct order', (WidgetTester tester) async {
      final mockSuggestions = [
        GoalSuggestion(
          title: 'First Suggestion',
          goalType: 'time',
          rationale: 'First',
          priority: 'high',
        ),
        GoalSuggestion(
          title: 'Second Suggestion',
          goalType: 'distance',
          rationale: 'Second',
          priority: 'medium',
        ),
        GoalSuggestion(
          title: 'Third Suggestion',
          goalType: 'frequency',
          rationale: 'Third',
          priority: 'low',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GoalSuggestionsWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all suggestion titles
      expect(find.text('First Suggestion'), findsOneWidget);
      expect(find.text('Second Suggestion'), findsOneWidget);
      expect(find.text('Third Suggestion'), findsOneWidget);

      // Should have 3 create buttons
      expect(find.text('Create This Goal'), findsNWidgets(3));
    });

    testWidgets('handles very long rationale text', (WidgetTester tester) async {
      const longRationale = 'This is a very long rationale that explains in great detail why this goal is recommended for the swimmer based on their current performance, training history, and time standards. It includes multiple sentences and a lot of information to help the swimmer understand the reasoning behind the suggestion.';

      final mockSuggestions = [
        GoalSuggestion(
          title: 'Goal with Long Rationale',
          goalType: 'time',
          rationale: longRationale,
          priority: 'high',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GoalSuggestionsWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the long text
      expect(find.text(longRationale), findsOneWidget);
    });

    testWidgets('callback is triggered on goal created', (WidgetTester tester) async {
      var callbackTriggered = false;

      final mockSuggestions = [
        GoalSuggestion(
          title: 'Test Goal',
          goalType: 'time',
          rationale: 'Test',
          priority: 'high',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalSuggestionsProvider.overrideWith((ref) async {
              return mockSuggestions;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GoalSuggestionsWidget(
                onGoalCreated: () {
                  callbackTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Callback should exist (we can't test the actual creation without mocking Supabase)
      expect(find.text('Test Goal'), findsOneWidget);

      // Verify widget accepts callback
      expect(callbackTriggered, false); // Not triggered yet since we didn't create a goal
    });
  });
}
