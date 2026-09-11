class TimeStandard {
  final String id;
  final String gender;
  final String ageGroup;
  final String course;
  final String event;
  final String stroke;
  final int distance;
  final StandardLevel standardLevel;
  final double timeSeconds;
  final DateTime? effectiveDate;

  TimeStandard({
    required this.id,
    required this.gender,
    required this.ageGroup,
    required this.course,
    required this.event,
    required this.stroke,
    required this.distance,
    required this.standardLevel,
    required this.timeSeconds,
    this.effectiveDate,
  });

  factory TimeStandard.fromJson(Map<String, dynamic> json) {
    return TimeStandard(
      id: json['id'] as String,
      gender: json['gender'] as String,
      ageGroup: json['age_group'] as String,
      course: json['course'] as String,
      event: json['event'] as String,
      stroke: json['stroke'] as String,
      distance: json['distance'] as int,
      standardLevel: StandardLevel.fromString(json['standard_level'] as String),
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      effectiveDate: json['effective_date'] != null
          ? DateTime.parse(json['effective_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gender': gender,
      'age_group': ageGroup,
      'course': course,
      'event': event,
      'stroke': stroke,
      'distance': distance,
      'standard_level': standardLevel.value,
      'time_seconds': timeSeconds,
      'effective_date': effectiveDate?.toIso8601String().split('T')[0],
    };
  }

  String formatTime() {
    final minutes = (timeSeconds / 60).floor();
    final seconds = timeSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${seconds.toStringAsFixed(2)}s';
  }
}

enum StandardLevel {
  b('B'),
  bb('BB'),
  a('A'),
  aa('AA'),
  aaa('AAA'),
  aaaa('AAAA'),
  aaaaa('AAAAA');

  final String value;
  const StandardLevel(this.value);

  static StandardLevel fromString(String value) {
    return StandardLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StandardLevel.b,
    );
  }

  int get rank {
    switch (this) {
      case StandardLevel.b:
        return 1;
      case StandardLevel.bb:
        return 2;
      case StandardLevel.a:
        return 3;
      case StandardLevel.aa:
        return 4;
      case StandardLevel.aaa:
        return 5;
      case StandardLevel.aaaa:
        return 6;
      case StandardLevel.aaaaa:
        return 7;
    }
  }

  StandardLevel? get nextLevel {
    final currentRank = rank;
    if (currentRank >= 7) return null;
    return StandardLevel.values.firstWhere((e) => e.rank == currentRank + 1);
  }
}

/// USA Swimming national-level time standard (Sectional, Futures, Junior National, National).
/// Used alongside motivational B–AAAA on the Records bar when cut data is available.
class NationalTierStandard {
  final String id;
  final String name; // "Sectional", "Futures", "Junior National", "National"
  final double timeSeconds;

  NationalTierStandard({
    required this.id,
    required this.name,
    required this.timeSeconds,
  });
}

/// Known national-tier names for display order.
enum NationalTier {
  sectional('Sectional'),
  futures('Futures'),
  juniorNational('Junior National'),
  national('National');

  final String displayName;
  const NationalTier(this.displayName);
}

class SwimmerStandardInfo {
  final double currentTime;
  final StandardLevel? currentStandard;
  final StandardLevel? nextStandard;
  final double? timeToNextStandard;
  final String event;
  final String ageGroup;
  final String gender;
  final String course;

  SwimmerStandardInfo({
    required this.currentTime,
    this.currentStandard,
    this.nextStandard,
    this.timeToNextStandard,
    required this.event,
    required this.ageGroup,
    required this.gender,
    required this.course,
  });

  String get currentStandardDisplay => currentStandard?.value ?? 'Not Yet';
  String get nextStandardDisplay => nextStandard?.value ?? 'Max Achieved';

  bool get hasAchievedStandard => currentStandard != null;
  bool get canImprove => nextStandard != null;
}
