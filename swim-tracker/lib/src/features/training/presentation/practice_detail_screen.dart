import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/training_repository.dart';
import '../domain/practice.dart';

class PracticeDetailScreen extends ConsumerStatefulWidget {
  final String practiceId;

  const PracticeDetailScreen({super.key, required this.practiceId});

  @override
  ConsumerState<PracticeDetailScreen> createState() =>
      _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends ConsumerState<PracticeDetailScreen> {
  bool _isCloning = false;

  Future<void> _clonePractice(Practice practice) async {
    setState(() => _isCloning = true);
    try {
      final repo = ref.read(trainingRepositoryProvider);
      final newPractice = await repo.createPractice(
        swimmerId: practice.swimmerId,
        practiceDate: DateTime.now(),
        name: '${practice.name ?? "Practice"} (Copy)',
        teamId: practice.teamId,
        goalId: practice.goalId,
      );

      if (practice.sets != null) {
        for (var set in practice.sets!) {
          await repo.createTrainingSession(
            swimmerId: practice.swimmerId,
            trainingDate: DateTime.now(),
            setDescription: set.setDescription,
            stroke: set.stroke,
            distancePerRep: set.distancePerRep,
            numberOfReps: set.numberOfReps,
            totalDistance: set.totalDistance,
            restSeconds: set.restSeconds,
            poolType: set.poolType,
            intensity: set.intensity,
            notes: set.notes,
            teamId: practice.teamId,
            goalId: practice.goalId,
            practiceId: newPractice.id,
          );
        }
      }

      ref.invalidate(practicesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice repeated successfully!')));
      context.push('/training/practices/${newPractice.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error repeating practice: $e')));
    } finally {
      if (mounted) setState(() => _isCloning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We can fetch the practice from the provider
    final practicesAsync = ref.watch(practicesProvider);

    return practicesAsync.when(
      data: (practices) {
        final practice =
            practices.where((p) => p.id == widget.practiceId).firstOrNull;

        if (practice == null) {
          return Scaffold(
            appBar: AppBar(
                title: Text('Practice Details', style: GoogleFonts.outfit())),
            body: Center(
              child: Text('Practice not found',
                  style: GoogleFonts.outfit(fontSize: 16)),
            ),
          );
        }

        final sets = practice.sets ?? [];

        return Scaffold(
          appBar: AppBar(
            title:
                Text(practice.name ?? 'Practice', style: GoogleFonts.outfit()),
            actions: [
              if (_isCloning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Repeat this Practice',
                  onPressed: () => _clonePractice(practice),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  DateFormat.yMMMd().format(practice.practiceDate),
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Text('Sets in this Practice',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final set = sets[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2)),
                      ),
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
                                    '${index + 1}. ${set.setDescription}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (set.isMainSet)
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'log') {
                                        context.push('/training/relog-manual',
                                            extra: {
                                              'template': set,
                                              'trainingDate': DateTime.now(),
                                            });
                                      } else if (val == 'progress') {
                                        context.push('/training/set-progress',
                                            extra: set);
                                      } else if (val == 'timer') {
                                        context.push('/training/timed-set',
                                            extra: {
                                              'template': set,
                                              'trainingDate': DateTime.now(),
                                            });
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                          value: 'log',
                                          child: Text('Manual Log Time')),
                                      const PopupMenuItem(
                                          value: 'timer',
                                          child: Text('Do with Timer')),
                                      const PopupMenuItem(
                                          value: 'progress',
                                          child: Text('View Progress')),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${set.stroke} · ${set.distancePerRep}×${set.numberOfReps} · ${set.intensity}',
                              style:
                                  GoogleFonts.outfit(color: Colors.grey[600]),
                            ),
                            if (set.notes != null && set.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Notes: ${set.notes}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                            ] else ...[
                              const SizedBox(height: 12),
                            ],
                            InkWell(
                              onTap: () {
                                context.push('/training/exercise-drill',
                                    extra: set);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_circle_outline,
                                      size: 16, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 4),
                                  Text(
                                      set.stroke == 'Dryland'
                                          ? 'Watch Demo & Do Exercise'
                                          : 'Watch Demo & Do Drill',
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
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
            title: Text('Practice Details', style: GoogleFonts.outfit())),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
            title: Text('Practice Details', style: GoogleFonts.outfit())),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
