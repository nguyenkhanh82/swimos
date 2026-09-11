import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../training/domain/swimmer_profile.dart';
import '../../../training/domain/time_standard.dart';
import '../../../training/data/time_standards_repository.dart';
import 'time_standards_bar_widget.dart';

/// Widget that loads time standards and displays the bar for a specific event
class TimeStandardsBarForEvent extends ConsumerStatefulWidget {
  final String eventName;
  final double? swimmerTime;
  final SwimmerProfile swimmer;

  const TimeStandardsBarForEvent({
    super.key,
    required this.eventName,
    this.swimmerTime,
    required this.swimmer,
  });

  @override
  ConsumerState<TimeStandardsBarForEvent> createState() => _TimeStandardsBarForEventState();
}

class _TimeStandardsBarForEventState extends ConsumerState<TimeStandardsBarForEvent> {
  List<TimeStandard>? _standards;
  double? _bestTime;

  @override
  void initState() {
    super.initState();
    _loadStandards();
    _loadBestTime();
  }

  /// Age group for time_standards table. Matches DB: '10 & Under', '11-12', '13-14', '15-16', '17-18', 'Open'.
  static String _ageGroupForStandards(int age) {
    if (age <= 10) return '10 & Under';
    if (age < 13) return '11-12';
    if (age < 15) return '13-14';
    if (age < 17) return '15-16';
    if (age < 19) return '17-18';
    return 'Open';
  }

  /// Normalize gender to F/M for time_standards lookup.
  static String _normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return raw ?? 'M';
    final lower = raw.trim().toLowerCase();
    if (lower == 'f' || lower == 'female' || lower == 'girls') return 'F';
    if (lower == 'm' || lower == 'male' || lower == 'boys') return 'M';
    return raw;
  }

  Future<void> _loadStandards() async {
    if (widget.swimmer.gender == null || widget.swimmer.birthDate == null) {
      return;
    }

    final age = widget.swimmer.age;
    if (age == null) return;

    // Parse event name (e.g., "100 Free" -> distance: 100, stroke: "Free")
    final parts = widget.eventName.split(' ');
    if (parts.length < 2) return;

    final distance = int.tryParse(parts[0]);
    if (distance == null) return;

    // Get stroke name (everything after the distance)
    String stroke = parts.sublist(1).join(' ');
    // Normalize stroke names to match database format
    if (stroke.toLowerCase().contains('free')) {
      stroke = 'Free';
    } else if (stroke.toLowerCase().contains('back')) {
      stroke = 'Back';
    } else if (stroke.toLowerCase().contains('breast')) {
      stroke = 'Breast';
    } else if (stroke.toLowerCase().contains('fly') || stroke.toLowerCase().contains('butterfly')) {
      stroke = 'Fly';
    } else if (stroke.toLowerCase().contains('im') || stroke.toLowerCase().contains('individual medley')) {
      stroke = 'IM';
    }

    final ageGroup = _ageGroupForStandards(age);
    final gender = _normalizeGender(widget.swimmer.gender);

    // Determine course from pool type (default to SCY)
    const course = 'SCY'; // Can be enhanced to get from meet or swimmer preference

    try {
      final repository = ref.read(timeStandardsRepositoryProvider);
      final standards = await repository.getStandardsByStrokeDistance(
        gender: gender,
        ageGroup: ageGroup,
        stroke: stroke,
        distance: distance,
        course: course,
        motivationalOnly: true,
      );

      if (mounted) {
        setState(() {
          _standards = standards;
        });
      }
    } catch (e) {
      debugPrint('Error loading standards: $e');
    }
  }

  Future<void> _loadBestTime() async {
    if (widget.swimmerTime != null) {
      setState(() {
        _bestTime = widget.swimmerTime;
      });
      return;
    }

    // Parse event name to get best time from database
    final parts = widget.eventName.split(' ');
    if (parts.length < 2) return;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('swim_times')
          .select('time_seconds')
          .eq('swimmer_id', widget.swimmer.id)
          .eq('event_name', widget.eventName)
          .order('time_seconds', ascending: true)
          .limit(1)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _bestTime = (response['time_seconds'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading best time: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_standards == null || _standards!.isEmpty || _bestTime == null) {
      return const SizedBox.shrink();
    }

    return TimeStandardsBarWidget(
      swimmerTime: _bestTime!,
      standards: _standards!,
      eventName: widget.eventName,
    );
  }
}
