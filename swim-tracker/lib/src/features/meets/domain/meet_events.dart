/// Standard meet events for each stroke and IM.
/// Used when adding meet entries and on the Records page.
/// Events are course-specific: SCY (short course yards) vs LCM (long course meters).
class MeetEvents {
  MeetEvents._();

  /// Ordered stroke names for UI (Free, Back, Breast, Fly, IM).
  static const List<String> strokeOrder = [
    'Free',
    'Back',
    'Breast',
    'Fly',
    'IM',
  ];

  /// Short course yards: Free has 500/1000/1650, no 400; IM includes 100.
  static const Map<String, List<int>> eventsByStrokeScy = {
    'Free': [50, 100, 200, 500, 800, 1000, 1500, 1650],
    'Back': [50, 100, 200],
    'Breast': [50, 100, 200],
    'Fly': [50, 100, 200],
    'IM': [100, 200, 400],
  };

  /// Long course meters: Free has 400/800/1500, no 500/1000/1650; no 100 IM.
  static const Map<String, List<int>> eventsByStrokeLcm = {
    'Free': [50, 100, 200, 400, 800, 1500],
    'Back': [50, 100, 200],
    'Breast': [50, 100, 200],
    'Fly': [50, 100, 200],
    'IM': [200, 400],
  };

  /// Stroke (or IM) -> list of distances for meet picker (union of SCY and LCM).
  static const Map<String, List<int>> eventsByStroke = {
    'Free': [50, 100, 200, 400, 500, 800, 1000, 1500, 1650],
    'Back': [50, 100, 200],
    'Breast': [50, 100, 200],
    'Fly': [50, 100, 200],
    'IM': [200, 400],
  };

  /// Event names for the given course in display order (by stroke, then distance).
  /// [course] is 'SCY' or 'LCM'.
  static List<String> eventNamesForCourse(String course) {
    final isScy = course.toUpperCase() == 'SCY';
    final map = isScy ? eventsByStrokeScy : eventsByStrokeLcm;
    final list = <String>[];
    for (final stroke in strokeOrder) {
      final distances = map[stroke];
      if (distances == null) continue;
      final sorted = List<int>.from(distances)..sort();
      for (final d in sorted) {
        list.add('$d $stroke');
      }
    }
    return list;
  }

  /// Events grouped by stroke for the given course.
  /// Returns map: stroke -> list of event names (e.g. "50 Free", "100 Free").
  static Map<String, List<String>> eventsByStrokeForCourse(String course) {
    final isScy = course.toUpperCase() == 'SCY';
    final map = isScy ? eventsByStrokeScy : eventsByStrokeLcm;
    final result = <String, List<String>>{};
    for (final stroke in strokeOrder) {
      final distances = map[stroke];
      if (distances == null) continue;
      final sorted = List<int>.from(distances)..sort();
      result[stroke] = sorted.map((d) => '$d $stroke').toList();
    }
    return result;
  }

  /// All event names (union of SCY and LCM) for meet add-entry picker.
  static List<String> get allEventNames {
    final list = <String>[];
    for (final stroke in strokeOrder) {
      final distances = eventsByStroke[stroke];
      if (distances == null) continue;
      final sorted = List<int>.from(distances)..sort();
      for (final d in sorted) {
        list.add('$d $stroke');
      }
    }
    return list;
  }
}
