// lib/features/plan/services/plan_service.dart

import 'package:layz/features/plan/data/exercise_seed_data.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/models/workout_set.dart';

class PlanService {

  // ── Schedule ─────────────────────────────────────────────────────────────

  static List<ScheduleDay> getSchedule(String goal) {
    final splitType = SplitLabel.fromGoal(goal);
    return SplitGenerator.generate(splitType);
  }

  // ── Seed routine names for this goal ──────────────────────────────────────
  // Used by WeeklyScheduleScreen to list available seed routines.

  static List<String> seedRoutineNames(String goal) {
    final splitType = SplitLabel.fromGoal(goal);
    return SplitGenerator.routineNamesFor(splitType);
  }

  // ── Routines ──────────────────────────────────────────────────────────────

  static Routine? getRoutine({
    required String routineName,
    required String userId,
    required String goal,
  }) {
    final exerciseIds = ExerciseSeedData.exerciseIdsFor(routineName);
    if (exerciseIds.isEmpty) return null;

    final routineExercises = exerciseIds.asMap().entries.map((entry) {
      final index    = entry.key;
      final id       = entry.value;
      final exercise = ExerciseSeedData.findById(id);
      if (exercise == null) return null;

      return RoutineExercise(
        id:       '${routineName}_$id',
        exercise: exercise,
        order:    index,
        sets:     _buildDefaultSets(exercise, goal),
      );
    }).whereType<RoutineExercise>().toList();

    return Routine(
      id:          routineName.toLowerCase().replaceAll(' ', '_'),
      userId:      userId,
      name:        routineName,
      exercises:   routineExercises,
      createdAt:   DateTime.now(),
      isGenerated: true,
    );
  }

  // ── Sets builder ──────────────────────────────────────────────────────────

  static List<WorkoutSet> _buildDefaultSets(Exercise exercise, String goal) {
    final repRange  = exercise.repRangeFor(goal);
    final targetReps = repRange != null
        ? ((repRange.min + repRange.max) ~/ 2)
        : 12;

    final sets     = <WorkoutSet>[];
    final wsSets   = _workingSetCount(goal);
    final restSecs = _restSeconds(goal);
    int   setNum   = 1;

    // Warmup sets
    sets.add(WorkoutSet(
      id: '${exercise.id}_wu_1', setNumber: setNum++,
      reps: 15, restSeconds: 60, isWarmUp: true,
    ));
    sets.add(WorkoutSet(
      id: '${exercise.id}_wu_2', setNumber: setNum++,
      reps: 10, restSeconds: 60, isWarmUp: true,
    ));

    // Working sets
    for (int i = 1; i <= wsSets; i++) {
      sets.add(WorkoutSet(
        id: '${exercise.id}_ws_$i', setNumber: setNum++,
        reps: targetReps, restSeconds: restSecs, isWarmUp: false,
      ));
    }

    return sets;
  }

  static int _workingSetCount(String goal) {
    switch (goal) {
      case 'muscle': return 4;
      case 'lean':   return 3;
      case 'fit':    return 3;
      default:       return 3;
    }
  }

  static int _restSeconds(String goal) {
    switch (goal) {
      case 'muscle': return 90;
      case 'lean':   return 45;
      case 'fit':    return 60;
      default:       return 60;
    }
  }

  // ── Exercise library ──────────────────────────────────────────────────────

  static List<Exercise> getAllExercises()              => ExerciseSeedData.all;
  static List<Exercise> searchExercises(String query) => ExerciseSeedData.search(query);
  static List<Exercise> filterByMuscle(MuscleGroup m) => ExerciseSeedData.filterByMuscle(m);
  static List<Exercise> filterByEquipment(Equipment e)=> ExerciseSeedData.filterByEquipment(e);
  static List<Exercise> getSubstitutes(Exercise ex)   => ExerciseSeedData.substitutesFor(ex);

  // ── Weekly volume tracker ─────────────────────────────────────────────────

  static Map<MuscleGroup, int> getWeeklyVolume(String goal) {
    return { for (final m in MuscleGroup.values) m: 0 };
  }
}