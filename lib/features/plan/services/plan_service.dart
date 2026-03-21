import 'package:layz/features/plan/data/exercise_seed_data.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/models/workout_set.dart';

// ── PlanService ────────────────────────────────────────────────────────────
// Single source of truth for all plan data.
// Currently uses local seed data.
// TODO: replace each method body with Supabase calls when ready.
// The UI layer never changes — only this file.

class PlanService {

  // ── Schedule ─────────────────────────────────────────────────────────────

  // Returns the weekly schedule for a user.
  // For now — generates from split type based on goal.
  // Later — reads from Supabase weekly_schedule table.
  static List<ScheduleDay> getSchedule(String goal) {
    final splitType = SplitLabel.fromGoal(goal);
    return SplitGenerator.generate(splitType);
  }

  // ── Routines ──────────────────────────────────────────────────────────────

  // Returns the routine for a given routine name.
  // Builds it from seed data — sets are generated with sensible defaults.
  static Routine? getRoutine({
    required String routineName,
    required String userId,
    required String goal,
  }) {
    final exerciseIds = ExerciseSeedData.exerciseIdsFor(routineName);
    if (exerciseIds.isEmpty) return null;

    final routineExercises = exerciseIds.asMap().entries.map((entry) {
      final index = entry.key;
      final id = entry.value;
      final exercise = ExerciseSeedData.findById(id);
      if (exercise == null) return null;

      final sets = _buildDefaultSets(exercise, goal);

      return RoutineExercise(
        id: '${routineName}_${id}',
        exercise: exercise,
        order: index,
        sets: sets,
      );
    }).whereType<RoutineExercise>().toList();

    return Routine(
      id: routineName.toLowerCase().replaceAll(' ', '_'),
      userId: userId,
      name: routineName,
      exercises: routineExercises,
      createdAt: DateTime.now(),
      isGenerated: true,
    );
  }

  // ── Sets builder ──────────────────────────────────────────────────────────
  // Builds default sets for an exercise based on goal.
  // 2 warm up sets + working sets per goal.

  static List<WorkoutSet> _buildDefaultSets(Exercise exercise, String goal) {
    final repRange = exercise.repRangeFor(goal);
    final targetReps = repRange != null
        ? ((repRange.min + repRange.max) ~/ 2)
        : 12;

    final sets = <WorkoutSet>[];

    // Warm up sets — 2 always, lighter reps, not counted in volume
    sets.add(WorkoutSet(
      id: '${exercise.id}_wu_1',
      setNumber: 1,
      reps: 15,
      restSeconds: 60,
      isWarmUp: true,
    ));
    sets.add(WorkoutSet(
      id: '${exercise.id}_wu_2',
      setNumber: 2,
      reps: 10,
      restSeconds: 60,
      isWarmUp: true,
    ));

    // Working sets — count based on goal
    final workingSetCount = _workingSetCount(goal);
    final restSeconds = _restSeconds(goal);

    for (int i = 1; i <= workingSetCount; i++) {
      sets.add(WorkoutSet(
        id: '${exercise.id}_ws_$i',
        setNumber: i,
        reps: targetReps,
        restSeconds: restSeconds,
        isWarmUp: false,
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
      case 'muscle': return 90;  // heavy lifting needs more rest
      case 'lean':   return 45;  // shorter rest keeps heart rate up
      case 'fit':    return 60;
      default:       return 60;
    }
  }

  // ── Exercise library ──────────────────────────────────────────────────────

  static List<Exercise> getAllExercises() => ExerciseSeedData.all;

  static List<Exercise> searchExercises(String query) =>
      ExerciseSeedData.search(query);

  static List<Exercise> filterByMuscle(MuscleGroup muscle) =>
      ExerciseSeedData.filterByMuscle(muscle);

  static List<Exercise> filterByEquipment(Equipment equipment) =>
      ExerciseSeedData.filterByEquipment(equipment);

  static List<Exercise> getSubstitutes(Exercise exercise) =>
      ExerciseSeedData.substitutesFor(exercise);

  // ── Volume tracker ────────────────────────────────────────────────────────
  // Returns a map of muscle group → sets completed this week.
  // Used by the muscle volume bar widget.
  // TODO: query Supabase workout_logs when wired.

  static Map<MuscleGroup, int> getWeeklyVolume(String goal) {
    // Placeholder — returns zeros until real workout logging is wired
    return {
      for (final m in MuscleGroup.values) m: 0,
    };
  }
}