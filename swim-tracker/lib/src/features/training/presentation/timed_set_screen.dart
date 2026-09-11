import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/training_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_session.dart';
import '../domain/training_set_split_row.dart';

class SegmentDef {
  final int index;
  final String strokeLeg;
  final int distance;

  SegmentDef(
      {required this.index, required this.strokeLeg, required this.distance});
}

class RepState {
  final int repIndex;
  final Stopwatch stopwatch = Stopwatch();
  final List<double> segmentTimes = [];
  bool isFinished = false;

  double get accumulatedTime => segmentTimes.fold(0.0, (a, b) => a + b);

  RepState(this.repIndex);
}

/// Screen to do a set with an in-app stopwatch; record one time per rep (Split).
class TimedSetScreen extends ConsumerStatefulWidget {
  /// Set template (from recent set or search). Used for definition; a new set + splits will be saved.
  final TrainingSession setTemplate;

  /// Optional date for the logged set (e.g. when relogging from history). Defaults to now.
  final DateTime? trainingDate;

  const TimedSetScreen({
    super.key,
    required this.setTemplate,
    this.trainingDate,
  });

  @override
  ConsumerState<TimedSetScreen> createState() => _TimedSetScreenState();
}

class _TimedSetScreenState extends ConsumerState<TimedSetScreen> {
  late List<SegmentDef> _segments;
  late List<RepState> _reps;
  int? _activeRepIndex;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _segments = _generateSegments(widget.setTemplate);
    _reps = List.generate(widget.setTemplate.numberOfReps, (i) => RepState(i));
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  List<SegmentDef> _generateSegments(TrainingSession template) {
    final stroke = template.stroke;
    final distance = template.distancePerRep;
    if (stroke == 'IM') {
      if (distance % 4 == 0) {
        final legDist = distance ~/ 4;
        return [
          SegmentDef(index: 0, strokeLeg: 'Fly', distance: legDist),
          SegmentDef(index: 1, strokeLeg: 'Back', distance: legDist),
          SegmentDef(index: 2, strokeLeg: 'Breast', distance: legDist),
          SegmentDef(index: 3, strokeLeg: 'Free', distance: legDist),
        ];
      }
    }
    // Otherwise split by 50 if >= 50
    if (distance >= 50 && distance % 50 == 0) {
      final count = distance ~/ 50;
      return List.generate(
          count, (i) => SegmentDef(index: i, strokeLeg: stroke, distance: 50));
    }
    // Default 1 segment
    return [SegmentDef(index: 0, strokeLeg: stroke, distance: distance)];
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var rep in _reps) {
      rep.stopwatch.stop();
    }
    super.dispose();
  }

  void _startRep(int index) {
    if (_activeRepIndex != null && _activeRepIndex != index) {
      _reps[_activeRepIndex!].stopwatch.stop();
    }
    setState(() {
      _activeRepIndex = index;
      _reps[index].stopwatch.start();
    });
  }

  void _pauseActive() {
    if (_activeRepIndex != null) {
      _reps[_activeRepIndex!].stopwatch.stop();
      setState(() => _activeRepIndex = null);
    }
  }

  void _splitActive() {
    if (_activeRepIndex == null) return;
    final rep = _reps[_activeRepIndex!];
    final totalElapsed = rep.stopwatch.elapsedMilliseconds / 1000.0;
    final lap = totalElapsed - rep.accumulatedTime;

    rep.segmentTimes.add(lap);

    if (rep.segmentTimes.length >= _segments.length) {
      rep.stopwatch.stop();
      rep.isFinished = true;
      _activeRepIndex = null;
    }
    setState(() {});
  }

  Future<void> _done() async {
    _timer?.cancel();
    for (var rep in _reps) {
      rep.stopwatch.stop();
    }

    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (swimmerId == null || !mounted) return;

    final rows = <TrainingSetSplitRow>[];
    for (int i = 0; i < _reps.length; i++) {
      final rep = _reps[i];
      if (rep.segmentTimes.isEmpty) continue;

      if (_segments.length == 1) {
        rows.add(TrainingSetSplitRow(
          repNumber: i + 1,
          timeSeconds: rep.segmentTimes[0],
          distancePerSegment: _segments[0].distance,
          strokeLeg: _segments[0].strokeLeg,
        ));
      } else {
        for (int s = 0; s < rep.segmentTimes.length; s++) {
          final seg = _segments[s];
          rows.add(TrainingSetSplitRow(
            repNumber: i + 1,
            timeSeconds: rep.segmentTimes[s],
            segmentIndex: seg.index,
            strokeLeg: seg.strokeLeg,
            distancePerSegment: seg.distance,
          ));
        }
      }
    }

    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No splits recorded. Record at least one lap.')),
        );
      }
      return;
    }

    try {
      final repo = ref.read(trainingRepositoryProvider);

      final trainingDate = widget.trainingDate ?? DateTime.now();

      final practice = await repo.createPractice(
        swimmerId: swimmerId,
        practiceDate: trainingDate,
        name: widget.setTemplate.setDescription,
        teamId: widget.setTemplate.teamId,
      );

      final session = await repo.createTrainingSession(
        swimmerId: swimmerId,
        trainingDate: trainingDate,
        setDescription: widget.setTemplate.setDescription,
        stroke: widget.setTemplate.stroke,
        distancePerRep: widget.setTemplate.distancePerRep,
        numberOfReps: widget.setTemplate.numberOfReps,
        totalDistance: widget.setTemplate.totalDistance,
        restSeconds: widget.setTemplate.restSeconds,
        poolType: widget.setTemplate.poolType,
        intensity: widget.setTemplate.intensity,
        notes: widget.setTemplate.notes,
        teamId: widget.setTemplate.teamId,
        practiceId: practice.id,
      );
      await repo.createSplitsForSet(
        trainingSetId: session.id,
        swimmerId: swimmerId,
        splits: rows,
      );
      ref.invalidate(trainingSessionsProvider);
      ref.invalidate(recentSetsForSwimmerProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set and splits saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Widget _buildRepCard(int index) {
    final rep = _reps[index];
    final isRunning = rep.stopwatch.isRunning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rep ${index + 1}',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (rep.isFinished)
                  Text(_formatElapsed(rep.accumulatedTime),
                      style: GoogleFonts.spaceMono(
                          color: Colors.green, fontWeight: FontWeight.bold))
                else if (isRunning || rep.stopwatch.elapsedMilliseconds > 0)
                  Text(
                      _formatElapsed(
                          rep.stopwatch.elapsedMilliseconds / 1000.0),
                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold))
                else
                  Text('--:--',
                      style: GoogleFonts.spaceMono(color: Colors.grey)),
              ],
            ),
            if (!rep.isFinished) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!isRunning)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startRep(index),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(rep.stopwatch.elapsedMilliseconds > 0
                            ? 'Resume'
                            : 'Start'),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pauseActive,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _splitActive,
                        icon: const Icon(Icons.flag),
                        label: Text(
                            rep.segmentTimes.length == _segments.length - 1
                                ? 'Finish'
                                : 'Split'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (rep.segmentTimes.isNotEmpty || isRunning) ...[
              const SizedBox(height: 16),
              const Divider(),
              ...List.generate(_segments.length, (sIndex) {
                final seg = _segments[sIndex];
                final hasTime = sIndex < rep.segmentTimes.length;
                final isCurrent =
                    isRunning && sIndex == rep.segmentTimes.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${seg.distance}m ${seg.strokeLeg}',
                          style: GoogleFonts.outfit(
                              color: isCurrent
                                  ? const Color(0xFF0EA5E9)
                                  : (hasTime ? Colors.black : Colors.grey))),
                      Text(
                        hasTime
                            ? _formatElapsed(rep.segmentTimes[sIndex])
                            : (isCurrent
                                ? _formatElapsed(
                                    (rep.stopwatch.elapsedMilliseconds /
                                            1000.0) -
                                        rep.accumulatedTime)
                                : '--:--'),
                        style: GoogleFonts.spaceMono(
                            color: isCurrent
                                ? const Color(0xFF0EA5E9)
                                : (hasTime ? Colors.black : Colors.grey)),
                      )
                    ],
                  ),
                );
              }),
            ]
          ],
        ),
      ),
    );
  }

  String _formatElapsed(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00.00';
    final m = (seconds ~/ 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toStringAsFixed(2).padLeft(5, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reps = widget.setTemplate.numberOfReps;
    final hasRecorded = _reps.any((r) => r.segmentTimes.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.setTemplate.setDescription,
          style: GoogleFonts.outfit(),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              '${widget.setTemplate.stroke} · ${widget.setTemplate.distancePerRep}×$reps',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: reps,
                itemBuilder: (context, i) => _buildRepCard(i),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRecorded ? _done : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
                child: Text('Save Recorded Reps',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
