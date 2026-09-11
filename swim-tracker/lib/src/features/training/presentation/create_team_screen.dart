import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/teams_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/team.dart';
import '../domain/swimmer_profile.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _levelController = TextEditingController();
  final _searchController = TextEditingController();
  
  TeamType _selectedType = TeamType.regular;
  bool _isLoading = false;
  Team? _selectedExistingTeam;
  List<Team> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _levelController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    debugPrint('[CreateTeamScreen] _onSearchChanged called with query: "$query"');
    
    if (query.isEmpty) {
      debugPrint('[CreateTeamScreen] Query is empty, clearing results');
      setState(() {
        _searchResults = [];
        _selectedExistingTeam = null;
      });
      return;
    }

    // Debounce: wait a bit before searching
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if query changed during delay
    if (_searchController.text.trim() != query) {
      debugPrint('[CreateTeamScreen] Query changed during debounce, ignoring');
      return;
    }

    debugPrint('[CreateTeamScreen] Starting search for: "$query"');
    setState(() => _isSearching = true);
    
    try {
      debugPrint('[CreateTeamScreen] Calling searchTeams...');
      final results = await ref.read(teamsRepositoryProvider).searchTeams(query);
      debugPrint('[CreateTeamScreen] Search returned ${results.length} results');
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      if (results.isEmpty) {
        debugPrint('[CreateTeamScreen] No results found for query: "$query"');
      }
    } catch (e, stackTrace) {
      debugPrint('[CreateTeamScreen] ERROR in search: $e');
      debugPrint('[CreateTeamScreen] Stack trace: $stackTrace');
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    // If user selected an existing team, join it instead of creating
    if (_selectedExistingTeam != null) {
      setState(() => _isLoading = true);
      try {
        // Get current user's swimmer to add to team
        // Try primary first, then any swimmer, then selected swimmer
        final swimmersRepo = ref.read(swimmersRepositoryProvider);
        SwimmerProfile? swimmer;
        
        // First, try to get primary swimmer
        swimmer = await swimmersRepo.getPrimarySwimmer();
        
        // If no primary, try to get selected swimmer
        if (swimmer == null) {
          final selectedId = await swimmersRepo.getSelectedSwimmerId();
          if (selectedId != null) {
            swimmer = await swimmersRepo.getSwimmerById(selectedId);
          }
        }
        
        // If still no swimmer, get the first available swimmer
        if (swimmer == null) {
          final allSwimmers = await swimmersRepo.getSwimmers();
          if (allSwimmers.isNotEmpty) {
            swimmer = allSwimmers.first;
          }
        }
        
        if (swimmer == null) {
          throw Exception('Please create a swimmer profile first');
        }

        // Add swimmer to the selected team
        await ref.read(teamsRepositoryProvider).addSwimmerToTeam(
          swimmer.id,
          _selectedExistingTeam!.id,
        );

        if (mounted) {
          ref.invalidate(teamsForSwimmerProvider);
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    // Otherwise, create a new team
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(teamsRepositoryProvider).createTeam(
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        teamType: _selectedType,
        level: _levelController.text.trim().isEmpty
            ? null
            : _levelController.text.trim(),
      );

      if (mounted) {
        ref.invalidate(teamsForSwimmerProvider);
        context.pop(true); // Return true to indicate team was created
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Team', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Type (moved to top)
              Text(
                'Team Type',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: TeamType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(_getTeamTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                          _selectedExistingTeam = null;
                          _searchController.clear();
                          _searchResults = [];
                        });
                      }
                    },
                    selectedColor: const Color(0xFF0EA5E9),
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Show search for regular teams
              if (_selectedType == TeamType.regular) ...[
                Text(
                  'Search Existing Teams',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a team...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedExistingTeam = null;
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Search results
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchResults.isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final team = _searchResults[index];
                        final isSelected = _selectedExistingTeam?.id == team.id;
                        return ListTile(
                          title: Text(team.name),
                          subtitle: team.location != null
                              ? Text(team.location!)
                              : null,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedExistingTeam = team;
                              _nameController.text = team.name;
                              _locationController.text = team.location ?? '';
                            });
                          },
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF0EA5E9))
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No teams found. You can create a new team below.',
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                  ),
                ],
                
                // Divider
                if (_searchController.text.isNotEmpty || _selectedExistingTeam != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                  ),
              ],
              
              // Team Name
              Text(
                'Team Name',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                enabled: _selectedExistingTeam == null,
                decoration: InputDecoration(
                  hintText: _selectedExistingTeam != null
                      ? 'Selected from search'
                      : 'e.g., High School Swim Team',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Location
              Text(
                'Location (Optional)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., City, State',
                ),
              ),
              const SizedBox(height: 24),

              // Level
              Text(
                'Level (Optional)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Beginner, Advanced, Elite',
                ),
              ),
              const SizedBox(height: 32),

              // Create/Join Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedExistingTeam != null
                              ? 'Join Team'
                              : 'Create Team',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTeamTypeLabel(TeamType type) {
    switch (type) {
      case TeamType.regular:
        return 'Regular';
      case TeamType.camp:
        return 'Camp';
      case TeamType.privateCoach:
        return 'Private Coach';
      case TeamType.self:
        return 'Self';
    }
  }
}
