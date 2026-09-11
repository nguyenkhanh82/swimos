import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/nutrition_repository.dart';
import '../domain/daily_macro_target.dart';
import '../domain/nutrition_log.dart';
import '../../training/presentation/widgets/swimmer_selector_widget.dart';

class NutritionDashboardScreen extends ConsumerStatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  ConsumerState<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState
    extends ConsumerState<NutritionDashboardScreen> {
  DateTime _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Look back exactly 7 days
    final startDate = _now.subtract(const Duration(days: 6));
    final range = NutritionDateRange(startDate, _now);

    final targetAsync = ref.watch(nutritionTargetProvider);
    final logsAsync = ref.watch(nutritionLogsProvider(range));

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses App's global dark gradient
      appBar: AppBar(
        title: Text(
          'Nutrition Tracking',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SwimmerSelectorWidget(compact: true),
                    const SizedBox(height: 32),
                    logsAsync.when(
                      data: (logs) {
                        final target = targetAsync.valueOrNull ??
                            DailyMacroTarget(
                                id: '',
                                userId: '',
                                swimmerId: '',
                                updatedAt: DateTime.now());

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTodayProgress(logs, target),
                            const SizedBox(height: 32),
                            _buildHistoricalChart(logs, target),
                            const SizedBox(height: 32),
                            _buildRecentMeals(logs),
                            const SizedBox(height: 60), // FAB padding
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Center(
                          child: Text('Error: $err',
                              style: const TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0055FF)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              blurRadius: 15,
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/nutrition/log'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTodayProgress(List<NutritionLog> logs, DailyMacroTarget target) {
    // Filter to exactly today relative to _now
    final todayStr = _now.toIso8601String().split('T')[0];
    final todayLogs = logs
        .where((l) => l.logDate.toIso8601String().split('T')[0] == todayStr)
        .toList();

    int totalCals = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (var l in todayLogs) {
      totalCals += l.calories;
      totalProtein += l.protein;
      totalCarbs += l.carbs;
      totalFat += l.fat;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Today\'s Intake',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Calories Circle Overview
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: (totalCals / target.caloriesTarget).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalCals',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/ ${target.caloriesTarget} kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Macros horizontal bar splits
          _buildMacroRow(
              'Protein', totalProtein, target.proteinTarget, Colors.blueAccent),
          const SizedBox(height: 16),
          _buildMacroRow(
              'Carbs', totalCarbs, target.carbsTarget, Colors.orangeAccent),
          const SizedBox(height: 16),
          _buildMacroRow('Fat', totalFat, target.fatTarget, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, int current, int target, Color color) {
    final rawProgress = current / (target == 0 ? 1 : target);
    final isOver = rawProgress > 1.0;
    final displayProgress = rawProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
            Text('${current}g / ${target}g',
                style: GoogleFonts.outfit(
                    color: isOver ? Colors.redAccent : Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: displayProgress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.redAccent : color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalChart(
      List<NutritionLog> logs, DailyMacroTarget target) {
    // Generate values for exactly the last 7 days including today.
    final values = List.filled(7, 0.0);
    final days = <String>[];

    final startDate = _now.subtract(const Duration(days: 6));
    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      days.add(DateFormat('E').format(d));
    }

    // Accumulate logs by day offset
    for (final log in logs) {
      final date =
          DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      final rawStart = DateTime(startDate.year, startDate.month, startDate.day);
      final difference = date.difference(rawStart).inDays;
      if (difference >= 0 && difference < 7) {
        values[difference] += log.calories.toDouble();
      }
    }

    double maxY = target.caloriesTarget.toDouble() * 1.5;
    double maxLog = values.fold(0.0, (prev, val) => val > prev ? val : prev);
    if (maxLog > maxY) maxY = maxLog * 1.2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Calorie History',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} kcal',
                        GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: target.caloriesTarget.toDouble(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5]);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: values.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: entry.value > target.caloriesTarget
                            ? Colors.redAccent
                            : const Color(0xFF00E5FF),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeals(List<NutritionLog> logs) {
    if (logs.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            'Recent Meals',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          TextButton(
              onPressed: () {},
              child: Text('View All',
                  style: GoogleFonts.outfit(color: const Color(0xFF00E5FF))))
        ]),
        const SizedBox(height: 16),
        ...logs.take(5).map((log) => _buildMealCard(log)),
      ],
    );
  }

  Widget _buildMealCard(NutritionLog log) {
    final dateStr = DateFormat('MMM d').format(log.logDate);
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          if (log.imageUrl != null)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(log.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fastfood, color: Colors.white54),
            ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  log.mealType,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateStr,
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                )
              ]),
              const SizedBox(height: 4),
              Text(
                log.description ?? 'Logged Meal',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${log.calories} kcal • ${log.protein}g P • ${log.carbs}g C • ${log.fat}g F',
                style: GoogleFonts.outfit(
                    color: const Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              )
            ],
          ))
        ]));
  }
}
