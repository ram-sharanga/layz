// lib/features/plan/models/exercise.dart

enum MuscleGroup {
  chest, back, shoulders, biceps, triceps,
  legs, glutes, core, calves, fullBody;

  String get label {
    switch (this) {
      case MuscleGroup.chest:    return 'Chest';
      case MuscleGroup.back:     return 'Back';
      case MuscleGroup.shoulders:return 'Shoulders';
      case MuscleGroup.biceps:   return 'Biceps';
      case MuscleGroup.triceps:  return 'Triceps';
      case MuscleGroup.legs:     return 'Legs';
      case MuscleGroup.glutes:   return 'Glutes';
      case MuscleGroup.core:     return 'Core';
      case MuscleGroup.calves:   return 'Calves';
      case MuscleGroup.fullBody: return 'Full Body';
    }
  }
}

enum Equipment {
  barbell, dumbbell, cable, machine, bodyweight,
  kettlebell, ezBar, resistanceBand, none;

  String get label {
    switch (this) {
      case Equipment.barbell:        return 'Barbell';
      case Equipment.dumbbell:       return 'Dumbbell';
      case Equipment.cable:          return 'Cable';
      case Equipment.machine:        return 'Machine';
      case Equipment.bodyweight:     return 'Bodyweight';
      case Equipment.kettlebell:     return 'Kettlebell';
      case Equipment.ezBar:          return 'EZ Bar';
      case Equipment.resistanceBand: return 'Band';
      case Equipment.none:           return 'None';
    }
  }
}

enum Difficulty { beginner, intermediate, advanced }

class RepRange {
  final int min;
  final int max;
  const RepRange(this.min, this.max);
}

class Exercise {
  final String      id;
  final String      name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment   equipment;
  final Difficulty  difficulty;
  final String?     description;
  final String?     imageUrl;  // future use
  final List<String> substitutes; // ids

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.difficulty = Difficulty.intermediate,
    this.description,
    this.imageUrl,
    this.substitutes = const [],
  });

  String get primaryMuscleLabel => primaryMuscle.label;

  String get equipmentLabel => equipment.label;

  /// Returns rep range appropriate for a given goal string.
  RepRange? repRangeFor(String goal) {
    switch (goal) {
      case 'muscle': return const RepRange(6, 12);
      case 'lean':   return const RepRange(12, 20);
      case 'fit':    return const RepRange(10, 15);
      default:       return const RepRange(8, 12);
    }
  }
}