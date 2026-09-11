/// One row from training_set_splits (for display / history).
class TrainingSetSplit {
  final String id;
  final int repNumber;
  final double timeSeconds;
  final int? segmentIndex;
  final String? strokeLeg;
  final int? distancePerSegment;

  const TrainingSetSplit({
    required this.id,
    required this.repNumber,
    required this.timeSeconds,
    this.segmentIndex,
    this.strokeLeg,
    this.distancePerSegment,
  });

  factory TrainingSetSplit.fromJson(Map<String, dynamic> json) {
    return TrainingSetSplit(
      id: json['id'] as String,
      repNumber: json['rep_number'] as int,
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      segmentIndex: json['segment_index'] as int?,
      strokeLeg: json['stroke_leg'] as String?,
      distancePerSegment: json['distance_per_segment'] as int?,
    );
  }
}
