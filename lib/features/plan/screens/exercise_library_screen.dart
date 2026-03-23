// lib/features/plan/screens/exercise_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/services/plan_service.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({
    super.key,
    required this.goal,
    this.onExerciseAdded, // non-null = add-to-routine mode
  });

  final String                  goal;
  final ValueChanged<Exercise>? onExerciseAdded;

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  MuscleGroup? _muscleFilter;
  Equipment?   _equipFilter;

  bool get _addMode => widget.onExerciseAdded != null;

  List<Exercise> get _filtered {
    var list = PlanService.getAllExercises();
    final q  = _search.text.trim();
    if (q.isNotEmpty) {
      final ql = q.toLowerCase();
      list = list.where((e) =>
          e.name.toLowerCase().contains(ql) ||
          e.primaryMuscle.label.toLowerCase().contains(ql) ||
          e.equipment.label.toLowerCase().contains(ql)).toList();
    }
    if (_muscleFilter != null) {
      list = list.where((e) => e.primaryMuscle == _muscleFilter).toList();
    }
    if (_equipFilter != null) {
      list = list.where((e) => e.equipment == _equipFilter).toList();
    }
    return list;
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _addMode ? 'Add Exercise' : 'Exercise Library',
                      style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Search
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText:    'Search exercises…',
                      hintStyle:   GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.2)),
                      prefixIcon:  Icon(Icons.search, size: 18,
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      suffixIcon:  _search.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _search.clear();
                                setState(() {});
                              },
                              child: Icon(Icons.close, size: 16,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            )
                          : null,
                      border:          InputBorder.none,
                      contentPadding:  const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Muscle filter chips
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _muscleFilter == null && _equipFilter == null,
                        onTap: () => setState(() {
                          _muscleFilter = null;
                          _equipFilter  = null;
                        }),
                      ),
                      ...MuscleGroup.values.map((m) => _FilterChip(
                        label:    m.label,
                        selected: _muscleFilter == m,
                        onTap:    () => setState(() {
                          _muscleFilter = _muscleFilter == m ? null : m;
                        }),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('No exercises found',
                        style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, i) {
                      final ex = _filtered[i];
                      return _ExerciseRow(
                        exercise: ex,
                        addMode:  _addMode,
                        onTap: () {
                          if (_addMode) {
                            HapticFeedback.mediumImpact();
                            widget.onExerciseAdded!(ex);
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ExerciseDetailScreen(
                                exercise: ex, goal: widget.goal),
                            ));
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise row
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.addMode,
    required this.onTap,
  });
  final Exercise     exercise;
  final bool         addMode;
  final VoidCallback onTap;

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:     return Colors.green;
      case Difficulty.intermediate: return Colors.orange;
      case Difficulty.advanced:     return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Row(
          children: [
            // Muscle dot
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Center(
                child: Text(
                  exercise.primaryMuscle.label.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.accent.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(exercise.primaryMuscle.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      width: 3, height: 3, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(exercise.equipment.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _diffColor(exercise.difficulty),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            if (addMode)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.add, size: 16, color: AppColors.accent),
              )
            else
              Icon(Icons.chevron_right, size: 16,
                  color: Colors.white.withValues(alpha: 0.15)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String     label;
  final bool       selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }
}