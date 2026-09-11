import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile/data/profile_repository.dart';
import '../data/teams_repository.dart';
import '../domain/team.dart';
import 'team_selection_sheet.dart';
import 'training_history_screen.dart';
import 'goals_screen.dart';
import 'schedule_screen.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

const String _selectedTeamIdsKey = 'selected_training_team_ids';

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  List<String> _selectedTeamIds = [];
  bool _teamsRestored = false;

  Future<void> _restoreSelectedTeams() async {
    if (_teamsRestored) return;
    _teamsRestored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_selectedTeamIdsKey);
      if (ids != null && ids.isNotEmpty) {
        if (mounted) setState(() => _selectedTeamIds = ids);
        return;
      }
      final defaultTeamId = await ref.read(defaultTeamIdProvider.future);
      if (defaultTeamId != null && mounted) {
        setState(() => _selectedTeamIds = [defaultTeamId]);
        await prefs.setStringList(_selectedTeamIdsKey, [defaultTeamId]);
      }
    } catch (_) {}
  }

  Future<void> _saveSelectedTeams(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_selectedTeamIdsKey, ids);
      if (ids.isNotEmpty) {
        await ref.read(profileRepositoryProvider).setDefaultTeam(ids.first);
        ref.invalidate(defaultTeamIdProvider);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _restoreSelectedTeams());
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsForSwimmerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Training', style: GoogleFonts.outfit()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => context.push('/training/teams'),
            tooltip: 'Manage Teams',
          ),
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () => context.push('/training/events'),
            tooltip: 'Custom Events',
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Team Selection Header
              _buildTeamSelectionHeader(context, teams),

              // Main Content: History (grouped by date, relog from set) + Goals
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF00E5FF),
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: Color(0xFF00E5FF),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Practices'),
                          Tab(text: 'Schedule'),
                          Tab(text: 'Goals'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            TrainingHistoryScreen(
                                selectedTeamIds: _selectedTeamIds),
                            const ScheduleScreen(),
                            const GoalsScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading teams: $err', style: GoogleFonts.outfit()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(teamsForSwimmerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0055FF)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              blurRadius: 15,
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateSetDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Create practice',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTeamSelectionHeader(BuildContext context, List<Team> teams) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showTeamSelection(context, teams),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, size: 20, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedTeamIds.isEmpty
                            ? 'Select Teams'
                            : '${_selectedTeamIds.length} team${_selectedTeamIds.length > 1 ? 's' : ''} selected',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Teams Yet',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create or import a team to start tracking your training',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/training/teams/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF010E1A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamSelection(BuildContext context, List<Team> teams) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamSelectionSheet(
        teams: teams,
        selectedTeamIds: _selectedTeamIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedTeamIds = selected;
      });
      _saveSelectedTeams(selected);
      // Refresh teams list in case a new team was created or joined
      ref.invalidate(teamsForSwimmerProvider);
    }
  }

  /// Opens screen to create a new practice.
  void _showCreateSetDialog(BuildContext context) {
    context.push('/training/create-practice');
  }
}
