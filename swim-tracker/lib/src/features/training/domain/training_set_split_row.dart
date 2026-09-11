/// One timed segment to insert into training_set_splits (per rep or per segment).
class TrainingSetSplitRow {
  final int repNumber;
  final double timeSeconds;
  final int? segmentIndex;
  final String? strokeLeg;
  final int? distancePerSegment;

  const TrainingSetSplitRow({
    required this.repNumber,
    required this.timeSeconds,
    this.segmentIndex,
    this.strokeLeg,
    this.distancePerSegment,
  });
}
