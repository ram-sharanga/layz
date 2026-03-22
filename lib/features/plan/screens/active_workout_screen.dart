// lib/features/plan/screens/active_workout_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/workout_set.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.routine,
    required this.goal,
  });

  final Routine routine;
  final String goal;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // Current position
  int _exerciseIndex = 0;
  int _setIndex = 0;

  // Rest timer state
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;

  // Per-exercise weight memory: exerciseId → weight string
  // Persists across sets within same exercise
  final Map<String, String> _weightMemory = {};

  // Logged sets: exerciseId_setIndex → WorkoutSet
  final Map<String, WorkoutSet> _loggedSets = {};

  // Controllers for weight/reps inputs
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _repsCtrl = TextEditingController();

  // Workout start time
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _prefillInputs();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  RoutineExercise get _currentExercise =>
      widget.routine.exercises[_exerciseIndex];

  WorkoutSet get _currentSet =>
      _currentExercise.sets[_setIndex];

  bool get _isLastSet =>
      _setIndex >= _currentExercise.sets.length - 1;

  bool get _isLastExercise =>
      _exerciseIndex >= widget.routine.exercises.length - 1;

  bool get _isFinished =>
      _isLastExercise && _isLastSet;

  int get _totalSets => _currentExercise.sets.length;

  String get _elapsedLabel {
    final elapsed = DateTime.now().difference(_startTime);
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _prefillInputs() {
    // Weight: use memory for this exercise, else blank
    final memWeight = _weightMemory[_currentExercise.exercise.id] ?? '';
    _weightCtrl.text = memWeight;

    // Reps: prefill from set target
    final targetReps = _currentSet.reps;
    _repsCtrl.text = targetReps != null ? '$targetReps' : '';
  }

  String _logKey(int exIdx, int setIdx) => '${exIdx}_$setIdx';

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onDone() {
    HapticFeedback.mediumImpact();

    // Save weight to memory for this exercise
    final weightText = _weightCtrl.text.trim();
    if (weightText.isNotEmpty) {
      _weightMemory[_currentExercise.exercise.id] = weightText;
    }

    // Log the set
    final loggedSet = _currentSet.copyWith(
      weight: double.tryParse(weightText),
      reps: int.tryParse(_repsCtrl.text.trim()),
      isCompleted: true,
    );
    _loggedSets[_logKey(_exerciseIndex, _setIndex)] = loggedSet;

    // If this is the very last set of the last exercise — finish
    if (_isFinished) {
      _finishWorkout();
      return;
    }

    // Start rest timer
    _startRest(_currentSet.restSeconds);
  }

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _restSecondsRemaining--);

      if (_restSecondsRemaining <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _endRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    HapticFeedback.lightImpact();
    _endRest();
  }

  void _endRest() {
    setState(() => _isResting = false);
    _advanceSet();
  }

  void _advanceSet() {
    setState(() {
      if (!_isLastSet) {
        _setIndex++;
      } else if (!_isLastExercise) {
        _exerciseIndex++;
        _setIndex = 0;
      }
    });
    _prefillInputs();
  }

  void _navigateToPreviousExercise() {
    if (_exerciseIndex == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _exerciseIndex--;
      _setIndex = 0;
      _isResting = false;
      _restTimer?.cancel();
    });
    _prefillInputs();
  }

  void _navigateToNextExercise() {
    if (_isLastExercise) return;
    HapticFeedback.selectionClick();
    setState(() {
      _exerciseIndex++;
      _setIndex = 0;
      _isResting = false;
      _restTimer?.cancel();
    });
    _prefillInputs();
  }

  void _finishWorkout() {
    _restTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _WorkoutSummaryScreen(
          routine: widget.routine,
          elapsed: DateTime.now().difference(_startTime),
          totalSetsLogged: _loggedSets.length,
        ),
      ),
    );
  }

  void _confirmQuit() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: Text(
          'End workout?',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your progress will be lost.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep going',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'End',
              style: GoogleFonts.dmSans(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: _isResting ? _buildRestScreen() : _buildSetScreen(),
    );
  }

  // ── Rest screen ───────────────────────────────────────────────────────────

  Widget _buildRestScreen() {
    final totalRest = _currentSet.restSeconds;
    final progress = totalRest > 0
        ? _restSecondsRemaining / totalRest
        : 0.0;

    final minutes = _restSecondsRemaining ~/ 60;
    final seconds = _restSecondsRemaining % 60;
    final timeLabel =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Figure out what's next
    final String nextLabel;
    if (!_isLastSet) {
      nextLabel =
          'Set ${_setIndex + 2} of ${_currentExercise.sets.length}';
    } else if (!_isLastExercise) {
      nextLabel = widget.routine.exercises[_exerciseIndex + 1].exercise.name;
    } else {
      nextLabel = 'Finish';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Text(
                  'REST',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  _elapsedLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Big countdown
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 2,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        timeLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -3,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'seconds',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Next up label
            Center(
              child: Column(
                children: [
                  Text(
                    'NEXT UP',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Skip rest button
            GestureDetector(
              onTap: _skipRest,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    'SKIP REST',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Set screen ────────────────────────────────────────────────────────────

  Widget _buildSetScreen() {
    final exercise = _currentExercise.exercise;
    final set = _currentSet;
    final isWarmUp = set.isWarmUp;
    final repRange = exercise.repRangeFor(widget.goal);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Progress: how many total sets done across all exercises
    final totalSets = widget.routine.exercises
        .fold<int>(0, (sum, e) => sum + e.sets.length);
    final completedSets = _loggedSets.length;

    return GestureDetector(
      // Tap left 1/3 → previous exercise, tap right 1/3 → next exercise
      onTapUp: (details) {
        final screenW = MediaQuery.of(context).size.width;
        final x = details.globalPosition.dx;
        if (x < screenW * 0.2) {
          _navigateToPreviousExercise();
        } else if (x > screenW * 0.8) {
          _navigateToNextExercise();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, bottomPad + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top bar ──────────────────────────────────────────────────
                Row(
                  children: [
                    // Quit
                    GestureDetector(
                      onTap: _confirmQuit,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Elapsed timer
                    Text(
                      _elapsedLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Progress bar ─────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: totalSets > 0 ? completedSets / totalSets : 0,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accent.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Exercise position label
                Row(
                  children: [
                    Text(
                      '${_exerciseIndex + 1} of ${widget.routine.exercises.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedSets / $totalSets sets',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Exercise name ─────────────────────────────────────────────
                if (isWarmUp)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'WARM UP',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                Text(
                  exercise.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 8),

                // Muscle group
                Text(
                  exercise.primaryMuscleLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.accent.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Set indicator dots ────────────────────────────────────────
                _SetDots(
                  sets: _currentExercise.sets,
                  currentSetIndex: _setIndex,
                  loggedKeys: _loggedSets.keys
                      .where((k) => k.startsWith('${_exerciseIndex}_'))
                      .map((k) => int.parse(k.split('_')[1]))
                      .toSet(),
                ),

                const SizedBox(height: 8),

                // Set label
                Text(
                  isWarmUp
                      ? 'Warm up ${_currentExercise.warmUpSets.indexOf(set) + 1} of ${_currentExercise.warmUpSets.length}'
                      : 'Set ${_currentExercise.workingSets.indexOf(set) + 1} of ${_currentExercise.workingSets.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Weight + Reps inputs ──────────────────────────────────────
                Row(
                  children: [
                    // Weight
                    Expanded(
                      child: _InputField(
                        controller: _weightCtrl,
                        label: 'WEIGHT',
                        unit: 'kg',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: '—',
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Reps
                    Expanded(
                      child: _InputField(
                        controller: _repsCtrl,
                        label: 'REPS',
                        unit: repRange != null
                            ? 'target ${repRange.min}–${repRange.max}'
                            : '',
                        keyboardType: TextInputType.number,
                        hint: '—',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ── Done button ───────────────────────────────────────────────
                GestureDetector(
                  onTap: _onDone,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _isFinished ? 'FINISH' : 'DONE',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nav hint — only show if there are multiple exercises
                if (widget.routine.exercises.length > 1)
                  Center(
                    child: Text(
                      'tap edges to browse exercises',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Set dots indicator ─────────────────────────────────────────────────────

class _SetDots extends StatelessWidget {
  const _SetDots({
    required this.sets,
    required this.currentSetIndex,
    required this.loggedKeys,
  });

  final List<WorkoutSet> sets;
  final int currentSetIndex;
  final Set<int> loggedKeys;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(sets.length, (i) {
        final isLogged = loggedKeys.contains(i);
        final isCurrent = i == currentSetIndex;
        final isWarmUp = sets[i].isWarmUp;

        Color color;
        double size;
        if (isLogged) {
          color = AppColors.accent;
          size = 8;
        } else if (isCurrent) {
          color = Colors.white.withValues(alpha: 0.6);
          size = 8;
        } else {
          color = Colors.white.withValues(alpha: 0.15);
          size = 6;
        }

        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isWarmUp && !isLogged
                ? Colors.orange.withValues(
                    alpha: isCurrent ? 0.5 : 0.2,
                  )
                : color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

// ── Input field ────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.keyboardType,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final TextInputType keyboardType;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 2.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                unit,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Input box
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Workout summary screen ─────────────────────────────────────────────────

class _WorkoutSummaryScreen extends StatelessWidget {
  const _WorkoutSummaryScreen({
    required this.routine,
    required this.elapsed,
    required this.totalSetsLogged,
  });

  final Routine routine;
  final Duration elapsed;
  final int totalSetsLogged;

  String get _elapsedLabel {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, topPad + 40, 24, bottomPad + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Done label
            Text(
              'WORKOUT DONE',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent.withValues(alpha: 0.7),
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 16),

            // Routine name
            Text(
              routine.name,
              style: GoogleFonts.dmSans(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -2,
                height: 1,
              ),
            ),

            const SizedBox(height: 48),

            // Stats row
            Row(
              children: [
                _StatCard(label: 'TIME', value: _elapsedLabel),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'SETS',
                  value: '$totalSetsLogged',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'EXERCISES',
                  value: '${routine.exerciseCount}',
                ),
              ],
            ),

            const Spacer(),

            // Back to plan
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // Pop back to root — plan screen
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'BACK TO PLAN',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}