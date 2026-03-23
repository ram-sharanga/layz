// lib/features/plan/screens/exercise_library_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/screens/exercise_detail_screen.dart';
import 'package:layz/features/plan/services/plan_service.dart';

// ── Filter state ───────────────────────────────────────────────────────────

class _FilterState {
  final Set<MuscleGroup> muscles = {};
  final Set<Equipment> equipment = {};
  final Set<_ExType> types = {};
  final Set<Difficulty> difficulties = {};

  bool get hasAny =>
      muscles.isNotEmpty ||
      equipment.isNotEmpty ||
      types.isNotEmpty ||
      difficulties.isNotEmpty;

  int get count =>
      muscles.length + equipment.length + types.length + difficulties.length;

  void reset() {
    muscles.clear();
    equipment.clear();
    types.clear();
    difficulties.clear();
  }

  bool matches(Exercise ex) {
    if (muscles.isNotEmpty && !ex.primaryMuscles.any(muscles.contains)) {
      return false;
    }
    if (equipment.isNotEmpty && !equipment.contains(ex.equipment)) {
      return false;
    }
    if (types.isNotEmpty) {
      final isCompound = ex.secondaryMuscles.isNotEmpty;
      final exType = isCompound ? _ExType.compound : _ExType.isolation;
      if (!types.contains(exType)) return false;
    }
    if (difficulties.isNotEmpty && !difficulties.contains(ex.difficulty)) {
      return false;
    }
    return true;
  }
}

enum _ExType { compound, isolation }

enum _FilterCat { muscle, equipment, type, difficulty }

extension _FilterCatLabel on _FilterCat {
  String get label {
    switch (this) {
      case _FilterCat.muscle:
        return 'Muscle';
      case _FilterCat.equipment:
        return 'Equipment';
      case _FilterCat.type:
        return 'Type';
      case _FilterCat.difficulty:
        return 'Difficulty';
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({
    super.key,
    required this.goal,
    this.onExerciseAdded,
  });

  final String goal;
  final ValueChanged<Exercise>? onExerciseAdded;

  bool get isAddMode => onExerciseAdded != null;

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchFocused = false;
  String _query = '';

  final _FilterState _filters = _FilterState();
  _FilterCat? _openCat;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    final all = PlanService.getAllExercises();
    return all.where((ex) {
      if (_query.isNotEmpty &&
          !ex.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return _filters.matches(ex);
    }).toList();
  }

  void _toggleCat(_FilterCat cat) {
    setState(() => _openCat = _openCat == cat ? null : cat);
  }

  void _resetAll() {
    setState(() {
      _filters.reset();
      _openCat = null;
    });
  }

  // ── Option chips for a given category ────────────────────────────────────

  List<Widget> _buildOptions(_FilterCat cat) {
    switch (cat) {
      case _FilterCat.muscle:
        return MuscleGroup.values
            .map(
              (m) => _OptionChip(
                label: m.label,
                selected: _filters.muscles.contains(m),
                onTap: () => setState(() {
                  if (_filters.muscles.contains(m)) {
                    _filters.muscles.remove(m);
                  } else {
                    _filters.muscles.add(m);
                  }
                }),
              ),
            )
            .toList();

      case _FilterCat.equipment:
        return Equipment.values
            .map(
              (e) => _OptionChip(
                label: e.label,
                selected: _filters.equipment.contains(e),
                onTap: () => setState(() {
                  if (_filters.equipment.contains(e)) {
                    _filters.equipment.remove(e);
                  } else {
                    _filters.equipment.add(e);
                  }
                }),
              ),
            )
            .toList();

      case _FilterCat.type:
        return _ExType.values
            .map(
              (t) => _OptionChip(
                label: t == _ExType.compound ? 'Compound' : 'Isolation',
                selected: _filters.types.contains(t),
                onTap: () => setState(() {
                  if (_filters.types.contains(t)) {
                    _filters.types.remove(t);
                  } else {
                    _filters.types.add(t);
                  }
                }),
              ),
            )
            .toList();

      case _FilterCat.difficulty:
        return Difficulty.values
            .map(
              (d) => _OptionChip(
                label: d.label,
                selected: _filters.difficulties.contains(d),
                onTap: () => setState(() {
                  if (_filters.difficulties.contains(d)) {
                    _filters.difficulties.remove(d);
                  } else {
                    _filters.difficulties.add(d);
                  }
                }),
              ),
            )
            .toList();
    }
  }

  bool _catHasSelection(_FilterCat cat) {
    switch (cat) {
      case _FilterCat.muscle:
        return _filters.muscles.isNotEmpty;
      case _FilterCat.equipment:
        return _filters.equipment.isNotEmpty;
      case _FilterCat.type:
        return _filters.types.isNotEmpty;
      case _FilterCat.difficulty:
        return _filters.difficulties.isNotEmpty;
    }
  }

  List<({String label, VoidCallback onRemove})> get _activePills {
    final pills = <({String label, VoidCallback onRemove})>[];
    for (final m in _filters.muscles) {
      pills.add((
        label: m.label,
        onRemove: () => setState(() => _filters.muscles.remove(m)),
      ));
    }
    for (final e in _filters.equipment) {
      pills.add((
        label: e.label,
        onRemove: () => setState(() => _filters.equipment.remove(e)),
      ));
    }
    for (final t in _filters.types) {
      pills.add((
        label: t == _ExType.compound ? 'Compound' : 'Isolation',
        onRemove: () => setState(() => _filters.types.remove(t)),
      ));
    }
    for (final d in _filters.difficulties) {
      pills.add((
        label: d.label,
        onRemove: () => setState(() => _filters.difficulties.remove(d)),
      ));
    }
    return pills;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final filtered = _filtered;
    final pills = _activePills;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + title
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
                    const SizedBox(width: 14),
                    Text(
                      widget.isAddMode ? 'Add Exercise' : 'Exercise Library',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search bar — glass pill, lime focus border, no system ring
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: _searchFocused
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(
                              Icons.close,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),

          // ── Category tabs ─────────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // All / reset tab
                _CatTab(
                  label: _filters.hasAny ? 'All  ${_filters.count}' : 'All',
                  isActive: !_filters.hasAny && _openCat == null,
                  hasSelection: false,
                  onTap: _resetAll,
                ),
                const SizedBox(width: 6),
                ..._FilterCat.values.map((cat) {
                  final isOpen = _openCat == cat;
                  final hasSel = _catHasSelection(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _CatTab(
                      label: cat.label,
                      isActive: isOpen,
                      hasSelection: hasSel && !isOpen,
                      onTap: () => _toggleCat(cat),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Options panel — fixed height, horizontal scroll ───────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: _openCat != null ? 50 : 0,
            child: _openCat != null
                ? ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    children: _buildOptions(_openCat!),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          Container(
            height: 0.5,
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // ── Results count + active pills ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Text(
                  '${filtered.length} exercise${filtered.length != 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          if (pills.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                children: pills
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: p.onRemove,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  p.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.close,
                                  size: 11,
                                  color: AppColors.accent.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 4),

          // ── Exercise list ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(query: _query, hasFilters: _filters.hasAny)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    itemBuilder: (context, i) {
                      final ex = filtered[i];
                      return _ExerciseTile(
                        exercise: ex,
                        goal: widget.goal,
                        isAddMode: widget.isAddMode,
                        onTap: () {
                          if (widget.isAddMode) {
                            widget.onExerciseAdded!(ex);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(
                                  exercise: ex,
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

// ── Category tab ───────────────────────────────────────────────────────────

class _CatTab extends StatelessWidget {
  const _CatTab({
    required this.label,
    required this.isActive,
    required this.hasSelection,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;

    if (isActive) {
      bg = AppColors.accent;
      border = AppColors.accent;
      textColor = AppColors.background;
    } else if (hasSelection) {
      bg = AppColors.accent.withValues(alpha: 0.08);
      border = AppColors.accent.withValues(alpha: 0.3);
      textColor = AppColors.accent;
    } else {
      bg = Colors.transparent;
      border = Colors.white.withValues(alpha: 0.1);
      textColor = Colors.white.withValues(alpha: 0.45);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ── Option chip ────────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  const _OptionChip({
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
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.background
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ── Exercise tile ──────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
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
    final isCompound = exercise.secondaryMuscles.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        color: AppColors.background,
        child: Row(
          children: [
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
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _Tag(label: exercise.primaryMuscleLabel, isAccent: true),
                      _Tag(label: exercise.equipmentLabel),
                      _Tag(label: isCompound ? 'Compound' : 'Isolation'),
                      _Tag(label: exercise.difficultyLabel),
                    ],
                  ),
                  if (repRange != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${repRange.min}–${repRange.max} reps for your goal',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isAddMode ? Icons.add_circle_outline : Icons.chevron_right,
              color: isAddMode
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.2),
              size: isAddMode ? 22 : 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag pill ───────────────────────────────────────────────────────────────

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
            ? AppColors.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAccent
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isAccent
              ? AppColors.accent.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.hasFilters});

  final String query;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 12),
            Text(
              'No exercises found',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            if (query.isNotEmpty || hasFilters) ...[
              const SizedBox(height: 6),
              Text(
                hasFilters
                    ? 'Try removing some filters'
                    : 'Try a different search term',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
