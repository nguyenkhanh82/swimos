import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/training_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_session.dart';

/// One data point for the progress chart: date and average split time (seconds).
class SetProgressPoint {
  final DateTime date;
  final double avgTimeSeconds;

  const SetProgressPoint({required this.date, required this.avgTimeSeconds});
}

/// Fetches all sessions matching the set and their splits, returns (date, avg time) for sessions that have splits.
Future<List<SetProgressPoint>> _loadProgressPoints({
  required TrainingRepository repo,
  required String swimmerId,
  required TrainingSession template,
  required DateTime from,
  required DateTime to,
}) async {
  final sessions = await repo.getSessionsForSetSignature(
    swimmerId: swimmerId,
    setDescription: template.setDescription,
    stroke: template.stroke,
    distancePerRep: template.distancePerRep,
    numberOfReps: template.numberOfReps,
    from: from,
    to: to,
  );
  final points = <SetProgressPoint>[];
  for (final session in sessions) {
    final splits = await repo.getSplitsForSet(session.id);
    if (splits.isEmpty) continue;
    final avg = splits.fold<double>(0, (s, e) => s + e.timeSeconds) / splits.length;
    points.add(SetProgressPoint(
      date: session.trainingDate,
      avgTimeSeconds: avg,
    ));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

String _formatTime(double seconds) {
  final m = (seconds ~/ 60).floor();
  final s = seconds % 60;
  if (m > 0) {
    return '$m:${s.toStringAsFixed(1).padLeft(4, "0")}';
  }
  return s.toStringAsFixed(1);
}

/// Screen showing progress for one set over time (line chart: date vs average split time).
class SetProgressScreen extends ConsumerStatefulWidget {
  final TrainingSession setTemplate;

  const SetProgressScreen({
    super.key,
    required this.setTemplate,
  });

  @override
  ConsumerState<SetProgressScreen> createState() => _SetProgressScreenState();
}

class _SetProgressScreenState extends ConsumerState<SetProgressScreen> {
  List<SetProgressPoint>? _points;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final swimmerId = await ref.read(selectedSwimmerIdProvider.future);
    if (swimmerId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Select a swimmer first';
        });
      }
      return;
    }
    final now = DateTime.now();
    final from = DateTime(now.year - 1, now.month, now.day);
    final to = now;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(trainingRepositoryProvider);
      final points = await _loadProgressPoints(
        repo: repo,
        swimmerId: swimmerId,
        template: widget.setTemplate,
        from: from,
        to: to,
      );
      if (mounted) {
        setState(() {
          _points = points;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.setTemplate;
    final points = _points ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set progress',
          style: GoogleFonts.outfit(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: GoogleFonts.outfit(color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : points.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No timed sessions yet',
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Relog this set with the timer to see progress over time.',
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            template.setDescription,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${template.stroke} · ${template.distancePerRep}×${template.numberOfReps} · Avg split',
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          _buildChart(points),
                          const SizedBox(height: 24),
                          Text(
                            'By date',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ...points.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat.yMMMd().format(p.date),
                                      style: GoogleFonts.outfit(color: Colors.grey[700]),
                                    ),
                                    Text(
                                      _formatTime(p.avgTimeSeconds),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0EA5E9),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildChart(List<SetProgressPoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();
    final minY = points.map((p) => p.avgTimeSeconds).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.avgTimeSeconds).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = (range > 0 ? range * 0.1 : 1) + 0.5;
    final yMin = (minY - padding).clamp(0.0, double.infinity);
    final yMax = maxY + padding;

    final spots = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.avgTimeSeconds)).toList();
    final maxX = points.length > 1 ? (points.length - 1).toDouble() : 1.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 8, top: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: yMin,
          maxY: yMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0EA5E9),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF0EA5E9),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: true, color: Color.lerp(const Color(0xFF0EA5E9), Colors.white, 0.85)!),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.Md().format(points[i].date),
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatTime(value),
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final i = s.x.toInt();
                if (i < 0 || i >= points.length) return null;
                final p = points[i];
                return LineTooltipItem(
                  '${DateFormat.yMMMd().format(p.date)}\n${_formatTime(p.avgTimeSeconds)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                );
              }).toList(),
              tooltipBgColor: const Color(0xFF0F172A),
              tooltipRoundedRadius: 8,
            ),
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
