// lib/features/plan/screens/create_routine_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/workout_set.dart';
import 'package:layz/features/plan/screens/exercise_library_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mutable routine exercise model used only during creation
// ─────────────────────────────────────────────────────────────────────────────

class _DraftExercise {
  final Exercise exercise;
  int sets;
  int reps;
  bool includeWarmup;

  _DraftExercise({
    required this.exercise,
    this.sets = 3,
    this.reps = 10,
    this.includeWarmup = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CreateRoutineScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({
    super.key,
    required this.goal,
    required this.userId,
    this.existingRoutine, // non-null = edit mode
  });

  final String goal;
  final String userId;
  final Routine? existingRoutine;

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final List<_DraftExercise>  _exercises = [];
  bool _saving = false;

  bool get _isEdit => widget.existingRoutine != null;
  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _exercises.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.existingRoutine!;
      _nameCtrl.text = r.name;
      for (final re in r.exercises) {
        _exercises.add(_DraftExercise(
          exercise:       re.exercise,
          sets:           re.workingSets.length,
          reps:           re.workingSets.isNotEmpty
              ? (re.workingSets.first.reps ?? 10)
              : 10,
          includeWarmup:  re.warmUpSets.isNotEmpty,
        ));
      }
    }
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          goal: widget.goal,
          onExerciseAdded: (exercise) {
            // Prevent duplicate
            if (_exercises.any((e) => e.exercise.id == exercise.id)) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise.name} already in routine',
                      style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }
            setState(() => _exercises.add(_DraftExercise(exercise: exercise)));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _removeExercise(int index) {
    HapticFeedback.lightImpact();
    setState(() => _exercises.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    HapticFeedback.mediumImpact();
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final exercises = _exercises.asMap().entries.map((entry) {
      final idx  = entry.key;
      final draft = entry.value;
      final sets  = <WorkoutSet>[];
      int setNum  = 1;

      if (draft.includeWarmup) {
        sets.add(WorkoutSet(
          id: '${draft.exercise.id}_wu_1',
          setNumber: setNum++,
          reps: (draft.reps * 0.6).round().clamp(5, 20),
          isWarmUp: true,
        ));
      }

      for (int i = 1; i <= draft.sets; i++) {
        sets.add(WorkoutSet(
          id: '${draft.exercise.id}_ws_$i',
          setNumber: setNum++,
          reps: draft.reps,
          isWarmUp: false,
        ));
      }

      return RoutineExercise(
        id:       '${_nameCtrl.text.trim()}_${draft.exercise.id}',
        exercise: draft.exercise,
        order:    idx,
        sets:     sets,
      );
    }).toList();

    final routine = Routine(
      id:          _isEdit
          ? widget.existingRoutine!.id
          : _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      userId:      widget.userId,
      name:        _nameCtrl.text.trim(),
      exercises:   exercises,
      createdAt:   DateTime.now(),
      isGenerated: false,
    );

    if (mounted) Navigator.of(context).pop(routine);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 17),
                      ),
                    ),
                    const Spacer(),
                    Text(_isEdit ? 'Edit Routine' : 'New Routine',
                        style: GoogleFonts.dmSans(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const Spacer(),
                    // placeholder for symmetry
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 20),

                // Routine name input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.dmSans(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Routine name',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ────────────────────────────────────────────────
          Expanded(
            child: _exercises.isEmpty
                ? _EmptyState(onAdd: _openLibrary)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 120),
                    onReorder: _reorder,
                    proxyDecorator: (child, index, animation) =>
                        Material(color: Colors.transparent, child: child),
                    itemCount: _exercises.length,
                    itemBuilder: (_, i) => _ExerciseDraftRow(
                      key: ValueKey(_exercises[i].exercise.id),
                      draft:    _exercises[i],
                      index:    i,
                      onRemove: () => _removeExercise(i),
                      onChanged: () => setState(() {}),
                    ),
                  ),
          ),

          // ── Bottom bar ───────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, botPad + 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                // Add exercise
                GestureDetector(
                  onTap: _openLibrary,
                  child: Container(
                    height: 52, width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.add,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                // Save
                Expanded(
                  child: GestureDetector(
                    onTap: _canSave ? _save : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: _canSave ? AppColors.accent : AppColors.buttonDisabled,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _saving
                            ? SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : Text(
                                _isEdit ? 'SAVE CHANGES' : 'CREATE ROUTINE',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: _canSave
                                      ? AppColors.background
                                      : AppColors.textSecondary,
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.fitness_center,
                  size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text('No exercises yet',
                style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            Text('Add exercises from the library to build your routine',
                style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Browse Library',
                    style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise draft row — inline set/rep/warmup config
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseDraftRow extends StatefulWidget {
  const _ExerciseDraftRow({
    super.key,
    required this.draft,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });
  final _DraftExercise draft;
  final int            index;
  final VoidCallback   onRemove;
  final VoidCallback   onChanged;

  @override
  State<_ExerciseDraftRow> createState() => _ExerciseDraftRowState();
}

class _ExerciseDraftRowState extends State<_ExerciseDraftRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Dismissible(
          key: ValueKey('dis_${d.exercise.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.red.withValues(alpha: 0.12),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
          onDismissed: (_) => widget.onRemove(),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              color: AppColors.background,
              child: Row(
                children: [
                  // Index
                  SizedBox(
                    width: 22,
                    child: Text('${widget.index + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.exercise.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 3),
                        Text(
                          '${d.sets} sets · ${d.reps} reps${d.includeWarmup ? ' · warmup' : ''}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 4),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expanded config
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _expanded
              ? Container(
                  margin: const EdgeInsets.fromLTRB(56, 0, 20, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      // Sets stepper
                      _ConfigRow(
                        label: 'Working sets',
                        value: '${d.sets}',
                        onDecrement: d.sets > 1
                            ? () { d.sets--; widget.onChanged(); setState(() {}); }
                            : null,
                        onIncrement: d.sets < 10
                            ? () { d.sets++; widget.onChanged(); setState(() {}); }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Reps stepper
                      _ConfigRow(
                        label: 'Reps per set',
                        value: '${d.reps}',
                        onDecrement: d.reps > 1
                            ? () { d.reps--; widget.onChanged(); setState(() {}); }
                            : null,
                        onIncrement: d.reps < 50
                            ? () { d.reps++; widget.onChanged(); setState(() {}); }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Warmup toggle
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Include warmup set',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    )),
                                Text('~60% weight, auto-calculated',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11, color: AppColors.textSecondary,
                                    )),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              d.includeWarmup = !d.includeWarmup;
                              widget.onChanged();
                              setState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44, height: 26,
                              padding: EdgeInsets.all(d.includeWarmup ? 3 : 3),
                              decoration: BoxDecoration(
                                color: d.includeWarmup
                                    ? Colors.orange.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: d.includeWarmup
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 20, height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Divider
        if (!_expanded)
          Divider(
            height: 1, indent: 56,
            color: Colors.white.withValues(alpha: 0.04),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config row — stepper widget used for sets and reps
// ─────────────────────────────────────────────────────────────────────────────

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });
  final String     label;
  final String     value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
        ),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: onDecrement,
            ),
            SizedBox(
              width: 40,
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  )),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}