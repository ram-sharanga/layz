import 'package:layz/features/plan/models/exercise.dart';

class ExerciseSeedData {
  static const List<Exercise> all = [

    // ── PUSH — Chest ──────────────────────────────────────────────────────

    Exercise(
      id: 'bench_press',
      name: 'Bench Press',
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.barbell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['dumbbell_press', 'push_up', 'incline_dumbbell_press'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light weight, controlled'),
        'muscle': RepRange(min: 6,  max: 10, note: 'Heavy, 2 reps in reserve'),
        'fit':    RepRange(min: 12, max: 15, note: 'Moderate, steady pace'),
      },
    ),

    Exercise(
      id: 'incline_dumbbell_press',
      name: 'Incline Dumbbell Press',
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['bench_press', 'incline_barbell_press'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full stretch'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Heavy enough to feel it'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled movement'),
      },
    ),

    Exercise(
      id: 'dumbbell_press',
      name: 'Dumbbell Chest Press',
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['bench_press', 'push_up'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full range'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Go heavy, squeeze at top'),
        'fit':    RepRange(min: 12, max: 15, note: 'Steady tempo'),
      },
    ),

    Exercise(
      id: 'push_up',
      name: 'Push Up',
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.bodyweight,
      difficulty: Difficulty.beginner,
      substituteIds: ['bench_press', 'dumbbell_press'],
      repRanges: {
        'lean':   RepRange(min: 20, max: 30, note: 'High reps, controlled'),
        'muscle': RepRange(min: 10, max: 20, note: 'Add weight if too easy'),
        'fit':    RepRange(min: 15, max: 25, note: 'Steady pace'),
      },
    ),

    Exercise(
      id: 'cable_fly',
      name: 'Cable Fly',
      primaryMuscles: [MuscleGroup.chest],
      secondaryMuscles: [],
      equipment: Equipment.cable,
      difficulty: Difficulty.intermediate,
      substituteIds: ['dumbbell_fly', 'pec_deck'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, feel the stretch'),
        'muscle': RepRange(min: 10, max: 15, note: 'Full stretch, strong squeeze'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled arc'),
      },
    ),

    // ── PUSH — Shoulders ──────────────────────────────────────────────────

    Exercise(
      id: 'overhead_press',
      name: 'Overhead Press',
      primaryMuscles: [MuscleGroup.shoulders],
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.core],
      equipment: Equipment.barbell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['dumbbell_shoulder_press', 'arnold_press'],
      repRanges: {
        'lean':   RepRange(min: 12, max: 15, note: 'Light, full lockout'),
        'muscle': RepRange(min: 6,  max: 10, note: 'Heavy, brace your core'),
        'fit':    RepRange(min: 10, max: 12, note: 'Controlled press'),
      },
    ),

    Exercise(
      id: 'lateral_raise',
      name: 'Lateral Raise',
      primaryMuscles: [MuscleGroup.shoulders],
      secondaryMuscles: [],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['cable_lateral_raise', 'machine_lateral_raise'],
      repRanges: {
        'lean':   RepRange(min: 20, max: 25, note: 'Very light, slow tempo'),
        'muscle': RepRange(min: 12, max: 20, note: 'Control the negative'),
        'fit':    RepRange(min: 15, max: 20, note: 'No swinging'),
      },
    ),

    Exercise(
      id: 'dumbbell_shoulder_press',
      name: 'Dumbbell Shoulder Press',
      primaryMuscles: [MuscleGroup.shoulders],
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['overhead_press', 'arnold_press'],
      repRanges: {
        'lean':   RepRange(min: 12, max: 15, note: 'Light, full range'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Heavy and controlled'),
        'fit':    RepRange(min: 10, max: 12, note: 'Steady tempo'),
      },
    ),

    // ── PUSH — Triceps ────────────────────────────────────────────────────

    Exercise(
      id: 'tricep_pushdown',
      name: 'Tricep Pushdown',
      primaryMuscles: [MuscleGroup.triceps],
      secondaryMuscles: [],
      equipment: Equipment.cable,
      difficulty: Difficulty.beginner,
      substituteIds: ['skull_crusher', 'overhead_tricep_extension'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, squeeze at bottom'),
        'muscle': RepRange(min: 10, max: 15, note: 'Full lockout each rep'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled pace'),
      },
    ),

    Exercise(
      id: 'skull_crusher',
      name: 'Skull Crusher',
      primaryMuscles: [MuscleGroup.triceps],
      secondaryMuscles: [],
      equipment: Equipment.ezBar,
      difficulty: Difficulty.intermediate,
      substituteIds: ['tricep_pushdown', 'overhead_tricep_extension'],
      repRanges: {
        'lean':   RepRange(min: 12, max: 15, note: 'Light, elbows stable'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Control the negative'),
        'fit':    RepRange(min: 10, max: 12, note: 'Slow and steady'),
      },
    ),

    // ── PULL — Back ───────────────────────────────────────────────────────

    Exercise(
      id: 'deadlift',
      name: 'Deadlift',
      primaryMuscles: [MuscleGroup.back],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.legs, MuscleGroup.core],
      equipment: Equipment.barbell,
      difficulty: Difficulty.advanced,
      substituteIds: ['romanian_deadlift', 'trap_bar_deadlift'],
      repRanges: {
        'lean':   RepRange(min: 10, max: 15, note: 'Moderate weight, hinge hard'),
        'muscle': RepRange(min: 3,  max: 6,  note: 'Heavy, full reset each rep'),
        'fit':    RepRange(min: 8,  max: 10, note: 'Perfect form priority'),
      },
    ),

    Exercise(
      id: 'pull_up',
      name: 'Pull Up',
      primaryMuscles: [MuscleGroup.back],
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.bodyweight,
      difficulty: Difficulty.intermediate,
      substituteIds: ['lat_pulldown', 'assisted_pull_up'],
      repRanges: {
        'lean':   RepRange(min: 10, max: 15, note: 'Body weight, full hang'),
        'muscle': RepRange(min: 6,  max: 10, note: 'Add weight if needed'),
        'fit':    RepRange(min: 8,  max: 12, note: 'Control the descent'),
      },
    ),

    Exercise(
      id: 'lat_pulldown',
      name: 'Lat Pulldown',
      primaryMuscles: [MuscleGroup.back],
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable,
      difficulty: Difficulty.beginner,
      substituteIds: ['pull_up', 'seated_cable_row'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full stretch at top'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Pull to chest, squeeze lats'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled tempo'),
      },
    ),

    Exercise(
      id: 'barbell_row',
      name: 'Barbell Row',
      primaryMuscles: [MuscleGroup.back],
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.core],
      equipment: Equipment.barbell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['dumbbell_row', 'seated_cable_row'],
      repRanges: {
        'lean':   RepRange(min: 12, max: 15, note: 'Light, squeeze shoulder blades'),
        'muscle': RepRange(min: 6,  max: 10, note: 'Heavy rows, chest to bar'),
        'fit':    RepRange(min: 10, max: 12, note: 'Controlled hinge'),
      },
    ),

    Exercise(
      id: 'dumbbell_row',
      name: 'Single Arm Dumbbell Row',
      primaryMuscles: [MuscleGroup.back],
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['barbell_row', 'seated_cable_row'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full stretch'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Heavy, elbow drives back'),
        'fit':    RepRange(min: 12, max: 15, note: 'Both sides equal'),
      },
    ),

    // ── PULL — Biceps ─────────────────────────────────────────────────────

    Exercise(
      id: 'barbell_curl',
      name: 'Barbell Curl',
      primaryMuscles: [MuscleGroup.biceps],
      secondaryMuscles: [],
      equipment: Equipment.barbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['dumbbell_curl', 'hammer_curl'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full squeeze'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Heavy, no swinging'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled curl'),
      },
    ),

    Exercise(
      id: 'dumbbell_curl',
      name: 'Dumbbell Curl',
      primaryMuscles: [MuscleGroup.biceps],
      secondaryMuscles: [],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['barbell_curl', 'hammer_curl', 'cable_curl'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Alternate arms, slow'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Squeeze at top'),
        'fit':    RepRange(min: 12, max: 15, note: 'Both arms controlled'),
      },
    ),

    Exercise(
      id: 'hammer_curl',
      name: 'Hammer Curl',
      primaryMuscles: [MuscleGroup.biceps],
      secondaryMuscles: [],
      equipment: Equipment.dumbbell,
      difficulty: Difficulty.beginner,
      substituteIds: ['dumbbell_curl', 'barbell_curl'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, neutral grip'),
        'muscle': RepRange(min: 10, max: 15, note: 'Heavier than regular curl'),
        'fit':    RepRange(min: 12, max: 15, note: 'Alternate arms'),
      },
    ),

    // ── LEGS ──────────────────────────────────────────────────────────────

    Exercise(
      id: 'squat',
      name: 'Barbell Squat',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.core],
      equipment: Equipment.barbell,
      difficulty: Difficulty.advanced,
      substituteIds: ['goblet_squat', 'leg_press', 'dumbbell_squat'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'High rep, moderate weight'),
        'muscle': RepRange(min: 5,  max: 8,  note: 'Heavy, below parallel'),
        'fit':    RepRange(min: 10, max: 12, note: 'Form first always'),
      },
    ),

    Exercise(
      id: 'leg_press',
      name: 'Leg Press',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.machine,
      difficulty: Difficulty.beginner,
      substituteIds: ['squat', 'goblet_squat'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full range'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Heavy, controlled descent'),
        'fit':    RepRange(min: 12, max: 15, note: 'Feet shoulder width'),
      },
    ),

    Exercise(
      id: 'romanian_deadlift',
      name: 'Romanian Deadlift',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.back],
      equipment: Equipment.barbell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['dumbbell_rdl', 'good_morning'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, feel the hamstring'),
        'muscle': RepRange(min: 8,  max: 12, note: 'Hip hinge, not a squat'),
        'fit':    RepRange(min: 10, max: 12, note: 'Slow negative'),
      },
    ),

    Exercise(
      id: 'leg_curl',
      name: 'Leg Curl',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: Difficulty.beginner,
      substituteIds: ['romanian_deadlift', 'nordic_curl'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, full squeeze'),
        'muscle': RepRange(min: 10, max: 15, note: 'Squeeze at top'),
        'fit':    RepRange(min: 12, max: 15, note: 'Controlled tempo'),
      },
    ),

    Exercise(
      id: 'leg_extension',
      name: 'Leg Extension',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: Difficulty.beginner,
      substituteIds: ['squat', 'leg_press'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, lockout squeeze'),
        'muscle': RepRange(min: 10, max: 15, note: 'Full extension each rep'),
        'fit':    RepRange(min: 12, max: 15, note: 'Slow and controlled'),
      },
    ),

    Exercise(
      id: 'calf_raise',
      name: 'Calf Raise',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: Difficulty.beginner,
      substituteIds: ['standing_calf_raise', 'seated_calf_raise'],
      repRanges: {
        'lean':   RepRange(min: 20, max: 30, note: 'High rep, pause at top'),
        'muscle': RepRange(min: 12, max: 20, note: 'Full range, slow negative'),
        'fit':    RepRange(min: 15, max: 20, note: 'Both legs equal'),
      },
    ),

    Exercise(
      id: 'goblet_squat',
      name: 'Goblet Squat',
      primaryMuscles: [MuscleGroup.legs],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.core],
      equipment: Equipment.kettlebell,
      difficulty: Difficulty.beginner,
      substituteIds: ['squat', 'leg_press', 'dumbbell_squat'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Light, upright torso'),
        'muscle': RepRange(min: 10, max: 15, note: 'Heavy kettlebell'),
        'fit':    RepRange(min: 12, max: 15, note: 'Deep squat, chest up'),
      },
    ),

    // ── CORE ──────────────────────────────────────────────────────────────

    Exercise(
      id: 'plank',
      name: 'Plank',
      primaryMuscles: [MuscleGroup.core],
      secondaryMuscles: [MuscleGroup.shoulders],
      equipment: Equipment.bodyweight,
      difficulty: Difficulty.beginner,
      substituteIds: ['ab_wheel', 'hollow_hold'],
      repRanges: {
        'lean':   RepRange(min: 30, max: 60,  note: 'Seconds. Breathe steadily'),
        'muscle': RepRange(min: 45, max: 90,  note: 'Seconds. Squeeze everything'),
        'fit':    RepRange(min: 30, max: 45,  note: 'Seconds. Hips level'),
      },
    ),

    Exercise(
      id: 'cable_crunch',
      name: 'Cable Crunch',
      primaryMuscles: [MuscleGroup.core],
      secondaryMuscles: [],
      equipment: Equipment.cable,
      difficulty: Difficulty.beginner,
      substituteIds: ['crunch', 'decline_crunch'],
      repRanges: {
        'lean':   RepRange(min: 20, max: 25, note: 'Light, crunch hard'),
        'muscle': RepRange(min: 12, max: 15, note: 'Weighted, slow negative'),
        'fit':    RepRange(min: 15, max: 20, note: 'Full contraction'),
      },
    ),

    Exercise(
      id: 'hanging_leg_raise',
      name: 'Hanging Leg Raise',
      primaryMuscles: [MuscleGroup.core],
      secondaryMuscles: [],
      equipment: Equipment.bodyweight,
      difficulty: Difficulty.intermediate,
      substituteIds: ['lying_leg_raise', 'cable_crunch'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Controlled swing'),
        'muscle': RepRange(min: 10, max: 15, note: 'Add ankle weights'),
        'fit':    RepRange(min: 12, max: 15, note: 'No kipping'),
      },
    ),

    // ── FULL BODY ─────────────────────────────────────────────────────────

    Exercise(
      id: 'clean_and_press',
      name: 'Clean and Press',
      primaryMuscles: [MuscleGroup.fullBody],
      secondaryMuscles: [],
      equipment: Equipment.barbell,
      difficulty: Difficulty.advanced,
      substituteIds: ['dumbbell_clean_press', 'thruster'],
      repRanges: {
        'lean':   RepRange(min: 10, max: 15, note: 'Moderate, explosive'),
        'muscle': RepRange(min: 5,  max: 8,  note: 'Heavy, full lockout'),
        'fit':    RepRange(min: 8,  max: 10, note: 'Technical — form first'),
      },
    ),

    Exercise(
      id: 'burpee',
      name: 'Burpee',
      primaryMuscles: [MuscleGroup.fullBody],
      secondaryMuscles: [],
      equipment: Equipment.bodyweight,
      difficulty: Difficulty.intermediate,
      substituteIds: ['mountain_climber', 'squat_thrust'],
      repRanges: {
        'lean':   RepRange(min: 15, max: 20, note: 'Fast, minimal rest'),
        'muscle': RepRange(min: 10, max: 15, note: 'Add weight vest'),
        'fit':    RepRange(min: 10, max: 15, note: 'Full extension at top'),
      },
    ),

    Exercise(
      id: 'kettlebell_swing',
      name: 'Kettlebell Swing',
      primaryMuscles: [MuscleGroup.fullBody],
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.back],
      equipment: Equipment.kettlebell,
      difficulty: Difficulty.intermediate,
      substituteIds: ['romanian_deadlift', 'good_morning'],
      repRanges: {
        'lean':   RepRange(min: 20, max: 30, note: 'Light, explosive hips'),
        'muscle': RepRange(min: 15, max: 20, note: 'Heavy bell, hip drive'),
        'fit':    RepRange(min: 15, max: 20, note: 'Hinge, not a squat'),
      },
    ),
  ];

  // ── Lookup helpers ────────────────────────────────────────────────────────

  static Exercise? findById(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Exercise> filterByMuscle(MuscleGroup muscle) =>
      all.where((e) => e.primaryMuscles.contains(muscle)).toList();

  static List<Exercise> filterByEquipment(Equipment equipment) =>
      all.where((e) => e.equipment == equipment).toList();

  static List<Exercise> search(String query) {
    final q = query.toLowerCase();
    return all.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  static List<Exercise> substitutesFor(Exercise exercise) {
    return exercise.substituteIds
        .map((id) => findById(id))
        .whereType<Exercise>()
        .toList();
  }

  // Default exercises per routine name — seeds the pre-populated plan
  static List<String> exerciseIdsFor(String routineName) {
    switch (routineName) {
      case 'Push Day':
        return [
          'bench_press',
          'incline_dumbbell_press',
          'overhead_press',
          'lateral_raise',
          'tricep_pushdown',
          'skull_crusher',
        ];
      case 'Pull Day':
        return [
          'deadlift',
          'barbell_row',
          'lat_pulldown',
          'dumbbell_row',
          'barbell_curl',
          'hammer_curl',
        ];
      case 'Legs Day':
        return [
          'squat',
          'romanian_deadlift',
          'leg_press',
          'leg_curl',
          'leg_extension',
          'calf_raise',
        ];
      case 'Upper Body':
        return [
          'bench_press',
          'barbell_row',
          'overhead_press',
          'lat_pulldown',
          'lateral_raise',
          'barbell_curl',
        ];
      case 'Lower Body':
        return [
          'squat',
          'romanian_deadlift',
          'leg_press',
          'leg_curl',
          'leg_extension',
          'calf_raise',
        ];
      case 'Full Body':
        return [
          'squat',
          'bench_press',
          'barbell_row',
          'overhead_press',
          'romanian_deadlift',
          'plank',
        ];
      default:
        return [];
    }
  }
}