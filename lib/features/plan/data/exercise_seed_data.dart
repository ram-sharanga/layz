// lib/features/plan/data/exercise_seed_data.dart

import '../models/exercise.dart';

class ExerciseSeedData {
  ExerciseSeedData._();

  // ── Exercises ─────────────────────────────────────────────────────────────

  static const List<Exercise> all = [
    // ── CHEST ──────────────────────────────────────────────────────────────
    Exercise(
      id: 'barbell_bench_press', name: 'Barbell Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      description: 'The king of chest exercises. Lie flat, grip wider than shoulder-width, lower bar to chest.',
      substitutes: ['dumbbell_bench_press', 'push_up'],
    ),
    Exercise(
      id: 'dumbbell_bench_press', name: 'Dumbbell Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['barbell_bench_press', 'push_up'],
    ),
    Exercise(
      id: 'incline_bench_press', name: 'Incline Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      substitutes: ['incline_dumbbell_press', 'cable_fly'],
    ),
    Exercise(
      id: 'incline_dumbbell_press', name: 'Incline Dumbbell Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders],
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['incline_bench_press'],
    ),
    Exercise(
      id: 'cable_fly', name: 'Cable Fly',
      primaryMuscle: MuscleGroup.chest,
      equipment: Equipment.cable, difficulty: Difficulty.intermediate,
      substitutes: ['dumbbell_fly'],
    ),
    Exercise(
      id: 'dumbbell_fly', name: 'Dumbbell Fly',
      primaryMuscle: MuscleGroup.chest,
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['cable_fly'],
    ),
    Exercise(
      id: 'push_up', name: 'Push-Up',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.core],
      equipment: Equipment.bodyweight, difficulty: Difficulty.beginner,
      substitutes: ['dumbbell_bench_press'],
    ),
    Exercise(
      id: 'chest_dip', name: 'Chest Dip',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.bodyweight, difficulty: Difficulty.intermediate,
      substitutes: ['cable_fly'],
    ),

    // ── BACK ───────────────────────────────────────────────────────────────
    Exercise(
      id: 'barbell_deadlift', name: 'Barbell Deadlift',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.legs, MuscleGroup.core],
      equipment: Equipment.barbell, difficulty: Difficulty.advanced,
      description: 'Pull the bar from the floor, hips hinge, back straight. Full posterior chain.',
      substitutes: ['romanian_deadlift', 'rack_pull'],
    ),
    Exercise(
      id: 'romanian_deadlift', name: 'Romanian Deadlift',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.legs],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      substitutes: ['barbell_deadlift', 'good_morning'],
    ),
    Exercise(
      id: 'barbell_row', name: 'Barbell Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      substitutes: ['dumbbell_row', 'cable_row'],
    ),
    Exercise(
      id: 'dumbbell_row', name: 'Dumbbell Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['barbell_row', 'cable_row'],
    ),
    Exercise(
      id: 'lat_pulldown', name: 'Lat Pulldown',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['pull_up', 'cable_row'],
    ),
    Exercise(
      id: 'pull_up', name: 'Pull-Up',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.core],
      equipment: Equipment.bodyweight, difficulty: Difficulty.intermediate,
      substitutes: ['lat_pulldown'],
    ),
    Exercise(
      id: 'cable_row', name: 'Cable Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['barbell_row', 'dumbbell_row'],
    ),
    Exercise(
      id: 'rack_pull', name: 'Rack Pull',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      substitutes: ['barbell_deadlift'],
    ),

    // ── SHOULDERS ──────────────────────────────────────────────────────────
    Exercise(
      id: 'overhead_press', name: 'Overhead Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.core],
      equipment: Equipment.barbell, difficulty: Difficulty.intermediate,
      substitutes: ['dumbbell_shoulder_press', 'arnold_press'],
    ),
    Exercise(
      id: 'dumbbell_shoulder_press', name: 'Dumbbell Shoulder Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['overhead_press', 'arnold_press'],
    ),
    Exercise(
      id: 'lateral_raise', name: 'Lateral Raise',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['cable_lateral_raise'],
    ),
    Exercise(
      id: 'cable_lateral_raise', name: 'Cable Lateral Raise',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['lateral_raise'],
    ),
    Exercise(
      id: 'face_pull', name: 'Face Pull',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.back],
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['rear_delt_fly'],
    ),
    Exercise(
      id: 'arnold_press', name: 'Arnold Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell, difficulty: Difficulty.intermediate,
      substitutes: ['dumbbell_shoulder_press'],
    ),

    // ── LEGS ───────────────────────────────────────────────────────────────
    Exercise(
      id: 'barbell_squat', name: 'Barbell Squat',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.core],
      equipment: Equipment.barbell, difficulty: Difficulty.advanced,
      description: 'High bar squat. Break at hips and knees simultaneously, depth below parallel.',
      substitutes: ['goblet_squat', 'leg_press'],
    ),
    Exercise(
      id: 'leg_press', name: 'Leg Press',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.machine, difficulty: Difficulty.beginner,
      substitutes: ['barbell_squat', 'goblet_squat'],
    ),
    Exercise(
      id: 'goblet_squat', name: 'Goblet Squat',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.core],
      equipment: Equipment.kettlebell, difficulty: Difficulty.beginner,
      substitutes: ['barbell_squat'],
    ),
    Exercise(
      id: 'leg_extension', name: 'Leg Extension',
      primaryMuscle: MuscleGroup.legs,
      equipment: Equipment.machine, difficulty: Difficulty.beginner,
      substitutes: ['barbell_squat'],
    ),
    Exercise(
      id: 'leg_curl', name: 'Leg Curl',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.machine, difficulty: Difficulty.beginner,
      substitutes: ['romanian_deadlift'],
    ),
    Exercise(
      id: 'walking_lunge', name: 'Walking Lunge',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.core],
      equipment: Equipment.dumbbell, difficulty: Difficulty.intermediate,
      substitutes: ['split_squat'],
    ),
    Exercise(
      id: 'split_squat', name: 'Bulgarian Split Squat',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.dumbbell, difficulty: Difficulty.intermediate,
      substitutes: ['walking_lunge'],
    ),

    // ── ARMS ───────────────────────────────────────────────────────────────
    Exercise(
      id: 'barbell_curl', name: 'Barbell Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.barbell, difficulty: Difficulty.beginner,
      substitutes: ['dumbbell_curl', 'hammer_curl'],
    ),
    Exercise(
      id: 'dumbbell_curl', name: 'Dumbbell Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['barbell_curl', 'hammer_curl'],
    ),
    Exercise(
      id: 'hammer_curl', name: 'Hammer Curl',
      primaryMuscle: MuscleGroup.biceps,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell, difficulty: Difficulty.beginner,
      substitutes: ['dumbbell_curl'],
    ),
    Exercise(
      id: 'tricep_pushdown', name: 'Tricep Pushdown',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['skull_crusher', 'tricep_dip'],
    ),
    Exercise(
      id: 'skull_crusher', name: 'Skull Crusher',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.ezBar, difficulty: Difficulty.intermediate,
      substitutes: ['tricep_pushdown'],
    ),
    Exercise(
      id: 'tricep_dip', name: 'Tricep Dip',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.bodyweight, difficulty: Difficulty.intermediate,
      substitutes: ['tricep_pushdown'],
    ),
    Exercise(
      id: 'cable_curl', name: 'Cable Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['barbell_curl', 'dumbbell_curl'],
    ),

    // ── CORE ───────────────────────────────────────────────────────────────
    Exercise(
      id: 'plank', name: 'Plank',
      primaryMuscle: MuscleGroup.core,
      equipment: Equipment.bodyweight, difficulty: Difficulty.beginner,
      substitutes: ['ab_rollout'],
    ),
    Exercise(
      id: 'ab_rollout', name: 'Ab Rollout',
      primaryMuscle: MuscleGroup.core,
      equipment: Equipment.bodyweight, difficulty: Difficulty.intermediate,
      substitutes: ['plank'],
    ),
    Exercise(
      id: 'cable_crunch', name: 'Cable Crunch',
      primaryMuscle: MuscleGroup.core,
      equipment: Equipment.cable, difficulty: Difficulty.beginner,
      substitutes: ['plank'],
    ),

    // ── CALVES ─────────────────────────────────────────────────────────────
    Exercise(
      id: 'standing_calf_raise', name: 'Standing Calf Raise',
      primaryMuscle: MuscleGroup.calves,
      equipment: Equipment.machine, difficulty: Difficulty.beginner,
      substitutes: ['seated_calf_raise'],
    ),
    Exercise(
      id: 'seated_calf_raise', name: 'Seated Calf Raise',
      primaryMuscle: MuscleGroup.calves,
      equipment: Equipment.machine, difficulty: Difficulty.beginner,
      substitutes: ['standing_calf_raise'],
    ),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Exercise? findById(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Exercise> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return all.where((e) =>
        e.name.toLowerCase().contains(q) ||
        e.primaryMuscle.label.toLowerCase().contains(q) ||
        e.equipment.label.toLowerCase().contains(q)).toList();
  }

  static List<Exercise> filterByMuscle(MuscleGroup m) =>
      all.where((e) => e.primaryMuscle == m).toList();

  static List<Exercise> filterByEquipment(Equipment eq) =>
      all.where((e) => e.equipment == eq).toList();

  static List<Exercise> substitutesFor(Exercise ex) =>
      ex.substitutes.map(findById).whereType<Exercise>().toList();

  // ── Routine exercise ID lists ─────────────────────────────────────────────

  static List<String> exerciseIdsFor(String routineName) {
    switch (routineName) {
      case 'Push Day':
        return [
          'barbell_bench_press',
          'incline_dumbbell_press',
          'cable_fly',
          'overhead_press',
          'lateral_raise',
          'tricep_pushdown',
        ];
      case 'Pull Day':
        return [
          'barbell_deadlift',
          'barbell_row',
          'lat_pulldown',
          'cable_row',
          'barbell_curl',
          'hammer_curl',
        ];
      case 'Legs Day':
        return [
          'barbell_squat',
          'romanian_deadlift',
          'leg_press',
          'leg_curl',
          'walking_lunge',
          'standing_calf_raise',
        ];
      case 'Upper Body':
        return [
          'barbell_bench_press',
          'barbell_row',
          'overhead_press',
          'lat_pulldown',
          'dumbbell_curl',
          'tricep_pushdown',
        ];
      case 'Lower Body':
        return [
          'barbell_squat',
          'romanian_deadlift',
          'leg_press',
          'leg_curl',
          'walking_lunge',
          'standing_calf_raise',
        ];
      case 'Full Body A':
        return [
          'barbell_squat',
          'barbell_bench_press',
          'barbell_row',
          'overhead_press',
          'plank',
        ];
      case 'Full Body B':
        return [
          'romanian_deadlift',
          'incline_dumbbell_press',
          'lat_pulldown',
          'lateral_raise',
          'cable_crunch',
        ];
      default:
        return [];
    }
  }
}