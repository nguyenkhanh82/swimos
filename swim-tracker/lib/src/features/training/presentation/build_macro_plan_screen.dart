import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/macro_plan_generation_service.dart';
import '../data/scheduled_workouts_repository.dart';
import '../data/training_goals_repository.dart';

class BuildMacroPlanScreen extends ConsumerStatefulWidget {
  final String goalId;
  final String swimmerId;

  const BuildMacroPlanScreen({
    super.key,
    required this.goalId,
    required this.swimmerId,
  });

  @override
  ConsumerState<BuildMacroPlanScreen> createState() =>
      _BuildMacroPlanScreenState();
}

class _BuildMacroPlanScreenState extends ConsumerState<BuildMacroPlanScreen> {
  int _daysPerWeek = 4;
  int _weeks = 4;
  int _targetVolumeMin = 2000;
  int _targetVolumeMax = 4000;
  DateTime _startDate = DateTime.now();

  bool _isGenerating = false;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);
    try {
      final goal = await ref.read(goalProvider(widget.goalId).future);
      if (goal == null) throw Exception("Goal not found");

      final service = ref.read(macroPlanGenerationServiceProvider);
      final repo = ref.read(scheduledWorkoutsRepositoryProvider);

      // 1. Generate new schedule layout
      final workouts = await service.generateMacroPlan(
        goal: goal,
        swimmerId: widget.swimmerId,
        daysPerWeek: _daysPerWeek,
        weeks: _weeks,
        targetVolumeMin: _targetVolumeMin,
        targetVolumeMax: _targetVolumeMax,
        startDate: _startDate,
      );

      // 2. Clear previous goal schedules
      await repo.deleteGoalSchedule(goal.id);

      // 3. Save new schedule
      await repo.createScheduledWorkouts(workouts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule successfully built!')),
        );
        context.pop(); // Go back to goal detail
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Build Training Schedule', style: GoogleFonts.spaceGrotesk()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customize Your AI Schedule',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coach AI will map out a day-by-day training focus progression based on your goal.',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Start Date
            _buildSectionLabel('Start Date'),
            GestureDetector(
              onTap: _isGenerating ? null : _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                      style:
                          GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF0EA5E9)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Weeks
            _buildSectionLabel('Plan Duration ($_weeks weeks)'),
            Slider(
              value: _weeks.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              activeColor: const Color(0xFF0EA5E9),
              label: '$_weeks weeks',
              onChanged: _isGenerating
                  ? null
                  : (val) => setState(() => _weeks = val.toInt()),
            ),

            // Days per week
            _buildSectionLabel('Days per Week ($_daysPerWeek days)'),
            Slider(
              value: _daysPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              activeColor: const Color(0xFF0EA5E9),
              label: '$_daysPerWeek days',
              onChanged: _isGenerating
                  ? null
                  : (val) => setState(() => _daysPerWeek = val.toInt()),
            ),

            // Volume Sliders
            _buildSectionLabel('Target Volume Range/Practice'),
            RangeSlider(
              values: RangeValues(
                  _targetVolumeMin.toDouble(), _targetVolumeMax.toDouble()),
              min: 500,
              max: 10000,
              divisions: 95,
              activeColor: const Color(0xFF0EA5E9),
              labels:
                  RangeLabels('${_targetVolumeMin}y', '${_targetVolumeMax}y'),
              onChanged: _isGenerating
                  ? null
                  : (val) {
                      setState(() {
                        _targetVolumeMin = val.start.toInt();
                        _targetVolumeMax = val.end.toInt();
                      });
                    },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_targetVolumeMin yards',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                  Text('$_targetVolumeMax yards',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Generate Macro Plan',
                      style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
