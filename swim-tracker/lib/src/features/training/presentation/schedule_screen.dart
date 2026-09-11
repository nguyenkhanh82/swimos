import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/scheduled_workouts_repository.dart';
import '../data/swimmers_repository.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final swimmerIdAsync = ref.watch(selectedSwimmerIdProvider);

    return swimmerIdAsync.when(
      data: (swimmerId) {
        if (swimmerId == null) {
          return const Center(child: Text('No swimmer selected'));
        }

        // Fetch workouts for current week (Mon-Sun)
        final startOfWeek =
            _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        final workoutsAsync = ref.watch(scheduledWorkoutsProvider((
          swimmerId: swimmerId,
          startDate: startOfWeek,
          endDate: endOfWeek,
        )));

        return Column(
          children: [
            _buildWeekHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: workoutsAsync.when(
                data: (workouts) {
                  if (workouts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final w = workouts[index];
                      return Card(
                        color: Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(w.targetDate),
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              Text(
                                DateFormat('d').format(w.targetDate),
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          title: Text(w.focusArea,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0EA5E9))),
                          subtitle: Text(
                            w.notes ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: Colors.white70),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (w.targetDistance != null)
                                Text('${w.targetDistance}yds',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              if (w.targetDurationMinutes != null)
                                Text('${w.targetDurationMinutes}m',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildWeekHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(() =>
                _focusedDate = _focusedDate.subtract(const Duration(days: 7))),
          ),
          Text(
            'Week of ${DateFormat('MMM d').format(_focusedDate.subtract(Duration(days: _focusedDate.weekday - 1)))}',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => setState(
                () => _focusedDate = _focusedDate.add(const Duration(days: 7))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No Workouts Scheduled',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to a Goal to generate an AI macro plan.',
            style: GoogleFonts.outfit(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
