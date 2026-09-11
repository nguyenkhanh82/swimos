import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../domain/training_practice.dart';
import '../domain/training_session.dart';
import '../data/training_practice_service.dart';
import '../data/training_goals_repository.dart';
import '../data/training_repository.dart';

class GoalPracticeScreen extends ConsumerStatefulWidget {
  final String goalId;
  final String swimmerId;

  const GoalPracticeScreen({
    super.key,
    required this.goalId,
    required this.swimmerId,
  });

  @override
  ConsumerState<GoalPracticeScreen> createState() => _GoalPracticeScreenState();
}

class _GoalPracticeScreenState extends ConsumerState<GoalPracticeScreen> {
  List<TrainingPractice>? _practices;
  bool _isLoading = false;
  String? _error;
  GoalWithCurrentTime? _goalInfo;

  @override
  void initState() {
    super.initState();
    _loadGoalInfo();
  }

  Future<void> _loadGoalInfo() async {
    try {
      final goalsRepo = ref.read(trainingGoalsRepositoryProvider);
      final goalInfo = await goalsRepo.getGoalWithCurrentTime(
          widget.goalId, widget.swimmerId);
      if (mounted) {
        setState(() {
          _goalInfo = goalInfo;
        });
        // Auto-generate training sets once goal is loaded
        _generatePractice();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _generatePractice() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _practices = null;
    });

    try {
      final service = ref.read(trainingPracticeServiceProvider);
      final practices = await service.generatePracticeFromGoal(
        widget.swimmerId,
        widget.goalId,
      );

      setState(() {
        _practices = practices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFullPractice() async {
    if (_practices == null || _practices!.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final trainingRepo = ref.read(trainingRepositoryProvider);

      final today =
          DateTime.parse(DateTime.now().toIso8601String().split('T')[0]);
      final practiceName = _goalInfo?.goal.title ?? 'Goal Practice';

      // Ensure we don't accidentally create duplicate practices for the same goal on the same day.
      final existingPractices = await trainingRepo.getPractices(
        swimmerId: widget.swimmerId,
        startDate: today,
        endDate: today,
        goalId: widget.goalId,
      );

      if (existingPractices.any((p) => p.name == practiceName)) {
        final duplicatePractice =
            existingPractices.firstWhere((p) => p.name == practiceName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This training plan is already saved to your log. You can record your times there!'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
          context
              .pushReplacement('/training/practices/${duplicatePractice.id}');
        }
        return;
      }

      // 1. Create the parent practice
      final practice = await trainingRepo.createPractice(
        swimmerId: widget.swimmerId,
        practiceDate: today,
        name: practiceName,
        goalId: widget.goalId,
      );

      // 2. Insert all sets
      for (final generatedSet in _practices!) {
        await trainingRepo.createTrainingSession(
          swimmerId: widget.swimmerId,
          trainingDate: DateTime.now(),
          setDescription: generatedSet.setDescription,
          stroke: generatedSet.stroke,
          distancePerRep: generatedSet.distancePerRep,
          numberOfReps: generatedSet.numberOfReps,
          totalDistance: generatedSet.totalDistance,
          restSeconds: generatedSet.restSeconds,
          intensity: generatedSet.intensity,
          notes: generatedSet.rationale,
          practiceId: practice.id,
          goalId: widget.goalId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Full practice saved! You can record times natively in your Training log.'),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Invalidate practicesProvider so the UI refreshes
        ref.invalidate(practicesProvider);

        // Navigate correctly directly to the newly created Practice view
        // instead of getting stuck on an empty training log screen stack.
        context.pushReplacement('/training/practices/${practice.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving practice: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
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
        title: Text('Training Plan', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Info Card
            if (_goalInfo != null) _buildGoalInfoCard(_goalInfo!),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePractice,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? 'Generating...' : 'Generate Practice Sets',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.outfit(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Generated Practices
            if (_practices != null && _practices!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Generated Practice Outline',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._practices!.map((practice) => _buildPracticeCard(practice)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveFullPractice,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_task),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Practice to Training Log',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalInfoCard(GoalWithCurrentTime goalInfo) {
    final goal = goalInfo.goal;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Current Time',
                    goalInfo.currentBestTime != null
                        ? _formatTime(goalInfo.currentBestTime!)
                        : 'N/A',
                    Colors.grey[700]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInfo(
                    'Target Time',
                    goal.targetTimeSeconds != null
                        ? _formatTime(goal.targetTimeSeconds!)
                        : 'N/A',
                    const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            if (goalInfo.improvementNeeded != null &&
                goalInfo.percentImprovement != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Improvement needed: ${_formatTime(goalInfo.improvementNeeded!.abs())} (${goalInfo.percentImprovement!.toStringAsFixed(1)}%)',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(TrainingPractice practice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    practice.setDescription,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(practice.intensity)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    practice.intensity.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getIntensityColor(practice.intensity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPracticeDetail(
                    Icons.pool, '${practice.totalDistance}m total'),
                const SizedBox(width: 16),
                _buildPracticeDetail(Icons.repeat,
                    '${practice.numberOfReps}x${practice.distancePerRep}m'),
                if (practice.restSeconds > 0) ...[
                  const SizedBox(width: 16),
                  _buildPracticeDetail(
                      Icons.timer, '${practice.restSeconds}s rest'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      practice.rationale,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                final setTemplate = TrainingSession(
                  id: '',
                  userId: '',
                  swimmerId: widget.swimmerId,
                  trainingDate: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  setDescription: practice.setDescription,
                  stroke: practice.stroke,
                  distancePerRep: practice.distancePerRep,
                  numberOfReps: practice.numberOfReps,
                  totalDistance: practice.totalDistance,
                  restSeconds: practice.restSeconds,
                  intensity: practice.intensity,
                  notes: practice.rationale,
                );
                context.push('/training/exercise-drill', extra: setTemplate);
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
  }

  Widget _buildPracticeDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.blue;
      case 'hard':
        return Colors.orange;
      case 'race_pace':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${secs.toStringAsFixed(2)}s';
  }
}
