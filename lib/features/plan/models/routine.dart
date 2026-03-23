// lib/features/plan/models/routine.dart

import 'workout_set.dart';
import 'exercise.dart';

class RoutineExercise {
  final String id;
  final Exercise exercise;
  final int order;
  final List<WorkoutSet> sets;
  final String? supersetWith; // id of next exercise if superset

  const RoutineExercise({
    required this.id,
    required this.exercise,
    required this.order,
    required this.sets,
    this.supersetWith,
  });

  List<WorkoutSet> get warmUpSets => sets.where((s) => s.isWarmUp).toList();
  List<WorkoutSet> get workingSets => sets.where((s) => !s.isWarmUp).toList();
}

class Routine {
  final String id;
  final String userId;
  final String name;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final bool isGenerated;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.exercises,
    required this.createdAt,
    this.isGenerated = false,
  });

  int get exerciseCount => exercises.length;

  String get muscleGroupLabel {
    if (exercises.isEmpty) return '';
    final muscles = exercises
        .map((e) => e.exercise.primaryMuscle.label)
        .toSet()
        .take(3)
        .join(', ');
    return muscles;
  }

  String get estimatedLabel {
    // ~1.5 min per working set (includes execution + rest overhead averaged)
    // Warm-up sets counted at 0.75 min each
    int workingSets = 0;
    int warmUpSets = 0;
    for (final re in exercises) {
      workingSets += re.workingSets.length;
      warmUpSets += re.warmUpSets.length;
    }
    final mins = (workingSets * 1.5 + warmUpSets * 0.75).round().clamp(10, 999);
    if (mins < 60) return '~$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~${h}h' : '~${h}h ${m}m';
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
}
