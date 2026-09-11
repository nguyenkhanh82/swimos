import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/training_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_session.dart';
import '../domain/training_set_split_row.dart';
import '../utils/interval_parser.dart';

/// Parse "1:02.50" or "62.5" to seconds.
double? _parseTime(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.length == 1) {
    return double.tryParse(parts[0].replaceAll(',', '.'));
  }
  if (parts.length == 2) {
    final m = int.tryParse(parts[0].trim());
    final sec = double.tryParse(parts[1].trim().replaceAll(',', '.'));
    if (m != null && sec != null) return m * 60 + sec;
  }
  return null;
}

/// Screen to enter lap/split times manually for a set (relog).
class RelogManualScreen extends ConsumerStatefulWidget {
  final TrainingSession setTemplate;
  final DateTime trainingDate;

  const RelogManualScreen({
    super.key,
    required this.setTemplate,
    required this.trainingDate,
  });

  @override
  ConsumerState<RelogManualScreen> createState() => _RelogManualScreenState();
}

class _RelogManualScreenState extends ConsumerState<RelogManualScreen> {
  late List<TextEditingController> _repControllers;
  late DateTime _selectedDate;
  bool _saving = false;
  int? _intervalSeconds;
  bool _isIntervalMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.trainingDate;
    _repControllers = List.generate(
      widget.setTemplate.numberOfReps,
      (_) => TextEditingController(),
    );

    // Parse interval notation to detect interval mode
    _intervalSeconds =
        IntervalParser.parseIntervalSeconds(widget.setTemplate.setDescription);
    _isIntervalMode = _intervalSeconds != null;
  }

  @override
  void dispose() {
    for (final c in _repControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatElapsed(double seconds) {
    final m = (seconds ~/ 60).floor();
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return s.toStringAsFixed(2);
  }

  Future<void> _showTimerSheet(int repIndex) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _RepTimerSheet(
        repNumber: repIndex + 1,
        intervalSeconds: _intervalSeconds,
        isIntervalMode: _isIntervalMode,
        distancePerRep: widget.setTemplate.distancePerRep,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _repControllers[repIndex].text = _formatElapsed(result);
      });
    }
  }

  Future<void> _save() async {
    final times = <int, double>{};
    for (var i = 0; i < _repControllers.length; i++) {
      final v = _parseTime(_repControllers[i].text);
      if (v == null || v <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Enter a valid time for Rep ${i + 1} (e.g. 1:02.50 or 62.5)')),
          );
        }
        return;
      }
      times[i + 1] = v;
    }

    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (swimmerId == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(trainingRepositoryProvider);

      // Create a new practice to hold this relogged set
      final practice = await repo.createPractice(
        swimmerId: swimmerId,
        practiceDate: _selectedDate,
        name: widget.setTemplate.setDescription,
        teamId: widget.setTemplate.teamId,
      );

      final session = await repo.createTrainingSession(
        swimmerId: swimmerId,
        trainingDate: _selectedDate,
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
        splits: times.entries
            .map((e) =>
                TrainingSetSplitRow(repNumber: e.key, timeSeconds: e.value))
            .toList(),
      );
      ref.invalidate(trainingSessionsProvider);
      ref.invalidate(recentSetsForSwimmerProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set and splits saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.setTemplate;
    final reps = template.numberOfReps;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log again: ${template.setDescription}',
          style: GoogleFonts.outfit(),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${template.stroke} · ${template.distancePerRep}×$reps',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: Text('Date',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                style: GoogleFonts.outfit(),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Tap each rep to record time',
              style:
                  GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Rep number buttons in a grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(reps, (i) {
                final hasTime = _repControllers[i].text.isNotEmpty;
                return InkWell(
                  onTap: () => _showTimerSheet(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: hasTime
                          ? const Color(0xFF0EA5E9).withAlpha(26)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasTime
                            ? const Color(0xFF0EA5E9)
                            : Colors.grey[300]!,
                        width: hasTime ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: hasTime
                                ? const Color(0xFF0EA5E9)
                                : Colors.grey[700],
                          ),
                        ),
                        if (hasTime) ...[
                          const SizedBox(height: 4),
                          Text(
                            _repControllers[i].text,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet with a stopwatch to time a single rep.
/// Supports interval mode with countdown and mid-rep splits.
class _RepTimerSheet extends StatefulWidget {
  final int repNumber;
  final int? intervalSeconds;
  final bool isIntervalMode;
  final int distancePerRep;

  const _RepTimerSheet({
    required this.repNumber,
    required this.intervalSeconds,
    required this.isIntervalMode,
    required this.distancePerRep,
  });

  @override
  State<_RepTimerSheet> createState() => _RepTimerSheetState();
}

class _RepTimerSheetState extends State<_RepTimerSheet> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<double> _splits = [];
  bool _running = false;
  bool _completed = false;
  double? _finalTime;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _start() {
    setState(() {
      _stopwatch.start();
      _running = true;
    });
  }

  void _pause() {
    setState(() {
      _stopwatch.stop();
      _running = false;
    });
  }

  void _reset() {
    setState(() {
      _stopwatch.reset();
      _stopwatch.stop();
      _running = false;
      _completed = false;
      _finalTime = null;
      _splits.clear();
    });
  }

  void _split() {
    if (!_stopwatch.isRunning) return;
    final elapsed = _stopwatch.elapsedMilliseconds / 1000.0;
    final previousTotal = _splits.fold<double>(0, (a, b) => a + b);
    final lap = elapsed - previousTotal;
    setState(() => _splits.add(lap));
  }

  void _done() {
    final elapsed = _stopwatch.elapsedMilliseconds / 1000.0;
    _stopwatch.stop();
    setState(() {
      _running = false;
      _completed = true;
      _finalTime = elapsed;
    });
  }

  void _confirmAndClose() {
    Navigator.of(context).pop(_finalTime);
  }

  String _formatElapsed(double seconds) {
    final m = (seconds ~/ 60).floor();
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return s.toStringAsFixed(2);
  }

  String _formatCountdown(double remainingSeconds) {
    if (remainingSeconds <= 0) return '+${_formatElapsed(-remainingSeconds)}';
    final m = (remainingSeconds ~/ 60).floor();
    final s = (remainingSeconds % 60).toInt();
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '$s';
  }

  Color _getCountdownColor(double remainingSeconds, int intervalSeconds) {
    if (remainingSeconds <= 0) return Colors.red;
    final ratio = remainingSeconds / intervalSeconds;
    if (ratio <= 0.1) return Colors.red;
    if (ratio <= 0.25) return Colors.orange;
    if (ratio <= 0.5) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsedMilliseconds / 1000.0;
    final hasInterval = widget.isIntervalMode && widget.intervalSeconds != null;
    final remaining = hasInterval ? widget.intervalSeconds! - elapsed : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timer - Rep ${widget.repNumber}',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            '${widget.distancePerRep}m',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Main timer display
          Center(
            child: Text(
              _formatElapsed(elapsed),
              style: GoogleFonts.spaceMono(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),

          // Countdown display (for interval mode)
          if (hasInterval && _running) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getCountdownColor(remaining!, widget.intervalSeconds!)
                      .withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      remaining <= 0 ? Icons.warning : Icons.timer,
                      size: 16,
                      color: _getCountdownColor(
                          remaining, widget.intervalSeconds!),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      remaining <= 0 ? 'Over time' : 'Next interval in',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _getCountdownColor(
                            remaining, widget.intervalSeconds!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCountdown(remaining),
                      style: GoogleFonts.spaceMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCountdownColor(
                            remaining, widget.intervalSeconds!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Splits list
          if (_splits.isNotEmpty) ...[
            Text(
              'Splits',
              style:
                  GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _splits.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split ${index + 1}',
                          style: GoogleFonts.outfit(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          _formatElapsed(_splits[index]),
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control buttons
          if (_completed) ...[
            // Show final time and confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Final Time',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatElapsed(_finalTime!),
                    style: GoogleFonts.spaceMono(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: Text('Reset', style: GoogleFonts.outfit()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirmAndClose,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9)),
                    child: Text('Use Time',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Normal control buttons
            Row(
              children: [
                if (!_running && _stopwatch.elapsedMilliseconds > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: Text('Reset', style: GoogleFonts.outfit()),
                    ),
                  ),
                if (!_running && _stopwatch.elapsedMilliseconds > 0)
                  const SizedBox(width: 12),
                Expanded(
                  child: _running
                      ? OutlinedButton(
                          onPressed: _pause,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: Text('Pause',
                              style: GoogleFonts.outfit(color: Colors.orange)),
                        )
                      : FilledButton(
                          onPressed: _start,
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: Text(
                            _stopwatch.elapsedMilliseconds > 0
                                ? 'Resume'
                                : 'Start',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _running ? _split : null,
                    child: Text('Split', style: GoogleFonts.outfit()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _stopwatch.elapsedMilliseconds > 0 ? _done : null,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9)),
                    child: Text('Done',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
