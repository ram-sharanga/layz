// lib/features/plan/screens/routine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/screens/active_workout_screen.dart';
import 'package:layz/features/plan/screens/exercise_detail_screen.dart';
import 'package:layz/features/plan/screens/exercise_library_screen.dart';

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.goal,
  });

  final Routine routine;
  final String goal;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late Routine _routine;
  final Set<String> _supersetIds = {};

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final exercises = List<RoutineExercise>.from(_routine.exercises);
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
      _routine = _routine.copyWith(exercises: exercises);
    });
    HapticFeedback.mediumImpact();
  }

  void _removeExercise(String id) {
    setState(() {
      final exercises = _routine.exercises.where((e) => e.id != id).toList();
      _routine = _routine.copyWith(exercises: exercises);
    });
  }

  void _toggleSuperset(String exerciseId) {
    setState(() {
      if (_supersetIds.contains(exerciseId)) {
        _supersetIds.remove(exerciseId);
      } else {
        _supersetIds.add(exerciseId);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _openExerciseDetail(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exercise: exercise,
          goal: widget.goal,
        ),
      ),
    );
  }

  void _openLibraryToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          goal: widget.goal,
          onExerciseAdded: (exercise) {
            // TODO: add exercise to routine
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startWorkout() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          routine: _routine,
          goal: widget.goal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + exercise count row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Estimated time pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _routine.estimatedLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Exercise count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        '${_routine.exerciseCount} exercises',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Routine name
                Text(
                  _routine.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 6),

                // Muscle groups
                Text(
                  _routine.muscleGroupLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ──────────────────────────────────────────────────
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 120),
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemCount: _routine.exercises.length,
              itemBuilder: (context, index) {
                final re = _routine.exercises[index];
                final isSuperset = _supersetIds.contains(re.id);
                final canSuperset = index < _routine.exercises.length - 1;

                return _ExerciseRow(
                  key: ValueKey(re.id),
                  routineExercise: re,
                  index: index,
                  isSuperset: isSuperset,
                  canSuperset: canSuperset,
                  onTap: () => _openExerciseDetail(re.exercise),
                  onRemove: () => _removeExercise(re.id),
                  onSupersetToggle: canSuperset
                      ? () => _toggleSuperset(re.id)
                      : null,
                );
              },
            ),
          ),

          // ── Bottom bar ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                // Add exercise — secondary, compact
                GestureDetector(
                  onTap: _openLibraryToAdd,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Start — primary, dominant
                Expanded(
                  child: GestureDetector(
                    onTap: _startWorkout,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'START WORKOUT',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise row ───────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.routineExercise,
    required this.index,
    required this.isSuperset,
    required this.canSuperset,
    required this.onTap,
    required this.onRemove,
    this.onSupersetToggle,
  });

  final RoutineExercise routineExercise;
  final int index;
  final bool isSuperset;
  final bool canSuperset;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onSupersetToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Dismissible(
          key: ValueKey('dismiss_${routineExercise.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.red.withValues(alpha: 0.12),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
          onDismissed: (_) => onRemove(),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              color: AppColors.background,
              child: Row(
                children: [
                  // Index
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routineExercise.exercise.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              routineExercise.setsLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Container(
                                width: 2,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Text(
                              routineExercise.repRangeLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.accent
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Superset link
                  if (canSuperset)
                    GestureDetector(
                      onTap: onSupersetToggle,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.link,
                          size: 18,
                          color: isSuperset
                              ? AppColors.accent
                              : AppColors.textSecondary
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                    ),

                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Superset connector
        if (isSuperset)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'superset',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.accent.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

        // Divider
        if (!isSuperset)
          Divider(
            height: 1,
            indent: 56,
            color: Colors.white.withValues(alpha: 0.04),
          ),
      ],
    );
  }
}