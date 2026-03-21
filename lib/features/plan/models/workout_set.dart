class WorkoutSet {
  final String id;
  final int setNumber;
  final double? weight;   // kg — null until user enters it
  final int? reps;        // null until user enters it
  final int restSeconds;  // rest after this set in seconds
  final bool isWarmUp;    // warm up set vs working set
  final bool isCompleted;
  final bool isPersonalRecord; // PR flag — set by service layer

  const WorkoutSet({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    this.restSeconds = 90,
    this.isWarmUp = false,
    this.isCompleted = false,
    this.isPersonalRecord = false,
  });

  // Flutter immutable pattern — returns new instance with changed fields
  WorkoutSet copyWith({
    double? weight,
    int? reps,
    int? restSeconds,
    bool? isWarmUp,
    bool? isCompleted,
    bool? isPersonalRecord,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      isWarmUp: isWarmUp ?? this.isWarmUp,
      isCompleted: isCompleted ?? this.isCompleted,
      isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord,
    );
  }

  // Display helpers
  String get weightLabel =>
      weight != null ? '${weight!.toStringAsFixed(weight! % 1 == 0 ? 0 : 1)} kg' : '—';

  String get repsLabel =>
      reps != null ? '$reps reps' : '—';

  // Volume contribution — warm up sets don't count
  double get volumeKg =>
      isWarmUp ? 0 : (weight ?? 0) * (reps ?? 0);
}