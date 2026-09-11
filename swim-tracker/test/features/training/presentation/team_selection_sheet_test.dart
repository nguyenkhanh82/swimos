import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/team.dart';
import 'package:swim_tracker_mobile/src/features/training/presentation/team_selection_sheet.dart';

void main() {
  testWidgets('TeamSelectionSheet shows teams when available', (tester) async {
    final mockTeams = [
      Team(
        id: 'team-1',
        name: 'Team A',
        teamType: TeamType.regular,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Team(
        id: 'team-2',
        name: 'Team B',
        teamType: TeamType.camp,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => TeamSelectionSheet(
                      teams: mockTeams,
                      selectedTeamIds: const [],
                    ),
                  );
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify teams are displayed
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(find.text('Select Teams'), findsOneWidget);
  });

  testWidgets('TeamSelectionSheet shows empty state when no teams',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const TeamSelectionSheet(
                      teams: [],
                      selectedTeamIds: [],
                    ),
                  );
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('No teams yet'), findsOneWidget);
    expect(find.text('Create New Team'), findsOneWidget);
  });

  testWidgets('TeamSelectionSheet allows team selection', (tester) async {
    final mockTeams = [
      Team(
        id: 'team-1',
        name: 'Team A',
        teamType: TeamType.regular,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await showModalBottomSheet<List<String>>(
                    context: context,
                    builder: (context) => TeamSelectionSheet(
                      teams: mockTeams,
                      selectedTeamIds: const [],
                    ),
                  );
                  // Result would contain selected team IDs
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet is displayed
    expect(find.text('Select Teams'), findsOneWidget);
    expect(find.text('Team A'), findsOneWidget);
  });
}
