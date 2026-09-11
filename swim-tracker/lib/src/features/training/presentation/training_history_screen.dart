import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/training_repository.dart';
import '../domain/practice.dart';
import '../domain/team.dart';
import '../data/teams_repository.dart';
import 'filters/training_filters.dart';

class TrainingHistoryScreen extends ConsumerStatefulWidget {
  final List<String> selectedTeamIds;
  final String? filterGoalId;

  const TrainingHistoryScreen({
    super.key,
    required this.selectedTeamIds,
    this.filterGoalId,
  });

  @override
  ConsumerState<TrainingHistoryScreen> createState() =>
      _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends ConsumerState<TrainingHistoryScreen> {
  String? _filterTeamId;
  String? _filterStroke;
  int? _filterDistance;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Future<void> _deletePractice(Practice practice) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Practice',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to delete this entire practice and all its sets?',
                style: GoogleFonts.outfit()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete',
                    style: GoogleFonts.outfit(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final repo = ref.read(trainingRepositoryProvider);
      await repo.deletePractice(practice.id);
      ref.invalidate(practicesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Practice deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting practice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final practicesAsync = ref.watch(practicesProvider);
    final teamsAsync = ref.watch(teamsListProvider);

    return Column(
      children: [
        // Filters
        TrainingFilters(
          selectedTeamId: _filterTeamId,
          selectedStroke: _filterStroke,
          selectedDistance: _filterDistance,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
          onFiltersChanged: (teamId, stroke, distance, startDate, endDate) {
            setState(() {
              _filterTeamId = teamId;
              _filterStroke = stroke;
              _filterDistance = distance;
              _filterStartDate = startDate;
              _filterEndDate = endDate;
            });
          },
        ),

        // Practices List
        Expanded(
          child: practicesAsync.when(
            data: (practices) {
              var filteredPractices = practices;

              if (widget.selectedTeamIds.isNotEmpty) {
                filteredPractices = filteredPractices
                    .where((p) =>
                        p.teamId == null ||
                        widget.selectedTeamIds.contains(p.teamId))
                    .toList();
              }
              if (_filterTeamId != null) {
                filteredPractices = filteredPractices
                    .where((p) => p.teamId == _filterTeamId)
                    .toList();
              }
              if (widget.filterGoalId != null) {
                filteredPractices = filteredPractices
                    .where((p) => p.goalId == widget.filterGoalId)
                    .toList();
              }
              if (_filterStartDate != null) {
                filteredPractices = filteredPractices
                    .where((p) => p.practiceDate.isAfter(
                        _filterStartDate!.subtract(const Duration(days: 1))))
                    .toList();
              }
              if (_filterEndDate != null) {
                filteredPractices = filteredPractices
                    .where((p) => p.practiceDate
                        .isBefore(_filterEndDate!.add(const Duration(days: 1))))
                    .toList();
              }

              // Set-level filtering (only show practices that contain a matching set if filtered by stroke/distance)
              if (_filterStroke != null || _filterDistance != null) {
                filteredPractices = filteredPractices.where((p) {
                  if (p.sets == null || p.sets!.isEmpty) return false;
                  return p.sets!.any((set) {
                    bool match = true;
                    if (_filterStroke != null && set.stroke != _filterStroke) {
                      match = false;
                    }
                    if (_filterDistance != null &&
                        set.distancePerRep != _filterDistance) {
                      match = false;
                    }
                    return match;
                  });
                }).toList();
              }

              if (filteredPractices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pool, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      Text('No practices found',
                          style: GoogleFonts.outfit(color: Colors.white54)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredPractices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final practice = filteredPractices[index];
                  Team? team;
                  if (practice.teamId != null && teamsAsync.value != null) {
                    team = teamsAsync.value!
                        .where((t) => t.id == practice.teamId)
                        .firstOrNull;
                  }

                  final totalYards = practice.sets
                          ?.fold(0, (sum, set) => sum + set.totalDistance) ??
                      0;
                  final setCount = practice.sets?.length ?? 0;

                  return InkWell(
                    onTap: () =>
                        context.push('/training/practices/${practice.id}'),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
                                    practice.name ?? 'Practice',
                                    style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'delete') {
                                      _deletePractice(practice);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Practice',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat.yMMMd()
                                      .format(practice.practiceDate),
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.waves,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalYards yds · $setCount sets',
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (team != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.group,
                                        size: 12, color: Color(0xFF00E5FF)),
                                    const SizedBox(width: 4),
                                    Text(team.name,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: const Color(0xFF00E5FF),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
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
  }
}
