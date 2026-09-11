import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../training/data/time_standards_repository.dart';
import '../../training/data/swimmers_repository.dart';
import '../../training/data/training_goals_repository.dart';
import '../../training/domain/time_standard.dart';
import '../../training/domain/training_goal.dart';
import '../../meets/presentation/widgets/contextual_time_standards_bar.dart';
import '../../training/data/swim_times_sync_service.dart';
import '../../profile/data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  String? _selectedCourse = 'SCY';
  bool _isSyncing = false;
  int _refreshKey = 0;

  Future<void> _syncFromSwimCloud(String swimmerId) async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(swimTimesSyncServiceProvider);
      final success =
          await syncService.fetchSwimmerTimes(swimmerId, forceRefresh: true);
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _refreshKey++;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Swim times synced from SwimCloud. Records updated.'
                    : 'Sync completed. Make sure your swimmer has a SwimCloud ID set.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSwimmerIdAsync = ref.watch(selectedSwimmerIdProvider);

    final syncButton = selectedSwimmerIdAsync.whenOrNull(
      data: (swimmerId) => swimmerId == null
          ? null
          : IconButton(
              onPressed:
                  _isSyncing ? null : () => _syncFromSwimCloud(swimmerId),
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync from SwimCloud',
            ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Records', style: GoogleFonts.outfit()),
        centerTitle: true,
        actions: [
          if (syncButton != null) syncButton,
          // Course selector
          PopupMenuButton<String>(
            onSelected: (course) {
              setState(() {
                _selectedCourse = course;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'SCY', child: Text('Short Course Yards')),
              const PopupMenuItem(
                  value: 'LCM', child: Text('Long Course Meters')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pool, size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCourse ?? 'SCY',
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      body: selectedSwimmerIdAsync.when(
        data: (swimmerId) {
          if (swimmerId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'No swimmer selected',
                    style:
                        GoogleFonts.outfit(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select a swimmer to view their records',
                    style:
                        GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            );
          }
          return _RecordsList(
            key: ValueKey(
                'records_${swimmerId}_${_selectedCourse}_$_refreshKey'),
            swimmerId: swimmerId,
            course: _selectedCourse!,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading swimmer',
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordsList extends ConsumerStatefulWidget {
  final String swimmerId;
  final String course;

  const _RecordsList({
    super.key,
    required this.swimmerId,
    required this.course,
  });

  @override
  ConsumerState<_RecordsList> createState() => _RecordsListState();
}

class _RecordsListState extends ConsumerState<_RecordsList> {
  Map<String, List<EventRecord>>? _recordsByStroke;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didUpdateWidget(_RecordsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.swimmerId != widget.swimmerId ||
        oldWidget.course != widget.course) {
      debugPrint(
          '🔄 Widget updated: swimmerId=${widget.swimmerId}, course=${widget.course}');
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get swimmer info
      final swimmersRepo = ref.read(swimmersRepositoryProvider);
      final swimmer = await swimmersRepo.getSwimmerById(widget.swimmerId);

      if (swimmer == null) {
        debugPrint('❌ Swimmer not found');
        setState(() {
          _recordsByStroke = {};
          _isLoading = false;
        });
        return;
      }

      if (swimmer.gender == null || swimmer.birthDate == null) {
        debugPrint(
            '❌ Swimmer missing gender or birth_date: gender=${swimmer.gender}, birthDate=${swimmer.birthDate}');
        setState(() {
          _recordsByStroke = {};
          _isLoading = false;
        });
        return;
      }

      // Calculate age and age group for standards (motivational standards are driven by age)
      final age = _calculateAge(swimmer.birthDate!);
      final ageGroupForStandards =
          _getAgeGroupForStandards(age); // 10 & Under, 11-12, 13-14, etc.
      final genderRaw = swimmer.gender!;
      // Normalize gender for lookup: DB/JSON use F/M
      final gender = _normalizeGenderForStandards(genderRaw);

      debugPrint(
          '👤 Swimmer: ${swimmer.fullName}, age=$age, ageGroup=$ageGroupForStandards, gender=$gender (raw=$genderRaw)');

      // Use time_standards from database only (no JSON asset)
      final standardsRepo = ref.read(timeStandardsRepositoryProvider);
      final standardsForAge = await standardsRepo.getStandards(
        gender: gender,
        ageGroup: ageGroupForStandards,
        course: widget.course,
      );
      debugPrint(
          '📊 Using time_standards from DB: ${standardsForAge.length} standards');

      debugPrint(
          '🔍 Loading records for: gender=$gender, ageGroup=$ageGroupForStandards (age-driven), course=${widget.course}');

      // Build standards map from this age group only (age-driven)
      final standardsMap = <String, TimeStandard>{};
      for (final standard in standardsForAge) {
        final key =
            '${standard.stroke}_${standard.event}_${standard.standardLevel.value}';
        standardsMap[key] = standard;
      }
      final allStandards = standardsMap.values.toList();
      debugPrint(
          '📊 Using ${allStandards.length} time standards (age-driven: $ageGroupForStandards)');

      // Get swimmer's goals
      final goalsRepo = ref.read(trainingGoalsRepositoryProvider);
      final allGoals = await goalsRepo.getGoals(swimmerId: widget.swimmerId);
      final timeGoals = allGoals
          .where((g) =>
              g.goalType == GoalType.time &&
              g.isActive &&
              g.poolType == widget.course)
          .toList();

      // Get swimmer's best times: swim_times (synced) + meet_entries (meet results)
      final supabase = Supabase.instance.client;
      final bestTimesMap = <String, BestTimeInfo>{};

      // Normalize event name: "50  Free", "50 free", "50 FR" -> "50 Free"; "200 IM" / "200 im" -> "200 IM"
      String normalizeEventName(String s) {
        final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
        final parts = t.split(' ');
        if (parts.length >= 2) {
          final strokeRaw = parts.sublist(1).join(' ').toLowerCase();
          const abbrevToStroke = {
            'fr': 'Free',
            'free': 'Free',
            'bk': 'Back',
            'back': 'Back',
            'br': 'Breast',
            'breast': 'Breast',
            'fly': 'Fly',
            'fl': 'Fly',
            'im': 'IM',
          };
          final strokeTitle = abbrevToStroke[strokeRaw] ??
              (strokeRaw.isEmpty
                  ? strokeRaw
                  : '${strokeRaw[0].toUpperCase()}${strokeRaw.length > 1 ? strokeRaw.substring(1) : ''}');
          return '${parts[0]} $strokeTitle';
        }
        return t;
      }

      // 1) swim_times: fetch ALL for this swimmer (no pool_type filter), then filter in code
      void mergeSwimTime(Map<String, dynamic> time) {
        final raw = time['event_name'] as String?;
        if (raw == null || raw.isEmpty) return;
        final eventName = normalizeEventName(raw);
        final timeSeconds = (time['time_seconds'] as num?)?.toDouble();
        if (timeSeconds == null) return;
        final poolType = time['pool_type'] as String?;
        if (poolType != null && poolType != widget.course) return;
        if (!bestTimesMap.containsKey(eventName) ||
            bestTimesMap[eventName]!.timeSeconds > timeSeconds) {
          bestTimesMap[eventName] = BestTimeInfo(
            timeSeconds: timeSeconds,
            meetName: time['meet_name'] as String?,
            meetDate: time['meet_date'] as String?,
          );
        }
      }

      List<dynamic> toList(dynamic response) {
        if (response == null) return [];
        if (response is List) return response;
        try {
          final d = response as dynamic;
          if (d.data != null && d.data is List) return d.data as List;
        } catch (_) {}
        return [];
      }

      // --- DEBUG: swim_times fetch ---
      debugPrint(
          '🔍 DEBUG: Fetching swim_times for swimmer_id=${widget.swimmerId}');
      dynamic swimTimesRaw;
      try {
        swimTimesRaw = await supabase
            .from('swim_times')
            .select('event_name, time_seconds, pool_type, meet_name, meet_date')
            .eq('swimmer_id', widget.swimmerId)
            .order('time_seconds', ascending: true);
        debugPrint(
            '🔍 DEBUG: swim_times response type=${swimTimesRaw.runtimeType}');
        if (swimTimesRaw != null && swimTimesRaw is! List) {
          try {
            final d = swimTimesRaw as dynamic;
            if (d.data != null) {
              debugPrint(
                  '🔍 DEBUG: swim_times response.data length=${d.data is List ? (d.data as List).length : "N/A"}');
            }
          } catch (_) {}
        }
      } catch (e, stack) {
        debugPrint('❌ DEBUG: swim_times fetch error: $e');
        debugPrint('❌ DEBUG: stack: $stack');
        swimTimesRaw = null;
      }

      final swimTimesList = toList(swimTimesRaw);
      debugPrint(
          '📊 Records: swim_times raw count=${swimTimesList.length} for swimmer=${widget.swimmerId} course=${widget.course}');
      if (swimTimesList.isNotEmpty) {
        final first = swimTimesList.first;
        if (first is Map<String, dynamic>) {
          debugPrint(
              '🔍 DEBUG: swim_times first row keys=${first.keys.toList()} values=${first.values.map((v) => v?.toString()).toList()}');
        }
      } else {
        debugPrint(
            '🔍 DEBUG: swim_times returned empty list (no rows for this swimmer_id or RLS filtered all)');
      }

      for (final time in swimTimesList) {
        if (time is! Map<String, dynamic>) continue;
        mergeSwimTime(time);
      }
      debugPrint(
          '📊 Records: swim_times merged, ${bestTimesMap.length} best so far');

      // --- DEBUG: meet_entries fetch ---
      debugPrint(
          '🔍 DEBUG: Fetching meet_entries for swimmer_id=${widget.swimmerId}');
      dynamic meetEntriesResponse;
      try {
        meetEntriesResponse = await supabase
            .from('meet_entries')
            .select(
                'event_name, final_time_seconds, meet_id, swim_meets(meet_name, pool_type)')
            .eq('swimmer_id', widget.swimmerId)
            .not('final_time_seconds', 'is', null);
        debugPrint(
            '🔍 DEBUG: meet_entries response type=${meetEntriesResponse.runtimeType}');
        if (meetEntriesResponse != null && meetEntriesResponse is! List) {
          try {
            final d = meetEntriesResponse as dynamic;
            if (d.data != null) {
              debugPrint(
                  '🔍 DEBUG: meet_entries response.data length=${d.data is List ? (d.data as List).length : "N/A"}');
            }
          } catch (_) {}
        }
      } catch (e, stack) {
        debugPrint('⚠️ Records: meet_entries with join failed: $e');
        debugPrint('❌ DEBUG: meet_entries stack: $stack');
        try {
          meetEntriesResponse = await supabase
              .from('meet_entries')
              .select('event_name, final_time_seconds, meet_id')
              .eq('swimmer_id', widget.swimmerId)
              .not('final_time_seconds', 'is', null);
          debugPrint(
              '🔍 DEBUG: meet_entries fallback (no join) response type=${meetEntriesResponse.runtimeType}');
        } catch (e2) {
          debugPrint('❌ DEBUG: meet_entries fallback also failed: $e2');
          meetEntriesResponse = null;
        }
      }

      final meetEntriesList = toList(meetEntriesResponse);
      debugPrint(
          '📊 Records: loaded ${meetEntriesList.length} meet_entries with final time');
      if (meetEntriesList.isNotEmpty) {
        final first = meetEntriesList.first;
        if (first is Map<String, dynamic>) {
          debugPrint(
              '🔍 DEBUG: meet_entries first row keys=${first.keys.toList()}');
        }
      } else {
        debugPrint(
            '🔍 DEBUG: meet_entries returned empty (no rows or RLS filtered all)');
      }

      // DEBUG: Also check meet_entries via meet_ids (in case rows have null swimmer_id)
      if (meetEntriesList.isEmpty) {
        try {
          final meetsForSwimmer = await supabase
              .from('swim_meets')
              .select('id')
              .eq('swimmer_id', widget.swimmerId)
              .limit(5);
          final meetIds = toList(meetsForSwimmer);
          if (meetIds.isNotEmpty) {
            final firstMeet = meetIds.first;
            final meetId =
                firstMeet is Map ? (firstMeet)['id'] as String? : null;
            if (meetId != null) {
              final entriesForMeet = await supabase
                  .from('meet_entries')
                  .select('id, event_name, final_time_seconds, swimmer_id')
                  .eq('meet_id', meetId);
              final entriesList = toList(entriesForMeet);
              debugPrint(
                  '🔍 DEBUG: meet_entries for first meet $meetId: count=${entriesList.length}');
              if (entriesList.isNotEmpty &&
                  entriesList.first is Map<String, dynamic>) {
                final row = entriesList.first as Map<String, dynamic>;
                debugPrint(
                    '🔍 DEBUG: first entry swimmer_id=${row['swimmer_id']} event=${row['event_name']} final_time=${row['final_time_seconds']}');
              }
            }
          }
        } catch (e) {
          debugPrint('🔍 DEBUG: meet_entries-via-meet check failed: $e');
        }
      }

      for (final entry in meetEntriesList) {
        if (entry is! Map<String, dynamic>) continue;
        final timeSeconds = (entry['final_time_seconds'] as num?)?.toDouble();
        if (timeSeconds == null) continue;
        final raw = entry['event_name'] as String?;
        if (raw == null || raw.isEmpty) continue;
        final eventName = normalizeEventName(raw);
        final meet = entry['swim_meets'];
        String? meetName;
        String? poolType;
        if (meet is Map<String, dynamic>) {
          meetName = meet['meet_name'] as String?;
          poolType = meet['pool_type'] as String?;
        }
        // Include when course matches OR meet has no pool_type set (show for current course)
        if (poolType != null && poolType != widget.course) continue;
        if (!bestTimesMap.containsKey(eventName) ||
            bestTimesMap[eventName]!.timeSeconds > timeSeconds) {
          bestTimesMap[eventName] = BestTimeInfo(
            timeSeconds: timeSeconds,
            meetName: meetName,
            meetDate:
                null, // meet_entries join could add swim_meets.start_date later
          );
        }
      }
      debugPrint(
          '📊 Records: bestTimesMap has ${bestTimesMap.length} events with fastest time');

      // Group standards by stroke and event (from DB). Motivational only B–AAAA (not AAAAA).
      final standardsByStrokeAndEvent =
          <String, Map<String, List<TimeStandard>>>{};
      for (final standard in allStandards) {
        if (standard.standardLevel == StandardLevel.aaaaa) {
          continue; // Motivational stops at AAAA
        }
        final stroke = standard.stroke;
        if (stroke.isEmpty) {
          debugPrint(
              '⚠️ Warning: Standard has empty stroke: ${standard.event}');
          continue;
        }
        if (!standardsByStrokeAndEvent.containsKey(stroke)) {
          standardsByStrokeAndEvent[stroke] = {};
        }
        if (!standardsByStrokeAndEvent[stroke]!.containsKey(standard.event)) {
          standardsByStrokeAndEvent[stroke]![standard.event] = [];
        }
        standardsByStrokeAndEvent[stroke]![standard.event]!.add(standard);
      }

      // Sort standards within each event (from slowest to fastest)
      for (final strokeMap in standardsByStrokeAndEvent.values) {
        for (final standardsList in strokeMap.values) {
          standardsList.sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
        }
      }

      // Only display events the swimmer has a time for. Use best times to drive the list.
      final eventsWithTime = bestTimesMap.keys.toList();
      if (eventsWithTime.isEmpty) {
        if (mounted) {
          setState(() {
            _recordsByStroke = {};
            _isLoading = false;
          });
        }
        return;
      }

      // Load national-tier cuts (Sectional, Futures, etc.) for those events so cards can show e.g. "Sectional"
      final nationalTiersByEvent =
          await standardsRepo.getNationalTierStandardsByCourse(
        gender: gender,
        course: widget.course,
        use18AndUnder: age < 19,
      );

      // Group events by stroke (parse "50 Free" -> stroke "Free"), then sort by stroke order and distance
      final strokeOrder = ['Free', 'Back', 'Breast', 'Fly', 'IM'];
      final byStroke = <String, List<String>>{};
      for (final eventName in eventsWithTime) {
        final stroke = _strokeFromEventName(eventName);
        if (stroke.isEmpty) continue;
        byStroke.putIfAbsent(stroke, () => []).add(eventName);
      }
      for (final list in byStroke.values) {
        list.sort((a, b) {
          final dA = int.tryParse(a.split(' ').first) ?? 0;
          final dB = int.tryParse(b.split(' ').first) ?? 0;
          return dA.compareTo(dB);
        });
      }

      // Build records only for events the swimmer has a time for; pull standards for those events
      final recordsByStroke = <String, List<EventRecord>>{};
      for (final stroke in strokeOrder) {
        final eventNames = byStroke[stroke];
        if (eventNames == null || eventNames.isEmpty) continue;

        final records = <EventRecord>[];
        for (final eventName in eventNames) {
          final bestTimeInfo = bestTimesMap[eventName]!;
          final dbEvent = _displayEventToDbEvent(eventName);
          List<TimeStandard> standards = standardsByStrokeAndEvent[stroke]
                  ?[eventName] ??
              standardsByStrokeAndEvent[stroke]?[dbEvent] ??
              [];
          // Ensure ascending by time (fastest cut first: AAAA, ..., B) for correct "achieved" level.
          standards = List.from(standards)
            ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
          final nationalTiers = nationalTiersByEvent[dbEvent] ??
              nationalTiersByEvent[eventName] ??
              [];

          TrainingGoal? goal;
          final eventParts = eventName.split(' ');
          if (eventParts.length >= 2) {
            final distance = int.tryParse(eventParts[0]);
            final strokeName = eventParts.sublist(1).join(' ');
            final match = timeGoals.where((g) =>
                g.distance == distance &&
                g.stroke == strokeName &&
                g.poolType == widget.course);
            goal = match.isEmpty ? null : match.first;
          }

          records.add(EventRecord(
            eventName: eventName,
            stroke: stroke,
            standards: standards,
            nationalTierStandards: nationalTiers,
            swimmerBestTime: bestTimeInfo.timeSeconds,
            meetName: bestTimeInfo.meetName,
            meetDate: bestTimeInfo.meetDate,
            goal: goal,
          ));
        }
        recordsByStroke[stroke] = records;
      }

      debugPrint(
          '✅ Loaded ${recordsByStroke.length} stroke groups with ${recordsByStroke.values.fold(0, (sum, list) => sum + list.length)} events (only events with time)');
      debugPrint('📝 Records by stroke keys: ${recordsByStroke.keys.toList()}');
      for (final entry in recordsByStroke.entries) {
        debugPrint('  - ${entry.key}: ${entry.value.length} events');
      }

      if (mounted) {
        setState(() {
          _recordsByStroke = recordsByStroke;
          _isLoading = false;
        });
        debugPrint(
            '🔄 State updated, _recordsByStroke now has ${_recordsByStroke?.length ?? 0} strokes');
      } else {
        debugPrint('⚠️ Widget not mounted, skipping setState');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading records: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _recordsByStroke = {};
        _isLoading = false;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Age group value for time_standards (motivational standards are driven by age).
  /// Matches DB CHECK: '10 & Under', '11-12', '13-14', '15-16', '17-18', 'Open'.
  String _getAgeGroupForStandards(int age) {
    if (age <= 10) return '10 & Under';
    if (age < 13) return '11-12';
    if (age < 15) return '13-14';
    if (age < 17) return '15-16';
    if (age < 19) return '17-18';
    return 'Open';
  }

  /// Normalize swimmer gender to F/M for time standards lookup (DB uses F/M).
  String _normalizeGenderForStandards(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'f' || lower == 'female' || lower == 'girls') return 'F';
    if (lower == 'm' || lower == 'male' || lower == 'boys') return 'M';
    return raw;
  }

  /// Parse display event name "50 Free" -> stroke "Free".
  String _strokeFromEventName(String eventName) {
    final parts = eventName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return '';
    return parts.sublist(1).join(' ');
  }

  /// Map display event name to DB event code for time_standards lookup (e.g. "50 Free" -> "50 FR").
  String _displayEventToDbEvent(String eventName) {
    final parts = eventName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return eventName;
    const strokeToAbbrev = {
      'Free': 'FR',
      'Back': 'BK',
      'Breast': 'BR',
      'Fly': 'FL',
      'IM': 'IM',
    };
    final stroke = parts.sublist(1).join(' ');
    final abbrev = strokeToAbbrev[stroke] ?? stroke;
    return '${parts[0]} $abbrev';
  }

  /// Add "next goal" (time standard cut) as a training goal for this event.
  Future<void> _addNextGoalToTraining(
    BuildContext context,
    EventRecord record,
    double targetTimeSeconds,
    String standardLabel,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add goals')),
        );
      }
      return;
    }
    final parts = record.eventName.split(' ');
    if (parts.isEmpty) return;
    final distance = int.tryParse(parts.first);
    if (distance == null) return;
    try {
      final repository = ref.read(trainingGoalsRepositoryProvider);
      final defaultTeamId = await ref.read(defaultTeamIdProvider.future);
      final goal = TrainingGoal(
        id: '',
        userId: userId,
        swimmerId: widget.swimmerId,
        teamId: defaultTeamId,
        goalType: GoalType.time,
        title: '${record.eventName} - $standardLabel',
        description: 'Time standard goal from Records',
        stroke: record.stroke,
        distance: distance,
        poolType: widget.course,
        targetTimeSeconds: targetTimeSeconds,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        status: GoalStatus.active,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final createdGoal =
          await repository.createGoal(goal, swimmerId: widget.swimmerId);
      ref.invalidate(activeGoalsProvider);
      ref.invalidate(teamGoalsProvider(defaultTeamId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal added: ${record.eventName} - $standardLabel'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Navigate directly to the AI generated screen
        context.push('/training/goals/${createdGoal.id}/practice',
            extra: {'swimmerId': widget.swimmerId});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🔵 RecordsList build: isLoading=$_isLoading, recordsByStroke=${_recordsByStroke?.length ?? 'null'}');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recordsByStroke == null || _recordsByStroke!.isEmpty) {
      debugPrint(
          '⚠️ Showing empty state: _recordsByStroke is ${_recordsByStroke == null ? 'null' : 'empty'}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'No times recorded',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Record or sync times to see standards for your events',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    debugPrint(
        '✅ Building list with ${_recordsByStroke!.length} stroke groups');

    // Order strokes: Free, Back, Breast, Fly, IM
    final strokeOrder = ['Free', 'Back', 'Breast', 'Fly', 'IM'];
    final orderedStrokes =
        strokeOrder.where((s) => _recordsByStroke!.containsKey(s)).toList();
    orderedStrokes
        .addAll(_recordsByStroke!.keys.where((s) => !strokeOrder.contains(s)));

    debugPrint(
        '📋 Building ListView with ${orderedStrokes.length} strokes: $orderedStrokes');

    if (orderedStrokes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'No times recorded',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Record or sync times to see standards for your events',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderedStrokes.length,
      itemBuilder: (context, index) {
        final stroke = orderedStrokes[index];
        final records = _recordsByStroke![stroke]!;
        debugPrint(
            '🎨 Building stroke section: $stroke with ${records.length} events');
        return _StrokeSection(
          stroke: stroke,
          records: records,
          course: widget.course,
          swimmerId: widget.swimmerId,
          onAddNextGoal: (record, time, label) =>
              _addNextGoalToTraining(context, record, time, label),
        );
      },
    );
  }
}

class BestTimeInfo {
  final double timeSeconds;
  final String? meetName;
  final String? meetDate; // ISO date string (YYYY-MM-DD) when available

  BestTimeInfo({
    required this.timeSeconds,
    this.meetName,
    this.meetDate,
  });
}

class EventRecord {
  final String eventName;
  final String stroke;
  final List<TimeStandard> standards;

  /// National-level tiers (Sectional, Futures, Junior National, National) when cut data is available.
  final List<NationalTierStandard> nationalTierStandards;
  final double? swimmerBestTime;
  final String? meetName;
  final String? meetDate;
  final TrainingGoal? goal;

  EventRecord({
    required this.eventName,
    required this.stroke,
    required this.standards,
    List<NationalTierStandard>? nationalTierStandards,
    this.swimmerBestTime,
    this.meetName,
    this.meetDate,
    this.goal,
  }) : nationalTierStandards = nationalTierStandards ?? [];
}

/// Callback when user taps "Add as goal" on the time standards bar: (record, targetTimeSeconds, standardLabel).
typedef OnAddNextGoal = void Function(
    EventRecord record, double targetTimeSeconds, String standardLabel);

class _StrokeSection extends StatelessWidget {
  final String stroke;
  final List<EventRecord> records;
  final String course;
  final String swimmerId;
  final OnAddNextGoal? onAddNextGoal;

  const _StrokeSection({
    required this.stroke,
    required this.records,
    required this.course,
    required this.swimmerId,
    this.onAddNextGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stroke header with quick overview
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stroke.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Quick overview row
              Wrap(
                spacing: 16,
                children: records.map((record) {
                  if (record.swimmerBestTime == null) {
                    return const SizedBox.shrink();
                  }
                  final distance = record.eventName.split(' ').first;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        distance,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(record.swimmerBestTime!),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Individual event cards (expandable: Standards tab + Progress tab)
        ...records.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _EventRecordCard(
                record: record,
                course: course,
                swimmerId: swimmerId,
                onAddNextGoal: onAddNextGoal,
              ),
            )),
      ],
    );
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

class _EventRecordCard extends StatefulWidget {
  final EventRecord record;
  final String course;
  final String swimmerId;
  final OnAddNextGoal? onAddNextGoal;

  const _EventRecordCard({
    required this.record,
    required this.course,
    required this.swimmerId,
    this.onAddNextGoal,
  });

  @override
  State<_EventRecordCard> createState() => _EventRecordCardState();
}

class _EventRecordCardState extends State<_EventRecordCard>
    with SingleTickerProviderStateMixin {
  bool _detailsExpanded = false;
  late TabController _tabController;

  EventRecord get record => widget.record;
  String get course => widget.course;
  String get swimmerId => widget.swimmerId;
  OnAddNextGoal? get onAddNextGoal => widget.onAddNextGoal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${secs.toStringAsFixed(2)}s';
  }

  StandardLevel? _getCurrentStandard() {
    if (record.swimmerBestTime == null) return null;
    // Standards are sorted ascending by time (fastest cut first). Return the strictest cut the swimmer has achieved.
    for (final standard in record.standards) {
      if (record.swimmerBestTime! <= standard.timeSeconds) {
        return standard.standardLevel;
      }
    }
    return null;
  }

  /// Highest national tier achieved (Sectional, Futures, Junior National, National) when time meets cut.
  NationalTierStandard? _getAchievedNationalTier() {
    if (record.swimmerBestTime == null ||
        record.nationalTierStandards.isEmpty) {
      return null;
    }
    final time = record.swimmerBestTime!;
    // Tiers are ordered slowest (Sectional) to fastest (National). Take highest tier where time <= cut.
    NationalTierStandard? achieved;
    for (final tier in record.nationalTierStandards) {
      if (time <= tier.timeSeconds) achieved = tier;
    }
    return achieved;
  }

  /// Badge text: if qualified for national (Sectional, Futures, etc.) show only that; otherwise motivational (B–AAAA).
  String _currentStandardBadgeText(StandardLevel? currentStandard) {
    final achievedNational = _getAchievedNationalTier();
    if (achievedNational != null) {
      return achievedNational.name; // National only, e.g. "Sectional"
    }
    return currentStandard?.value ?? 'Below B';
  }

  /// True when swimmer time is faster than the fastest motivational cut (AAAA).
  bool _isFasterThanAllMotivational(EventRecord r) {
    if (r.swimmerBestTime == null || r.standards.isEmpty) return false;
    final fastestCut =
        r.standards.first.timeSeconds; // Ascending sort => first is AAAA
    return r.swimmerBestTime! < fastestCut;
  }

  Color _getStandardColor(StandardLevel level) {
    switch (level) {
      case StandardLevel.b:
      case StandardLevel.bb:
        return const Color(0xFF64748B); // Slate
      case StandardLevel.a:
        return const Color(0xFF3B82F6); // Blue
      case StandardLevel.aa:
        return const Color(0xFF22C55E); // Green
      case StandardLevel.aaa:
        return const Color(0xFFF59E0B); // Amber
      case StandardLevel.aaaa:
        return const Color(0xFFEF4444); // Red
      case StandardLevel.aaaaa:
        return const Color(0xFFDC2626); // Dark red
    }
  }

  Color _badgeColor(
      StandardLevel? currentStandard, NationalTierStandard? achievedNational) {
    if (currentStandard != null) return _getStandardColor(currentStandard);
    if (achievedNational != null) {
      return const Color(0xFF0EA5E9); // Primary-style for national tier
    }
    return Colors.grey;
  }

  /// If swimmer is faster than all motivational (AAAA), bar shows only national tiers; otherwise show both.
  List<TimeStandard> _barMotivationalStandards(EventRecord record) {
    if (_isFasterThanAllMotivational(record)) return [];
    return record.standards;
  }

  String _formatMeetDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final d = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStandard = _getCurrentStandard();
    final achievedNational = _getAchievedNationalTier();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event name (left) and best time + standard badge (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.eventName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (record.swimmerBestTime != null &&
                          (record.meetName != null ||
                              record.meetDate != null)) ...[
                        const SizedBox(height: 6),
                        if (record.meetName != null)
                          Row(
                            children: [
                              Icon(Icons.place_outlined,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  record.meetName!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (record.meetDate != null &&
                            record.meetDate!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  _formatMeetDate(record.meetDate),
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (record.swimmerBestTime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(record.swimmerBestTime!),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                      if (currentStandard != null ||
                          achievedNational != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _badgeColor(currentStandard, achievedNational)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentStandard != null
                                ? _currentStandardBadgeText(currentStandard)
                                : achievedNational!.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _badgeColor(
                                  currentStandard, achievedNational),
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Below B',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Text(
                    'No time recorded',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Contextual standards bar. If swimmer is faster than all motivational (AAAA), show only national tiers.
            if (record.swimmerBestTime != null)
              ContextualTimeStandardsBar(
                swimmerTime: record.swimmerBestTime!,
                standards: _barMotivationalStandards(record),
                nationalTierStandards: record.nationalTierStandards,
                onNextGoalTap: onAddNextGoal != null
                    ? (targetTimeSeconds, standardLabel) =>
                        onAddNextGoal!(record, targetTimeSeconds, standardLabel)
                    : null,
              )
            else
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No time recorded for this event',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            // Expandable: full time standards list + progress diagram
            if (record.swimmerBestTime != null) ...[
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      setState(() => _detailsExpanded = !_detailsExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _detailsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Time standards & progress',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_detailsExpanded) _buildDetailsWithTabs(),
            ],
            // Goal card at bottom
            if (record.goal != null &&
                record.goal!.targetTimeSeconds != null &&
                record.swimmerBestTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 20, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal: ${_formatTime(record.goal!.targetTimeSeconds!)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeToGo(record.swimmerBestTime!,
                                record.goal!.targetTimeSeconds!),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

  /// Tabbed expandable content: Standards tab + Progress tab.
  Widget _buildDetailsWithTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0EA5E9),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF0EA5E9),
            labelStyle:
                GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
            tabs: const [
              Tab(text: 'Standards'),
              Tab(text: 'Progress'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStandardsTab(),
                _buildProgressTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Standards tab: table-style layout (Standard | Time).
  Widget _buildStandardsTab() {
    final allCuts = <({String label, double time, bool isCurrent})>[];
    for (final s in record.standards) {
      allCuts.add((
        label: s.standardLevel.value,
        time: s.timeSeconds,
        isCurrent: false
      ));
    }
    for (final n in record.nationalTierStandards) {
      allCuts.add((label: n.name, time: n.timeSeconds, isCurrent: false));
    }

    if (record.swimmerBestTime != null) {
      final bestTime = record.swimmerBestTime!;
      allCuts.removeWhere((cut) => cut.time >= bestTime);
      allCuts.add((label: 'Current Best', time: bestTime, isCurrent: true));
    }

    allCuts.sort((a, b) => b.time.compareTo(a.time)); // slowest first

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Standard',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Time',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...allCuts.map((cut) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        cut.label,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight:
                              cut.isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: cut.isCurrent
                              ? const Color(0xFF0EA5E9)
                              : Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatTime(cut.time),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: cut.isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: cut.isCurrent
                              ? const Color(0xFF0EA5E9)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Progress tab: time history with standard achieved at each time.
  Widget _buildProgressTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTimeHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              snapshot.hasError ? 'Could not load history' : 'No times yet',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
            ),
          );
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No time history for this event',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final row = list[i];
            final timeSeconds =
                (row['time_seconds'] as num?)?.toDouble() ?? 0.0;
            final meetDate = row['meet_date'] as String?;
            final meetName = row['meet_name'] as String?;
            final standardLabel = _standardAchievedForTime(timeSeconds);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      _formatTime(timeSeconds),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meetDate != null && meetDate.isNotEmpty)
                          Text(
                            _formatMeetDate(meetDate),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        if (meetName != null && meetName.isNotEmpty)
                          Text(
                            meetName,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        Text(
                          standardLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTimeHistory() async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('swim_times')
        .select('time_seconds, meet_date, meet_name')
        .eq('swimmer_id', swimmerId)
        .eq('event_name', record.eventName)
        .eq('pool_type', course)
        .order('time_seconds', ascending: true);
    final list = res as List<dynamic>?;
    if (list == null) return [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Label for the strictest standard (or national tier) this time achieves; "Below B" if none.
  String _standardAchievedForTime(double timeSeconds) {
    // Motivational: strictest cut where time <= cut (standards sorted ascending = fastest first)
    for (final s in record.standards) {
      if (timeSeconds <= s.timeSeconds) return s.standardLevel.value;
    }
    // National tier
    NationalTierStandard? achieved;
    for (final tier in record.nationalTierStandards) {
      if (timeSeconds <= tier.timeSeconds) achieved = tier;
    }
    if (achieved != null) return achieved.name;
    return 'Below B';
  }

  String _formatTimeToGo(double currentSeconds, double goalSeconds) {
    final diff = currentSeconds - goalSeconds;
    if (diff <= 0) return 'Goal achieved!';
    return '~ ${_formatTime(diff)} to go';
  }
}
