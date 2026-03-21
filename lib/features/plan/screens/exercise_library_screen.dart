// lib/features/plan/screens/exercise_library_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/screens/exercise_detail_screen.dart';
import 'package:layz/features/plan/services/plan_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({
    super.key,
    required this.goal,
    this.onExerciseAdded, // null = browse mode, non-null = add-to-routine mode
  });

  final String goal;
  final ValueChanged<Exercise>? onExerciseAdded;

  bool get isAddMode => onExerciseAdded != null;

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  MuscleGroup? _selectedMuscle;
  Equipment? _selectedEquipment;
  String _query = '';

  List<Exercise> get _filtered {
    var list = PlanService.getAllExercises();

    if (_query.isNotEmpty) {
      list = list
          .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    if (_selectedMuscle != null) {
      list = list
          .where((e) => e.primaryMuscles.contains(_selectedMuscle))
          .toList();
    }

    if (_selectedEquipment != null) {
      list = list
          .where((e) => e.equipment == _selectedEquipment)
          .toList();
    }

    return list;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ──────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Text(
                      widget.isAddMode ? 'Add Exercise' : 'Exercise Library',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search exercises...',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Muscle filter chips ──────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedMuscle == null &&
                      _selectedEquipment == null,
                  onTap: () => setState(() {
                    _selectedMuscle = null;
                    _selectedEquipment = null;
                  }),
                ),
                ...MuscleGroup.values.map((m) => _FilterChip(
                      label: m.label,
                      selected: _selectedMuscle == m,
                      onTap: () => setState(() {
                        _selectedMuscle =
                            _selectedMuscle == m ? null : m;
                        _selectedEquipment = null;
                      }),
                    )),
              ],
            ),
          ),

          // ── Equipment filter chips ───────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              children: Equipment.values.map((eq) => _FilterChip(
                    label: eq.label,
                    selected: _selectedEquipment == eq,
                    onTap: () => setState(() {
                      _selectedEquipment =
                          _selectedEquipment == eq ? null : eq;
                      _selectedMuscle = null;
                    }),
                  )).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // ── Results count ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} exercises',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) {
                      final exercise = filtered[i];
                      return _ExerciseListTile(
                        exercise: exercise,
                        goal: widget.goal,
                        isAddMode: widget.isAddMode,
                        onTap: () {
                          if (widget.isAddMode) {
                            widget.onExerciseAdded!(exercise);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(
                                  exercise: exercise,
                                  goal: widget.goal,
                                ),
                              ),
                            );
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

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Exercise list tile ─────────────────────────────────────────────────────

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({
    required this.exercise,
    required this.goal,
    required this.isAddMode,
    required this.onTap,
  });

  final Exercise exercise;
  final String goal;
  final bool isAddMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repRange = exercise.repRangeFor(goal);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        color: AppColors.background,
        child: Row(
          children: [

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(label: exercise.primaryMuscleLabel),
                      const SizedBox(width: 6),
                      _Tag(label: exercise.equipmentLabel),
                      const SizedBox(width: 6),
                      _Tag(
                        label: exercise.difficultyLabel,
                        isAccent: exercise.difficulty == Difficulty.beginner,
                      ),
                    ],
                  ),
                  if (repRange != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${repRange.min}–${repRange.max} reps for your goal',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action icon
            Icon(
              isAddMode ? Icons.add_circle_outline : Icons.chevron_right,
              color: isAddMode ? AppColors.accent : AppColors.textSecondary,
              size: isAddMode ? 22 : 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small tag pill ─────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.isAccent = false});

  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAccent
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isAccent ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No exercises found',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Try a different search term',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}