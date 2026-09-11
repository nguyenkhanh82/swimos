import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/team.dart';

class TeamSelectionSheet extends StatefulWidget {
  final List<Team> teams;
  final List<String> selectedTeamIds;

  const TeamSelectionSheet({
    super.key,
    required this.teams,
    required this.selectedTeamIds,
  });

  @override
  State<TeamSelectionSheet> createState() => _TeamSelectionSheetState();
}

class _TeamSelectionSheetState extends State<TeamSelectionSheet> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTeamIds);
  }

  @override
  Widget build(BuildContext context) {
    final activeTeams = widget.teams.where((t) => t.isActive).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Teams',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, _selectedIds);
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Team List
          Flexible(
            child: activeTeams.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No teams yet',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeTeams.length,
                    itemBuilder: (context, index) {
                      final team = activeTeams[index];
                      final isSelected = _selectedIds.contains(team.id);
                      
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(team.id);
                            } else {
                              _selectedIds.remove(team.id);
                            }
                          });
                        },
                        title: Text(
                          team.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                        subtitle: team.location != null
                            ? Text(
                                team.location!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                        secondary: _buildTeamTypeIcon(team.teamType),
                      );
                    },
                  ),
          ),
          
          // Create Team Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Close the selection sheet first
                Navigator.pop(context, _selectedIds);
                // Navigate to create team screen
                // The parent will refresh teams list when returning
                context.push('/training/teams/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Team'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9),
                side: const BorderSide(color: Color(0xFF0EA5E9)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTypeIcon(teamType) {
    IconData icon;
    Color color;

    switch (teamType.toString()) {
      case 'TeamType.camp':
        icon = Icons.cabin;
        color = Colors.orange;
        break;
      case 'TeamType.privateCoach':
        icon = Icons.person;
        color = Colors.purple;
        break;
      case 'TeamType.self':
        icon = Icons.person_outline;
        color = Colors.blue;
        break;
      default:
        icon = Icons.group;
        color = const Color(0xFF0EA5E9);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
