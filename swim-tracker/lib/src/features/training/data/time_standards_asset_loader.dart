import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/time_standard.dart';

/// Loads USA Swimming motivational time standards from bundled time_standard.json.
/// Use this as the source of truth for Records so displayed standards match
/// the official 2024-2028 cuts (e.g. 13-14 F SCY 50 FR AAAA = 24.39).
class TimeStandardsAssetLoader {
  static const String _assetPath = 'time_standard.json';

  List<Map<String, dynamic>>? _groups;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final str = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(str) as Map<String, dynamic>;
    final groupsRaw = json['groups'] as List<dynamic>?;
    _groups = groupsRaw?.cast<Map<String, dynamic>>() ?? [];
    _loaded = true;
  }

  /// Map JSON event code to app event name, stroke, and distance.
  static ({String event, String stroke, int distance}) _parseEvent(String code) {
    final parts = code.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return (event: code, stroke: '', distance: 0);
    final distance = int.tryParse(parts[0]) ?? 0;
    final abbrev = parts.length > 1 ? parts[1].toUpperCase() : '';
    const map = {
      'FR': 'Free',
      'BK': 'Back',
      'BR': 'Breast',
      'FL': 'Fly',
      'IM': 'IM',
    };
    final stroke = map[abbrev] ?? abbrev;
    final eventName = '$distance $stroke';
    return (event: eventName, stroke: stroke, distance: distance);
  }

  /// Get standards for the given age group, course, and gender.
  /// [gender] should be 'F' or 'M' (normalize from 'Female'/'Girls' -> 'F', 'Male'/'Boys' -> 'M' before calling).
  Future<List<TimeStandard>> getStandards({
    required String gender,
    required String ageGroup,
    required String course,
  }) async {
    await _ensureLoaded();
    final g = _normalizeGender(gender);
    final ag = _normalizeAgeGroup(ageGroup);
    final list = <TimeStandard>[];
    for (final row in _groups!) {
      if ((row['gender'] as String? ?? '') != g) continue;
      if ((row['age_group'] as String? ?? '') != ag) continue;
      if ((row['course'] as String? ?? '') != course) continue;
      final eventCode = row['event'] as String? ?? '';
      final parsed = _parseEvent(eventCode);
      if (parsed.stroke.isEmpty) continue;
      for (final level in ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA']) {
        final time = row[level];
        if (time == null) continue;
        final seconds = (time is num) ? time.toDouble() : double.tryParse('$time');
        if (seconds == null) continue;
        list.add(TimeStandard(
          id: '',
          gender: g,
          ageGroup: ag,
          course: course,
          event: parsed.event,
          stroke: parsed.stroke,
          distance: parsed.distance,
          standardLevel: StandardLevel.fromString(level),
          timeSeconds: seconds,
          effectiveDate: null,
        ));
      }
    }
    return list;
  }

  String _normalizeGender(String v) {
    final lower = v.trim().toLowerCase();
    if (lower == 'f' || lower == 'female' || lower == 'girls') return 'F';
    if (lower == 'm' || lower == 'male' || lower == 'boys') return 'M';
    return v;
  }

  String _normalizeAgeGroup(String v) {
    const map = {
      '10 & under': '10 & Under',
      '10&u': '10 & Under',
      '11-12': '11-12',
      '13-14': '13-14',
      '15-16': '15-16',
      '17-18': '17-18',
      'Open': 'Open',
    };
    return map[v.trim()] ?? v;
  }
}
