import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/workout_set.dart';

// ── RoutineExercise — exercise inside a routine ────────────────────────────
// Junction between a Routine and an Exercise.
// Holds the sets, order, and any notes specific to this routine.

class RoutineExercise {
  final String id;
  final Exercise exercise;
  final int order;           // drag-to-reorder position
  final List<WorkoutSet> sets;
  final String? notes;       // optional coaching note

  const RoutineExercise({
    required this.id,
    required this.exercise,
    required this.order,
    required this.sets,
    this.notes,
  });

  // Warm up sets — auto-calculated, not stored
  List<WorkoutSet> get warmUpSets =>
      sets.where((s) => s.isWarmUp).toList();

  // Working sets — what counts for volume
  List<WorkoutSet> get workingSets =>
      sets.where((s) => !s.isWarmUp).toList();

  String get setsLabel {
    final wuCount = warmUpSets.length;
    final wsCount = workingSets.length;
    if (wuCount > 0) {
      return '$wuCount warm up · $wsCount sets';
    }
    return '$wsCount sets';
  }

  // Rep range label from first working set
  String get repRangeLabel {
    final ws = workingSets;
    if (ws.isEmpty) return '';
    final first = ws.first;
    // All working sets should have same rep target
    return '${first.reps ?? '—'} reps';
  }

  RoutineExercise copyWith({
    int? order,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return RoutineExercise(
      id: id,
      exercise: exercise,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}

// ── Routine ────────────────────────────────────────────────────────────────

class Routine {
  final String id;
  final String userId;
  final String name;           // "Push Day", "Pull Day" etc
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final bool isGenerated;      // true = auto-generated, false = user-created

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.exercises,
    required this.createdAt,
    this.isGenerated = false,
  });

  // Primary muscle groups in this routine
  List<MuscleGroup> get muscleGroups {
    final groups = <MuscleGroup>{};
    for (final re in exercises) {
      groups.addAll(re.exercise.primaryMuscles);
    }
    return groups.toList();
  }

  String get muscleGroupLabel =>
      muscleGroups.map((m) => m.label).join(' · ');

  // Rough estimate — 3 min per working set + 1 min per exercise for setup
  int get estimatedMinutes {
    int sets = 0;
    for (final re in exercises) {
      sets += re.workingSets.length;
    }
    return (sets * 3) + exercises.length;
  }

  String get estimatedLabel => '~${estimatedMinutes} min';

  int get exerciseCount => exercises.length;

  Routine copyWith({
    String? name,
    List<RoutineExercise>? exercises,
  }) {
    return Routine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
      isGenerated: isGenerated,
    );
  }
}