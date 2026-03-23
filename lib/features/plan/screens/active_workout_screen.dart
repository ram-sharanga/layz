// lib/features/plan/screens/active_workout_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/workout_set.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants — all derived, never change independently
// ─────────────────────────────────────────────────────────────────────────────

const double _kTabW = 56.0;
const double _kTabH = 52.0;
const double _kTabGap = 6.0;
const double _kDrumHeight = _kTabH * 3 + _kTabGap * 2; // 168.0
const double _kWuRowH = _kTabH;
const double _kActionH = _kTabH;

// ─────────────────────────────────────────────────────────────────────────────
// Data constants
// ─────────────────────────────────────────────────────────────────────────────

const List<double> kStandardWeights = [
  0,
  1,
  1.5,
  2,
  2.5,
  3,
  4,
  5,
  6,
  7.5,
  8,
  10,
  12,
  12.5,
  15,
  17.5,
  20,
  22.5,
  25,
  27.5,
  30,
  32.5,
  35,
  37.5,
  40,
  42.5,
  45,
  47.5,
  50,
  55,
  60,
  65,
  70,
  75,
  80,
  85,
  90,
  95,
  100,
  110,
  120,
  130,
  140,
  150,
];
const List<double> kBarWeights = [10, 15, 20, 25];
const List<int> kStandardReps = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  22,
  25,
  30,
];
const List<int> kRestOptions = [30, 45, 60, 90, 120, 180];

bool _isBarbell(Equipment e) => e == Equipment.barbell || e == Equipment.ezBar;
String _lastWeightKey(String id) => 'lw_$id';
String _prKey(String id) => 'pr_$id';
const String _streakCountKey = 'streak_count';
const String _streakLastDateKey = 'streak_last_date';
String _fmt(double w) =>
    w == w.truncateToDouble() ? w.toInt().toString() : w.toString();

String _fmtDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// ActiveWorkoutScreen
// ─────────────────────────────────────────────────────────────────────────────

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

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  int _exerciseIndex = 0;

  SharedPreferences? _prefs;
  late List<List<_SetData>> _setsData;
  late List<int> _activeSetIndex;
  late List<ScrollController> _sidebarCtrls;
  final Map<String, double> _prBests = {};
  final Set<String> _newPRs = {};

  // ── Rest timer ──────────────────────────────────────────────────────────
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  bool _restActive = false;
  int _restDuration = 90; // configurable
  late AnimationController _restPulse;

  // ── Workout duration ────────────────────────────────────────────────────
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  // ── Nudge animation ─────────────────────────────────────────────────────
  late AnimationController _nudgeCtrl;
  late Animation<double> _nudgeAnim;

  @override
  void initState() {
    super.initState();
    _setsData = widget.routine.exercises
        .map((re) => re.sets.map(_SetData.fromWorkoutSet).toList())
        .toList();
    _activeSetIndex = List.filled(widget.routine.exercises.length, 0);
    _sidebarCtrls = List.generate(
      widget.routine.exercises.length,
      (_) => ScrollController(),
    );

    _restPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _nudgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nudgeAnim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _nudgeCtrl, curve: Curves.elasticOut),
    );

    // Start duration timer immediately
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    _loadPrefs();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _durationTimer?.cancel();
    _restPulse.dispose();
    _nudgeCtrl.dispose();
    for (final c in _sidebarCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < widget.routine.exercises.length; i++) {
        final id = widget.routine.exercises[i].exercise.id;
        final lw = _prefs!.getDouble(_lastWeightKey(id));
        if (lw != null) {
          int best = 0;
          double bd = double.infinity;
          for (int j = 0; j < kStandardWeights.length; j++) {
            final d = (kStandardWeights[j] - lw).abs();
            if (d < bd) {
              bd = d;
              best = j;
            }
          }
          for (final sd in _setsData[i]) sd.weightIndex = best;
        }
        final pr = _prefs!.getDouble(_prKey(id));
        if (pr != null) _prBests[id] = pr;
      }
    });
  }

  // ── Rest timer ──────────────────────────────────────────────────────────

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restActive = true;
      _restSecondsLeft = _restDuration;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _restSecondsLeft--;
        if (_restSecondsLeft <= 0) {
          _restActive = false;
          t.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restActive = false;
      _restSecondsLeft = 0;
    });
  }

  String get _restLabel {
    final m = _restSecondsLeft ~/ 60;
    final s = _restSecondsLeft % 60;
    return m > 0
        ? '$m:${s.toString().padLeft(2, '0')}'
        : '${_restSecondsLeft}s';
  }

  void _showRestConfig() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestConfigSheet(
        current: _restDuration,
        options: kRestOptions,
        onSelect: (v) {
          setState(() => _restDuration = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Nudge ───────────────────────────────────────────────────────────────

  void _triggerNudge() => _nudgeCtrl.forward(from: 0);

  // ── Navigation ──────────────────────────────────────────────────────────

  bool get _allDone =>
      _setsData.every((sets) => sets.every((s) => s.isCompleted));

  void _navigateToExercise(int i) {
    if (i < 0 || i >= widget.routine.exercises.length) return;
    HapticFeedback.selectionClick();
    setState(() => _exerciseIndex = i);
  }

  void _selectSet(int exIdx, int setIdx) {
    HapticFeedback.selectionClick();
    setState(() => _activeSetIndex[exIdx] = setIdx);
    _scrollSidebarToCenter(exIdx, setIdx);
  }

  void _scrollSidebarToCenter(int exIdx, int setIdx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = _sidebarCtrls[exIdx];
      if (!ctrl.hasClients) return;
      final nonWu = <int>[
        for (int i = 0; i < _setsData[exIdx].length; i++)
          if (!_setsData[exIdx][i].isWarmUp) i,
      ];
      final pos = nonWu.indexOf(setIdx);
      if (pos < 0) return;
      final hasNext = pos < nonWu.length - 1;
      final hasPrev = pos > 0;
      if (!(hasNext && hasPrev)) {
        if (!hasPrev)
          ctrl.animateTo(0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut);
        if (!hasNext)
          ctrl.animateTo(ctrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut);
        return;
      }
      final targetOffset = pos * (_kTabH + _kTabGap) - (_kTabH + _kTabGap);
      ctrl.animateTo(
        targetOffset.clamp(0.0, ctrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addSet(int exIdx) {
    HapticFeedback.lightImpact();
    final last = _setsData[exIdx].last;
    setState(() {
      _setsData[exIdx].add(_SetData(
        setNumber: _setsData[exIdx].length + 1,
        weightIndex: last.weightIndex,
        repsIndex: last.repsIndex,
        isWarmUp: false,
      ));
      _activeSetIndex[exIdx] = _setsData[exIdx].length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = _sidebarCtrls[exIdx];
      if (!ctrl.hasClients) return;
      ctrl.animateTo(ctrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _removeSet(int exIdx, int setIdx) {
    if (_setsData[exIdx].length <= 1) return;
    HapticFeedback.lightImpact();
    final removed = _setsData[exIdx][setIdx];
    final removedPos = setIdx;
    setState(() {
      _setsData[exIdx].removeAt(setIdx);
      _activeSetIndex[exIdx] =
          _activeSetIndex[exIdx].clamp(0, _setsData[exIdx].length - 1);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        duration: const Duration(seconds: 3),
        content: Text('Set removed',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () {
            setState(() {
              _setsData[exIdx].insert(removedPos, removed);
              _activeSetIndex[exIdx] = removedPos;
            });
          },
        ),
      ),
    );
  }

  void _toggleSet(int exIdx, int setIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      final sd = _setsData[exIdx][setIdx];
      sd.isCompleted = !sd.isCompleted;

      if (sd.isCompleted) {
        final exercise = widget.routine.exercises[exIdx].exercise;
        final weight = kStandardWeights[sd.weightIndex];
        _prefs?.setDouble(_lastWeightKey(exercise.id), weight);

        if (weight > 0) {
          final prev = _prBests[exercise.id] ?? 0;
          if (weight > prev) {
            _prBests[exercise.id] = weight;
            _newPRs.add(exercise.id);
            _prefs?.setDouble(_prKey(exercise.id), weight);
          }
        }

        _startRestTimer();

        final next =
            _setsData[exIdx].indexWhere((s) => !s.isCompleted, setIdx + 1);
        if (next != -1) {
          _activeSetIndex[exIdx] = next;
          _scrollSidebarToCenter(exIdx, next);
        } else {
          _triggerNudge();
        }
      } else {
        _cancelRestTimer();
      }
    });
  }

  Future<void> _finishWorkout() async {
    HapticFeedback.heavyImpact();
    _restTimer?.cancel();
    _durationTimer?.cancel();

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // ── Streak ──────────────────────────────────────────────────────────────
    int streak = _prefs?.getInt(_streakCountKey) ?? 0;
    final lastDateStr = _prefs?.getString(_streakLastDateKey);
    if (lastDateStr == null) {
      streak = 1;
    } else {
      final diff = today.difference(DateTime.parse(lastDateStr)).inDays;
      if (diff == 0) {
      } else if (diff == 1)
        streak += 1;
      else
        streak = 1;
    }
    await _prefs?.setInt(_streakCountKey, streak);
    await _prefs?.setString(_streakLastDateKey, todayStr);

    // ── Volume + set count ──────────────────────────────────────────────────
    double sessionVolume = 0;
    int workingSetsLog = 0;
    for (int i = 0; i < _setsData.length; i++) {
      for (final sd in _setsData[i]) {
        if (sd.isCompleted && !sd.isWarmUp) {
          sessionVolume +=
              kStandardWeights[sd.weightIndex] * kStandardReps[sd.repsIndex];
          workingSetsLog++;
        }
      }
    }
    final totalCompleted =
        _setsData.expand((s) => s).where((s) => s.isCompleted).length;
    final sessionMinutes = (_elapsedSeconds / 60).ceil();

    // ── Write cumulative stats ──────────────────────────────────────────────
    final prevWorkouts = _prefs?.getInt('total_workouts') ?? 0;
    final prevSets = _prefs?.getInt('total_sets') ?? 0;
    final prevVolume = _prefs?.getDouble('total_volume_kg') ?? 0.0;
    final prevMinutes = _prefs?.getInt('total_minutes') ?? 0;

    await _prefs?.setInt('total_workouts', prevWorkouts + 1);
    await _prefs?.setInt('total_sets', prevSets + workingSetsLog);
    await _prefs?.setDouble('total_volume_kg', prevVolume + sessionVolume);
    await _prefs?.setInt('total_minutes', prevMinutes + sessionMinutes);

    // ── Activity heatmap key: activity_YYYY-MM-DD → working sets done ──────
    // Accumulate in case user does two sessions in one day
    final actKey = 'activity_$todayStr';
    final prevAct = _prefs?.getInt(actKey) ?? 0;
    await _prefs?.setInt(actKey, prevAct + workingSetsLog);

    // ── Journey start date (set once) ──────────────────────────────────────
    final existingStart = _prefs?.getString('journey_start_date');
    if (existingStart == null) {
      await _prefs?.setString('journey_start_date', todayStr);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        routine: widget.routine,
        totalSetsLogged: totalCompleted,
        streak: streak,
        newPRExercises: _newPRs
            .map((id) => widget.routine.exercises
                .firstWhere((e) => e.exercise.id == id)
                .exercise
                .name)
            .toList(),
        elapsedSeconds: _elapsedSeconds,
        totalVolumeKg: sessionVolume,
      ),
    ));
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
        title: Text('End workout?',
            style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text('Your progress will not be saved.',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep going',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('End',
                style: GoogleFonts.dmSans(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<double> get _completionRatios => List.generate(
        widget.routine.exercises.length,
        (i) {
          final sets = _setsData[i];
          final done = sets.where((s) => s.isCompleted).length;
          return sets.isEmpty ? 0.0 : done / sets.length;
        },
      );

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final exercises = widget.routine.exercises;
    final isLast = _exerciseIndex == exercises.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _confirmQuit,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentedProgress(
                    count: exercises.length,
                    currentIndex: _exerciseIndex,
                    completionRatios: _completionRatios,
                    onTap: _navigateToExercise,
                  ),
                ),
                const SizedBox(width: 10),
                // Duration + rest config
                GestureDetector(
                  onTap: _showRestConfig,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_fmtDuration(_elapsedSeconds),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Rest timer banner ──────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: _restActive
                ? _RestBanner(
                    label: _restLabel,
                    seconds: _restSecondsLeft,
                    total: _restDuration,
                    pulse: _restPulse,
                    onSkip: _cancelRestTimer,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // ── Exercise pages ─────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _exerciseIndex,
              children: List.generate(
                exercises.length,
                (i) => _ExercisePage(
                  key: ValueKey(exercises[i].exercise.id),
                  routineExercise: exercises[i],
                  setsData: _setsData[i],
                  activeSetIndex: _activeSetIndex[i],
                  sidebarCtrl: _sidebarCtrls[i],
                  goal: widget.goal,
                  prBest: _prBests[exercises[i].exercise.id],
                  isNewPR: _newPRs.contains(exercises[i].exercise.id),
                  onSelectSet: (si) => _selectSet(i, si),
                  onToggleSet: (si) => _toggleSet(i, si),
                  onAddSet: () => _addSet(i),
                  onRemoveSet: (si) => _removeSet(i, si),
                  onWeightChanged: (si, wi) =>
                      WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _setsData[i][si].weightIndex = wi),
                  ),
                  onRepsChanged: (si, ri) =>
                      WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _setsData[i][si].repsIndex = ri),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom nav ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, botPad + 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _exerciseIndex > 0
                      ? () => _navigateToExercise(_exerciseIndex - 1)
                      : null,
                  child: AnimatedOpacity(
                    opacity: _exerciseIndex > 0 ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercises[_exerciseIndex].exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_exerciseIndex + 1} of ${exercises.length}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: !isLast
                      ? () => _navigateToExercise(_exerciseIndex + 1)
                      : _allDone
                          ? _finishWorkout
                          : null,
                  child: AnimatedOpacity(
                    opacity: (!isLast || _allDone) ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedBuilder(
                      animation: _nudgeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_nudgeAnim.value, 0),
                        child: child,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _allDone && isLast
                              ? AppColors.accent
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          _allDone && isLast
                              ? Icons.check_rounded
                              : Icons.chevron_right,
                          color: _allDone && isLast
                              ? AppColors.background
                              : AppColors.accent,
                          size: 20,
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
// Rest config sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RestConfigSheet extends StatelessWidget {
  const _RestConfigSheet({
    required this.current,
    required this.options,
    required this.onSelect,
  });
  final int current;
  final List<int> options;
  final ValueChanged<int> onSelect;

  String _label(int s) {
    if (s < 60) return '${s}s';
    if (s % 60 == 0) return '${s ~/ 60}m';
    return '${s ~/ 60}m ${s % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bot + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          Text('Rest Duration',
              style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Applied to the next rest period',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((s) {
              final sel = s == current;
              return GestureDetector(
                onTap: () => onSelect(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accent
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(_label(s),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? AppColors.background
                            : AppColors.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rest banner
// ─────────────────────────────────────────────────────────────────────────────

class _RestBanner extends StatelessWidget {
  const _RestBanner({
    required this.label,
    required this.seconds,
    required this.total,
    required this.pulse,
    required this.onSkip,
  });
  final String label;
  final int seconds, total;
  final AnimationController pulse;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = seconds / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: AppColors.accent.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent
                            .withValues(alpha: 0.4 + pulse.value * 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Rest',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSkip,
                    child: Text('Skip',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented progress
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.count,
    required this.currentIndex,
    required this.completionRatios,
    required this.onTap,
  });
  final int count, currentIndex;
  final List<double> completionRatios;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final ratio = completionRatios[i];
        final isCurrent = i == currentIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: ratio >= 1.0
                        ? AppColors.accent
                        : isCurrent
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise page
// ─────────────────────────────────────────────────────────────────────────────

class _ExercisePage extends StatelessWidget {
  const _ExercisePage({
    super.key,
    required this.routineExercise,
    required this.setsData,
    required this.activeSetIndex,
    required this.sidebarCtrl,
    required this.goal,
    required this.prBest,
    required this.isNewPR,
    required this.onSelectSet,
    required this.onToggleSet,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final RoutineExercise routineExercise;
  final List<_SetData> setsData;
  final int activeSetIndex;
  final ScrollController sidebarCtrl;
  final String goal;
  final double? prBest;
  final bool isNewPR;
  final ValueChanged<int> onSelectSet;
  final ValueChanged<int> onToggleSet;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int, int) onWeightChanged;
  final void Function(int, int) onRepsChanged;

  Exercise get exercise => routineExercise.exercise;

  @override
  Widget build(BuildContext context) {
    final repRange = exercise.repRangeFor(goal);
    final activeSet = setsData[activeSetIndex];
    final isBarbell = _isBarbell(exercise.equipment);
    final wuCount = setsData.where((s) => s.isWarmUp).length;
    final displaySetNum = activeSet.isWarmUp ? 0 : activeSetIndex - wuCount + 1;
    final hasWu = setsData.any((s) => s.isWarmUp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScrollableName(name: exercise.name),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(exercise.primaryMuscleLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.accent.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          )),
                      if (prBest != null && prBest! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNewPR
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isNewPR
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            isNewPR ? '🏆  NEW PR' : 'PR  ${_fmt(prBest!)} kg',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isNewPR
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              if (isBarbell)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _PlateCalculatorSheet(
                        totalWeight: kStandardWeights[activeSet.weightIndex],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(children: [
                        Icon(Icons.fitness_center,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Plates',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Image placeholder ──────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFF0C0C0C),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.image_outlined,
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: Text('EXERCISE PREVIEW',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Colors.white.withValues(alpha: 0.1),
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Set section ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROW A — WU tab + set title
              SizedBox(
                height: _kWuRowH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasWu)
                      _buildWuTab(setsData, activeSetIndex, onSelectSet)
                    else
                      SizedBox(width: _kTabW),
                    if (hasWu)
                      const SizedBox(width: 14)
                    else
                      const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            activeSet.isWarmUp
                                ? 'Warm up'
                                : 'Set $displaySetNum',
                            style: GoogleFonts.dmSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          if (repRange != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${repRange.min}–${repRange.max} reps',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.22),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _kTabGap),

              // ROW B — Sidebar + drums
              SizedBox(
                height: _kDrumHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _kTabW,
                      height: _kDrumHeight,
                      child: _SetSidebar(
                        setsData: setsData,
                        activeSetIndex: activeSetIndex,
                        scrollCtrl: sidebarCtrl,
                        onSelectSet: onSelectSet,
                        onRemoveSet: onRemoveSet,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _DrumRoller(
                              values: kStandardWeights.map(_fmt).toList(),
                              selectedIndex: activeSet.weightIndex,
                              unit: 'kg',
                              enabled: !activeSet.isCompleted,
                              onChanged: (wi) =>
                                  onWeightChanged(activeSetIndex, wi),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DrumRoller(
                              values: kStandardReps.map((r) => '$r').toList(),
                              selectedIndex: activeSet.repsIndex,
                              unit: 'reps',
                              enabled: !activeSet.isCompleted,
                              onChanged: (ri) =>
                                  onRepsChanged(activeSetIndex, ri),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _kTabGap),

              // ROW C — Add tab + complete button
              SizedBox(
                height: _kActionH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: onAddSet,
                      child: _GlassTab(
                        width: _kTabW,
                        height: _kActionH,
                        borderRadius: 14,
                        isDashed: true,
                        child: Icon(Icons.add,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onToggleSet(activeSetIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: activeSet.isCompleted
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: activeSet.isCompleted
                                  ? AppColors.accent.withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: activeSet.isCompleted
                              ? _CompletedSetSummary(setData: activeSet)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Mark Complete',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        )),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWuTab(List<_SetData> setsData, int activeSetIndex,
      ValueChanged<int> onSelectSet) {
    final wuIdx = setsData.indexWhere((s) => s.isWarmUp);
    if (wuIdx < 0) return const SizedBox.shrink();
    final isDone = setsData[wuIdx].isCompleted;
    return GestureDetector(
      onTap: () => onSelectSet(wuIdx),
      child: isDone
          ? _GlassTab(
              width: _kTabW,
              height: _kWuRowH,
              borderRadius: 14,
              isActive: true,
              isWarmUp: true,
              showTick: true,
              child: Text('W',
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange)),
            )
          : Container(
              width: _kTabW,
              height: _kWuRowH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              alignment: Alignment.center,
              child: Text('W',
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.withValues(alpha: 0.55))),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completed set summary — shown inside the complete button when done
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedSetSummary extends StatelessWidget {
  const _CompletedSetSummary({required this.setData});
  final _SetData setData;

  @override
  Widget build(BuildContext context) {
    final weight = kStandardWeights[setData.weightIndex];
    final reps = kStandardReps[setData.repsIndex];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.undo_rounded,
            size: 14, color: AppColors.accent.withValues(alpha: 0.45)),
        const SizedBox(width: 8),
        // Weight logged
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent.withValues(alpha: 0.6),
            ),
            children: [
              TextSpan(text: _fmt(weight)),
              TextSpan(
                text: ' kg',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              const TextSpan(text: '  ·  '),
              TextSpan(text: '$reps'),
              TextSpan(
                text: ' reps',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _SetSidebar extends StatelessWidget {
  const _SetSidebar({
    required this.setsData,
    required this.activeSetIndex,
    required this.scrollCtrl,
    required this.onSelectSet,
    required this.onRemoveSet,
  });
  final List<_SetData> setsData;
  final int activeSetIndex;
  final ScrollController scrollCtrl;
  final ValueChanged<int> onSelectSet;
  final ValueChanged<int> onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final nonWuIndices = <int>[
      for (int i = 0; i < setsData.length; i++)
        if (!setsData[i].isWarmUp) i,
    ];
    return SingleChildScrollView(
      controller: scrollCtrl,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(nonWuIndices.length, (pos) {
          final setIdx = nonWuIndices[pos];
          final sd = setsData[setIdx];
          final isActive = setIdx == activeSetIndex;
          return Padding(
            padding: EdgeInsets.only(top: pos == 0 ? 0 : _kTabGap),
            child: GestureDetector(
              onTap: () => onSelectSet(setIdx),
              onLongPress: () => onRemoveSet(setIdx),
              child: _GlassTab(
                width: _kTabW,
                height: _kTabH,
                borderRadius: 14,
                isActive: isActive,
                isDone: sd.isCompleted,
                showTick: sd.isCompleted,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${pos + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: isActive
                              ? AppColors.accent
                              : sd.isCompleted
                                  ? AppColors.accent.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.22),
                        )),
                    const SizedBox(height: 3),
                    Text('set',
                        style: GoogleFonts.dmSans(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: isActive
                              ? AppColors.accent.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.14),
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass tab
// ─────────────────────────────────────────────────────────────────────────────

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.isActive = false,
    this.isDone = false,
    this.isWarmUp = false,
    this.isDashed = false,
    this.showTick = false,
    required this.child,
  });
  final double width, height, borderRadius;
  final bool isActive, isDone, isWarmUp, isDashed, showTick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (isWarmUp
            ? Colors.orange.withValues(alpha: 0.13)
            : AppColors.accent.withValues(alpha: 0.12))
        : isDone
            ? AppColors.accent.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.04);

    final border = isActive
        ? (isWarmUp
            ? Colors.orange.withValues(alpha: 0.45)
            : AppColors.accent.withValues(alpha: 0.4))
        : isDone
            ? AppColors.accent.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: isDashed ? 0.12 : 0.09);

    final tickColor = isWarmUp ? Colors.orange : AppColors.accent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              Center(child: child),
              if (showTick)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration:
                        BoxDecoration(color: tickColor, shape: BoxShape.circle),
                    child: CustomPaint(
                      painter: _TickPainter(
                          color: AppColors.background, strokeWidth: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable name
// ─────────────────────────────────────────────────────────────────────────────

class _ScrollableName extends StatelessWidget {
  const _ScrollableName({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(right: 52),
              child: Text(name,
                  style: GoogleFonts.dmSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5,
                    height: 1.2,
                  )),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 52,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, AppColors.background],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drum roller
// ─────────────────────────────────────────────────────────────────────────────

class _DrumRoller extends StatefulWidget {
  const _DrumRoller({
    required this.values,
    required this.selectedIndex,
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });
  final List<String> values;
  final int selectedIndex;
  final String unit;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<_DrumRoller> createState() => _DrumRollerState();
}

class _DrumRollerState extends State<_DrumRoller> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_DrumRoller old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && _ctrl.hasClients) {
      if (!_ctrl.position.isScrollingNotifier.value) {
        _ctrl.jumpToItem(widget.selectedIndex);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: _ctrl,
            itemExtent: 46,
            physics:
                const FixedExtentScrollPhysics(parent: BouncingScrollPhysics()),
            perspective: 0.003,
            diameterRatio: 1.5,
            onSelectedItemChanged: widget.enabled ? widget.onChanged : null,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.values.length,
              builder: (_, i) => Center(
                child: Text(widget.values[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.35),
                    )),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surface, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.surface, Colors.transparent],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(widget.unit.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plate calculator
// ─────────────────────────────────────────────────────────────────────────────

class _PlateCalculatorSheet extends StatefulWidget {
  const _PlateCalculatorSheet({required this.totalWeight});
  final double totalWeight;

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  late double _barWeight;
  static const List<double> _plateSizes = [25, 20, 15, 10, 5, 2.5, 1.25];

  @override
  void initState() {
    super.initState();
    _barWeight = 20.0;
  }

  List<MapEntry<double, int>> get _platesPerSide {
    final perSide = (widget.totalWeight - _barWeight) / 2;
    if (perSide <= 0) return [];
    var rem = perSide;
    final result = <MapEntry<double, int>>[];
    for (final plate in _plateSizes) {
      final count = (rem / plate).floor();
      if (count > 0) {
        result.add(MapEntry(plate, count));
        rem -= plate * count;
        rem = double.parse(rem.toStringAsFixed(4));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final plates = _platesPerSide;
    final actual =
        _barWeight + plates.fold<double>(0, (s, e) => s + e.key * e.value * 2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, botPad + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          Row(children: [
            Text('Plate calculator',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Text('${_fmt(actual)} kg on bar',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 22),
          Text('BAR WEIGHT',
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5)),
          const SizedBox(height: 10),
          Row(
              children: kBarWeights.map((bw) {
            final sel = bw == _barWeight;
            return GestureDetector(
              onTap: () => setState(() => _barWeight = bw),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text('${_fmt(bw)} kg',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          sel ? AppColors.background : AppColors.textSecondary,
                    )),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),
          Text('PLATES PER SIDE',
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5)),
          const SizedBox(height: 12),
          if (plates.isEmpty)
            Text(
              widget.totalWeight <= _barWeight
                  ? 'Bar only — no plates needed'
                  : 'Target below bar weight',
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plates
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text('${_fmt(e.key)} kg  ×${e.value}',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Each side: ${plates.map((e) => '${_fmt(e.key)}×${e.value}').join(' + ')}',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tick painter
// ─────────────────────────────────────────────────────────────────────────────

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.color, this.strokeWidth = 1.8});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width / 10;
    final sh = size.height / 10;
    canvas.drawPath(
      Path()
        ..moveTo(1.5 * sw, 5 * sh)
        ..lineTo(4 * sw, 7.5 * sh)
        ..lineTo(8.5 * sw, 2.5 * sh),
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth * sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSummaryScreen — public so home can pop to it
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.routine,
    required this.totalSetsLogged,
    required this.streak,
    required this.newPRExercises,
    required this.elapsedSeconds,
    required this.totalVolumeKg,
  });
  final Routine routine;
  final int totalSetsLogged;
  final int streak;
  final List<String> newPRExercises;
  final int elapsedSeconds;
  final double totalVolumeKg;

  String get _duration => _fmtDuration(elapsedSeconds);
  String get _volume {
    if (totalVolumeKg >= 1000) {
      return '${(totalVolumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg.toStringAsFixed(0)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPad + 40, 24, botPad + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('WORKOUT DONE',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent.withValues(alpha: 0.7),
                  letterSpacing: 3,
                )),
            const SizedBox(height: 12),
            Text(routine.name,
                style: GoogleFonts.dmSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -2,
                  height: 1,
                )),

            const SizedBox(height: 32),

            // Stat cards row 1
            Row(children: [
              _StatCard(label: 'SETS', value: '$totalSetsLogged'),
              const SizedBox(width: 12),
              _StatCard(
                label: 'STREAK',
                value: '$streak',
                unit: streak == 1 ? 'day' : 'days',
                highlight: streak >= 3,
              ),
            ]),

            const SizedBox(height: 12),

            // Stat cards row 2
            Row(children: [
              _StatCard(label: 'DURATION', value: _duration),
              const SizedBox(width: 12),
              _StatCard(label: 'VOLUME', value: _volume),
            ]),

            // PRs
            if (newPRExercises.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('PERSONAL RECORDS',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 2.5,
                  )),
              const SizedBox(height: 14),
              ...newPRExercises.map((name) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      const Text('🏆', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(name,
                          style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ]),
                  )),
            ],

            const SizedBox(height: 52),

            // CTA
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                    child: Text('BACK TO HOME',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: AppColors.background,
                        ))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.unit,
    this.highlight = false,
  });
  final String label, value;
  final String? unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? AppColors.accent.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: highlight ? AppColors.accent : AppColors.textPrimary,
                height: 1,
              )),
          if (unit != null) ...[
            const SizedBox(height: 2),
            Text(unit!,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SetData
// ─────────────────────────────────────────────────────────────────────────────

class _SetData {
  int setNumber;
  int weightIndex;
  int repsIndex;
  bool isWarmUp;
  bool isCompleted = false;

  _SetData({
    required this.setNumber,
    required this.weightIndex,
    required this.repsIndex,
    required this.isWarmUp,
  });

  factory _SetData.fromWorkoutSet(WorkoutSet ws) {
    int repsIdx = 7;
    if (ws.reps != null) {
      int best = 0, bestDiff = 9999;
      for (int i = 0; i < kStandardReps.length; i++) {
        final diff = (kStandardReps[i] - ws.reps!).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = i;
        }
      }
      repsIdx = best;
    }
    return _SetData(
      setNumber: ws.setNumber,
      weightIndex: 0,
      repsIndex: repsIdx,
      isWarmUp: ws.isWarmUp,
    );
  }
}
