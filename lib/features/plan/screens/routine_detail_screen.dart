// lib/features/plan/screens/routine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
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

  // Tracks which exercises are supersetted with the next one
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
      final exercises = _routine.exercises
          .where((e) => e.id != id)
          .toList();
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ──────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _routine.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _routine.muscleGroupLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_routine.exerciseCount} exercises',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ────────────────────────────
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
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

          // ── Bottom bar ───────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20, 16, 20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                // Add exercise
                Expanded(
                  child: GestureDetector(
                    onTap: _openLibraryToAdd,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add exercise',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Start workout
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: navigate to warmup then active workout
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'START',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red.withValues(alpha: 0.15),
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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              color: AppColors.background,
              child: Row(
                children: [

                  // Index number
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

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
                        const SizedBox(height: 3),
                        Text(
                          '${routineExercise.setsLabel} · '
                          '${routineExercise.exercise.equipmentLabel}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Superset link icon — lime, always visible
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
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Superset connector line
        if (isSuperset)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'superset',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.accent.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

        // Divider between exercises
        if (!isSuperset)
          const Divider(
            height: 1,
            indent: 56,
            color: AppColors.divider,
          ),
      ],
    );
  }
}