enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  core,
  fullBody,
}

enum Equipment {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  resistanceBand,
  kettlebell,
  ezBar,
}

enum Difficulty {
  beginner,
  intermediate,
  advanced,
}
 
class RepRange {
  final int min;
  final int max;
  final String note;
  const RepRange({
    required this.min,
    required this.max,
    required this.note,
  });
}
 
class Exercise {
  final String id;
  final String name;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final Difficulty difficulty;
  final List<String> imageUrls;      // Supabase Storage URLs
  final List<String> substituteIds;  // IDs of alternative exercises
  final Map<String, RepRange> repRanges; // keyed by goal: lean/muscle/fit
 
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.difficulty,
    this.imageUrls = const [],
    this.substituteIds = const [],
    required this.repRanges,
  });
 
  // Display helpers
  String get primaryMuscleLabel =>
      primaryMuscles.map((m) => m.label).join(' · ');
 
  String get secondaryMuscleLabel =>
      secondaryMuscles.map((m) => m.label).join(' · ');
 
  String get equipmentLabel => equipment.label;
  String get difficultyLabel => difficulty.label;
 
  RepRange? repRangeFor(String goal) => repRanges[goal];
}
 
// ── Extensions for display labels ─────────────────────────────────────────
 
extension MuscleGroupLabel on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest:     return 'Chest';
      case MuscleGroup.back:      return 'Back';
      case MuscleGroup.shoulders: return 'Shoulders';
      case MuscleGroup.biceps:    return 'Biceps';
      case MuscleGroup.triceps:   return 'Triceps';
      case MuscleGroup.legs:      return 'Legs';
      case MuscleGroup.glutes:    return 'Glutes';
      case MuscleGroup.core:      return 'Core';
      case MuscleGroup.fullBody:  return 'Full Body';
    }
  }
}
 
extension EquipmentLabel on Equipment {
  String get label {
    switch (this) {
      case Equipment.barbell:       return 'Barbell';
      case Equipment.dumbbell:      return 'Dumbbell';
      case Equipment.cable:         return 'Cable';
      case Equipment.machine:       return 'Machine';
      case Equipment.bodyweight:    return 'Bodyweight';
      case Equipment.resistanceBand:return 'Band';
      case Equipment.kettlebell:    return 'Kettlebell';
      case Equipment.ezBar:         return 'EZ Bar';
    }
  }
}
 
extension DifficultyLabel on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner:     return 'Beginner';
      case Difficulty.intermediate: return 'Intermediate';
      case Difficulty.advanced:     return 'Advanced';
    }
  }
}