import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/training_repository.dart';
import '../data/teams_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_session.dart';
import '../../profile/data/profile_repository.dart';

class CreatePracticeScreen extends ConsumerStatefulWidget {
  const CreatePracticeScreen({super.key});

  @override
  ConsumerState<CreatePracticeScreen> createState() =>
      _CreatePracticeScreenState();
}

class _CreatePracticeScreenState extends ConsumerState<CreatePracticeScreen> {
  final _practiceNameController = TextEditingController();
  final _aiPromptController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTeamId;
  String _trainingType = 'Water';
  String _equipmentType = 'Bodyweight';
  int _durationMinutes = 60;

  bool _isLoading = false;
  bool _isAILoading = false;

  List<TrainingSession> _sets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(defaultTeamIdProvider.future).then((defaultTeamId) {
        if (mounted) {
          setState(() => _selectedTeamId = defaultTeamId);
        }
      });
    });
  }

  @override
  void dispose() {
    _practiceNameController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  String _normalizeStroke(String rawStroke) {
    final lower = rawStroke.toLowerCase();
    if (lower.contains('free')) return 'Free';
    if (lower.contains('back')) return 'Back';
    if (lower.contains('breast')) return 'Breast';
    if (lower.contains('fly') || lower.contains('butterfly')) return 'Fly';
    if (lower.contains('im') || lower.contains('medley')) return 'IM';
    if (lower.contains('drill')) return 'Drill';
    if (lower.contains('kick')) return 'Kick';
    if (lower.contains('dry') || lower.contains('land')) return 'Dryland';
    return 'Mixed';
  }

  Future<void> _generateAI() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what you want to train')),
      );
      return;
    }

    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (!mounted) return;
    if (swimmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a swimmer first')),
      );
      return;
    }

    setState(() => _isAILoading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'generate-practice',
        body: {
          'swimmer_id': swimmerId,
          'prompt': 'Target Duration: $_durationMinutes minutes. $prompt',
          'training_type': _trainingType,
          'equipment_type': _equipmentType,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['error'] ?? 'Unknown error');
      }

      final List<dynamic> suggestions = data['suggestions'];

      setState(() {
        _sets = suggestions
            .map((s) => TrainingSession(
                  id: '',
                  userId: '',
                  swimmerId: swimmerId,
                  trainingDate: _selectedDate,
                  setDescription: s['set_description'] ?? 'Generated Set',
                  stroke: _normalizeStroke(s['stroke'] ?? 'Free'),
                  distancePerRep: s['distance_per_rep'] ?? 100,
                  numberOfReps: s['number_of_reps'] ?? 1,
                  totalDistance: s['total_distance'] ?? 100,
                  restSeconds: s['rest_seconds'],
                  poolType: 'SCY', // Default
                  intensity: s['intensity'] ?? 'moderate',
                  notes: s['rationale'],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating practice: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAILoading = false);
      }
    }
  }

  void _addManualSet() {
    final swimmerId = ref.read(selectedSwimmerIdProvider).valueOrNull;
    if (swimmerId == null) return;

    setState(() {
      _sets.add(TrainingSession(
        id: '',
        userId: '',
        swimmerId: swimmerId,
        trainingDate: _selectedDate,
        setDescription: 'New Set',
        stroke: 'Free',
        distancePerRep: 100,
        numberOfReps: 1,
        totalDistance: 100,
        poolType: 'SCY',
        intensity: 'moderate',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  Future<void> _savePractice() async {
    if (_sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one set to the practice.')),
      );
      return;
    }

    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (swimmerId == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(trainingRepositoryProvider);

      final practiceName = _practiceNameController.text.trim().isNotEmpty
          ? _practiceNameController.text.trim()
          : 'Custom Practice';

      final practice = await repo.createPractice(
        swimmerId: swimmerId,
        practiceDate: _selectedDate,
        name: practiceName,
        teamId: _selectedTeamId,
      );

      for (var set in _sets) {
        await repo.createTrainingSession(
          swimmerId: swimmerId,
          trainingDate: _selectedDate,
          setDescription: set.setDescription,
          stroke: set.stroke,
          distancePerRep: set.distancePerRep,
          numberOfReps: set.numberOfReps,
          totalDistance: set.distancePerRep * set.numberOfReps,
          restSeconds: set.restSeconds,
          poolType: set.poolType,
          intensity: set.intensity,
          notes: set.notes,
          teamId: _selectedTeamId,
          practiceId: practice.id,
        );
      }

      ref.invalidate(practicesProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Practice saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Practice', style: GoogleFonts.outfit()),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _savePractice,
              child: Text('Save',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Info
            TextFormField(
              controller: _practiceNameController,
              decoration: InputDecoration(
                labelText: 'Practice Name (Optional)',
                hintText: 'e.g. Endurance Day',
                labelStyle: GoogleFonts.outfit(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: GoogleFonts.outfit(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            teamsAsync.when(
              data: (teams) {
                if (teams.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedTeamId,
                  decoration: InputDecoration(
                    labelText: 'Team',
                    labelStyle: GoogleFonts.outfit(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Team')),
                    ...teams.map((t) =>
                        DropdownMenuItem(value: t.id, child: Text(t.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedTeamId = val),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // AI Generation Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 8),
                      Text('AI Generator',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF0EA5E9))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiPromptController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. I want an intense 3000-yard breaststroke focus workout',
                      hintStyle: GoogleFonts.outfit(fontSize: 14),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _trainingType,
                          dropdownColor: const Color(0xFF001B33),
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Training Type',
                            labelStyle:
                                GoogleFonts.outfit(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                          ),
                          items: ['Water', 'Dryland']
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _trainingType = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _durationMinutes,
                          dropdownColor: const Color(0xFF001B33),
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Duration',
                            labelStyle:
                                GoogleFonts.outfit(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                          ),
                          items: [30, 45, 60, 90, 120]
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text('$d min')))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _durationMinutes = val!),
                        ),
                      ),
                    ],
                  ),
                  if (_trainingType == 'Dryland') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _equipmentType,
                      dropdownColor: const Color(0xFF001B33),
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Equipment',
                        labelStyle: GoogleFonts.outfit(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                      items: [
                        'Bodyweight',
                        'Stretch Band',
                        'Full Gym',
                        'Dumbbell'
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _equipmentType = val!),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isAILoading ? null : _generateAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                    ),
                    child: _isAILoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Generate Practice',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sets List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Practice Sets',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addManualSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_sets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                      'No sets added yet.\nGenerate with AI or add manually.',
                      style: GoogleFonts.outfit(color: Colors.grey),
                      textAlign: TextAlign.center),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.1),
                                child: Text('${index + 1}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF0EA5E9),
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: set.setDescription,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Description',
                                    labelStyle: GoogleFonts.outfit(),
                                  ),
                                  onChanged: (val) => _sets[index] =
                                      _sets[index]
                                          .copyWith(setDescription: val),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _removeSet(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: set.stroke,
                                  decoration: const InputDecoration(
                                      isDense: true, labelText: 'Stroke'),
                                  items: [
                                    'Free',
                                    'Back',
                                    'Breast',
                                    'Fly',
                                    'IM',
                                    'Drill',
                                    'Kick',
                                    'Mixed',
                                    'Dryland'
                                  ]
                                      .map((s) => DropdownMenuItem(
                                          value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _sets[index] =
                                          _sets[index].copyWith(stroke: val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: set.numberOfReps.toString(),
                                  decoration: const InputDecoration(
                                      isDense: true, labelText: 'Reps'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) => _sets[index] =
                                      _sets[index].copyWith(
                                          numberOfReps: int.tryParse(val) ?? 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: set.distancePerRep.toString(),
                                  decoration: const InputDecoration(
                                      isDense: true, labelText: 'Dist/Rep'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) => _sets[index] =
                                      _sets[index].copyWith(
                                          distancePerRep:
                                              int.tryParse(val) ?? 100),
                                ),
                              ),
                            ],
                          ),
                          if (set.notes != null && set.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Note: ${set.notes}',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              context.push('/training/exercise-drill',
                                  extra: set);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_outline,
                                    size: 16, color: Color(0xFF0EA5E9)),
                                const SizedBox(width: 4),
                                Text('Watch Demo',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF0EA5E9),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
