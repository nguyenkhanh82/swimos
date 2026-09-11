import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/training_repository.dart';
import '../data/teams_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_session.dart';
import '../../profile/data/profile_repository.dart';

class TrainingLogScreen extends ConsumerStatefulWidget {
  final List<String> selectedTeamIds;

  /// Title shown in the dialog (e.g. "Create set" or "Log Practice").
  final String dialogTitle;

  /// When user taps "Do with timer" on a recent set, call this with that set (template).
  final void Function(TrainingSession template)? onDoWithTimer;

  const TrainingLogScreen({
    super.key,
    required this.selectedTeamIds,
    this.dialogTitle = 'Log Practice',
    this.onDoWithTimer,
  });

  @override
  ConsumerState<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends ConsumerState<TrainingLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _practiceNameController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedStroke = 'Free';
  int _distancePerRep = 100;
  int _numberOfReps = 1;
  int? _restSeconds;
  String _poolType = 'SCY';
  String _intensity = 'moderate';
  String? _selectedTeamId;
  bool _isLoading = false;

  List<TrainingSession>? _searchResults;
  bool _searchLoading = false;

  @override
  void initState() {
    super.initState();
    // Prefer default team from profile, then selected team from widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(defaultTeamIdProvider.future).then((defaultTeamId) {
        if (mounted) {
          setState(() {
            _selectedTeamId = defaultTeamId ??
                (widget.selectedTeamIds.isNotEmpty
                    ? widget.selectedTeamIds.first
                    : null);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _practiceNameController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (swimmerId == null) return;
    setState(() => _searchLoading = true);
    try {
      final repo = ref.read(trainingRepositoryProvider);
      final results = await repo.searchSets(
        swimmerId: swimmerId,
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        stroke: _selectedStroke,
        limit: 25,
      );
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _prefillFromSet(TrainingSession set) {
    setState(() {
      _descriptionController.text = set.setDescription;
      _selectedStroke = set.stroke;
      _distancePerRep = set.distancePerRep;
      _numberOfReps = set.numberOfReps;
      _selectedDate = set.trainingDate;
      _poolType = set.poolType;
      _intensity = set.intensity;
      _notesController.text = set.notes ?? '';
      _selectedTeamId = set.teamId;
    });
  }

  Future<void> _submit({bool startTimer = false}) async {
    if (!_formKey.currentState!.validate()) return;

    // Get selected swimmer ID
    final selectedSwimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (selectedSwimmerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a swimmer profile first')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(trainingRepositoryProvider);
      String? practiceId;
      final practiceName = _practiceNameController.text.trim();
      if (practiceName.isNotEmpty) {
        final practice = await repo.createPractice(
          swimmerId: selectedSwimmerId,
          practiceDate: _selectedDate,
          name: practiceName,
          teamId: _selectedTeamId,
        );
        practiceId = practice.id;
      }

      final sessionData = TrainingSession(
        id: '',
        userId: '',
        swimmerId: selectedSwimmerId,
        practiceId: practiceId,
        trainingDate: _selectedDate,
        setDescription: _descriptionController.text.trim(),
        stroke: _selectedStroke,
        distancePerRep: _distancePerRep,
        numberOfReps: _numberOfReps,
        totalDistance: _distancePerRep * _numberOfReps,
        restSeconds: _restSeconds,
        poolType: _poolType,
        intensity: _intensity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        teamId: _selectedTeamId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (startTimer) {
        if (!mounted) return;
        Navigator.pop(context);
        if (widget.onDoWithTimer != null) {
          widget.onDoWithTimer!(sessionData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timer navigation not configured.')),
          );
        }
      } else {
        await repo.createTrainingSession(
          swimmerId: sessionData.swimmerId!,
          trainingDate: sessionData.trainingDate,
          setDescription: sessionData.setDescription,
          stroke: sessionData.stroke,
          distancePerRep: sessionData.distancePerRep,
          numberOfReps: sessionData.numberOfReps,
          totalDistance: sessionData.totalDistance,
          restSeconds: sessionData.restSeconds,
          poolType: sessionData.poolType,
          intensity: sessionData.intensity,
          notes: sessionData.notes,
          teamId: sessionData.teamId,
          practiceId: sessionData.practiceId,
        );

        if (!mounted) return;
        ref.invalidate(trainingSessionsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice logged successfully!')),
        );
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
    final teamsAsync = ref.watch(teamsListProvider);

    return Dialog(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.dialogTitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search sets (log again)
                      _buildSearchSetsSection(),
                      const SizedBox(height: 16),

                      // Recent sets (previous practice)
                      _buildRecentSetsSection(),
                      const SizedBox(height: 16),

                      // Date
                      _buildDatePicker(),
                      const SizedBox(height: 16),

                      // Practice name (optional – groups this set into a practice)
                      Text(
                        'Practice name (optional)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _practiceNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Monday AM',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Team Selection
                      teamsAsync.when(
                        data: (teams) {
                          if (teams.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Team',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedTeamId,
                                  decoration: const InputDecoration(
                                    hintText: 'Select team (optional)',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('No Team'),
                                    ),
                                    ...teams.map((team) => DropdownMenuItem(
                                          value: team.id,
                                          child: Text(team.name),
                                        )),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedTeamId = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Description
                      Text(
                        'Set Description',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 10x100 Free on 1:30',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Stroke
                      Text(
                        'Stroke',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStroke,
                        items: ['Free', 'Back', 'Breast', 'Fly', 'IM']
                            .map((stroke) => DropdownMenuItem(
                                  value: stroke,
                                  child: Text(stroke),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStroke = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Distance and Reps
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distance/Rep',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _distancePerRep.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    suffixText: 'm/yd',
                                  ),
                                  onChanged: (value) {
                                    _distancePerRep =
                                        int.tryParse(value) ?? 100;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reps',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _numberOfReps.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _numberOfReps = int.tryParse(value) ?? 1;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pool Type
                      Text(
                        'Pool Type',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _poolType,
                        items: ['SCY', 'SCM', 'LCM']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _poolType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      Text(
                        'Notes (Optional)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Additional notes...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _submit(startTimer: false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFF0EA5E9)),
                                  foregroundColor: const Color(0xFF0EA5E9),
                                ),
                                child: Text('Save Only',
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _submit(startTimer: true),
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
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        'Log Time',
                                        style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search sets to log again',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10x100 Free',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searchLoading ? null : _runSearch,
              child: _searchLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search'),
            ),
          ],
        ),
        if (_searchResults != null) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 160),
            child: _searchResults!.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No sets found',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults!.length,
                    itemBuilder: (context, index) {
                      final s = _searchResults![index];
                      final dateStr =
                          '${s.trainingDate.year}-${s.trainingDate.month.toString().padLeft(2, '0')}-${s.trainingDate.day.toString().padLeft(2, '0')}';
                      return ListTile(
                        dense: true,
                        title: Text(
                          s.setDescription,
                          style: GoogleFonts.outfit(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${s.stroke} · ${s.distancePerRep}×${s.numberOfReps} · $dateStr',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _prefillFromSet(s),
                              child: Text('Use',
                                  style: GoogleFonts.outfit(fontSize: 12)),
                            ),
                            if (widget.onDoWithTimer != null)
                              TextButton(
                                onPressed: () {
                                  widget.onDoWithTimer!(s);
                                },
                                child: Text('Timer',
                                    style: GoogleFonts.outfit(fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentSetsSection() {
    final recentAsync = ref.watch(recentSetsForSwimmerProvider);
    return recentAsync.when(
      data: (sets) {
        if (sets.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent sets',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  final s = sets[index];
                  final dateStr =
                      '${s.trainingDate.year}-${s.trainingDate.month.toString().padLeft(2, '0')}-${s.trainingDate.day.toString().padLeft(2, '0')}';
                  return ListTile(
                    dense: true,
                    title: Text(
                      s.setDescription,
                      style: GoogleFonts.outfit(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${s.stroke} · ${s.distancePerRep}×${s.numberOfReps} · $dateStr',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _prefillFromSet(s),
                          child: Text('Use',
                              style: GoogleFonts.outfit(fontSize: 12)),
                        ),
                        if (widget.onDoWithTimer != null)
                          TextButton(
                            onPressed: () {
                              widget.onDoWithTimer!(s);
                            },
                            child: Text('Timer',
                                style: GoogleFonts.outfit(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.outfit(),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
