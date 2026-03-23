// lib/features/plan/models/workout_set.dart

class WorkoutSet {
  final String id;
  final int    setNumber;
  final int?   reps;
  final double? weight;
  final int?   restSeconds;
  final bool   isWarmUp;

  const WorkoutSet({
    required this.id,
    required this.setNumber,
    this.reps,
    this.weight,
    this.restSeconds,
    this.isWarmUp = false,
  });

  List<WorkoutSet> get warmUpSets  => [];
  List<WorkoutSet> get workingSets => [];
}