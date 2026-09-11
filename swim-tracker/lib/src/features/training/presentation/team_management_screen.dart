import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/teams_repository.dart';
import '../domain/team.dart';

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Teams', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _TeamCard(team: team);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: () => context.push('/training/teams/import'),
            backgroundColor: Colors.white,
            child: const Icon(Icons.cloud_download, color: Color(0xFF0EA5E9)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push('/training/teams/create'),
            backgroundColor: const Color(0xFF0EA5E9),
            child: const Icon(Icons.add, color: Colors.white),
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
            Icon(Icons.group_add, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No Teams Yet',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first team to start tracking',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/training/teams/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTeamTypeColor(team.teamType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTeamTypeIcon(team.teamType),
            color: _getTeamTypeColor(team.teamType),
          ),
        ),
        title: Text(
          team.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (team.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(team.location!, style: GoogleFonts.outfit(fontSize: 12)),
                ],
              ),
            ],
            if (team.level != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  team.level!,
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // Navigate to team details
        },
      ),
    );
  }

  IconData _getTeamTypeIcon(TeamType type) {
    switch (type) {
      case TeamType.camp:
        return Icons.cabin;
      case TeamType.privateCoach:
        return Icons.person;
      case TeamType.self:
        return Icons.person_outline;
      default:
        return Icons.group;
    }
  }

  Color _getTeamTypeColor(TeamType type) {
    switch (type) {
      case TeamType.camp:
        return Colors.orange;
      case TeamType.privateCoach:
        return Colors.purple;
      case TeamType.self:
        return Colors.blue;
      default:
        return const Color(0xFF0EA5E9);
    }
  }
}
