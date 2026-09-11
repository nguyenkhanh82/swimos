import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'training_history_screen.dart';

class GoalHistoryScreen extends StatelessWidget {
  final String goalId;

  const GoalHistoryScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Goal History', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: TrainingHistoryScreen(
        selectedTeamIds: const [],
        filterGoalId: goalId,
      ),
    );
  }
}
