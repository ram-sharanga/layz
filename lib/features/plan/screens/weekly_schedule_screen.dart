// lib/features/plan/screens/weekly_schedule_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/screens/active_workout_screen.dart';
import 'package:layz/features/plan/screens/create_routine_screen.dart';
import 'package:layz/features/plan/screens/exercise_library_screen.dart';
import 'package:layz/features/plan/screens/routine_detail_screen.dart';
import 'package:layz/features/plan/screens/schedule_editor_screen.dart';
import 'package:layz/features/plan/services/plan_service.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({
    super.key,
    required this.goal,
    required this.userId,
  });
  final String goal;
  final String userId;

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late List<ScheduleDay> _schedule;
  late WeekDay _todayDay;
  late WeekDay _selectedDay;
  Routine? _selectedRoutine;

  // User-created routines (in addition to seed data)
  final List<Routine> _userRoutines = [];

  // Activity map — YYYY-MM-DD → sets done. Drives isCompleted on day tiles.
  final Map<String, int> _activity = {};

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _schedule = PlanService.getSchedule(widget.goal);
    _todayDay = WeekDay.fromDateTime(DateTime.now());
    _selectedDay = _todayDay;
    _loadRoutineFor(_selectedDay);
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final now = DateTime.now();
    final activityMap = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dayKey(d);
      final v = prefs.getInt('activity_$key');
      if (v != null && v > 0) activityMap[key] = v;
    }
    setState(() => _activity.addAll(activityMap));
  }

  /// Returns true if a given WeekDay had activity logged this week.
  bool _isDayCompleted(WeekDay day) {
    final now = DateTime.now();
    final today = WeekDay.fromDateTime(now);
    // Walk back through this week to find the date for this weekday
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (WeekDay.fromDateTime(d) == day) {
        return (_activity[_dayKey(d)] ?? 0) > 0;
      }
    }
    return false;
  }

  // Returns all routines (seed + user-created)
  List<Routine> get _allRoutines {
    final seedNames = PlanService.seedRoutineNames(widget.goal);
    final seedRoutines = seedNames
        .map((name) => PlanService.getRoutine(
              routineName: name,
              userId: widget.userId,
              goal: widget.goal,
            ))
        .whereType<Routine>()
        .toList();
    return [...seedRoutines, ..._userRoutines];
  }

  void _loadRoutineFor(WeekDay day) {
    final sd = _schedule.firstWhere((d) => d.day == day);
    if (sd.isRest) {
      setState(() => _selectedRoutine = null);
      return;
    }
    // Try user routines first, then seed data
    Routine? found;
    try {
      found = _userRoutines.firstWhere((r) => r.name == sd.routineName);
    } catch (_) {
      found = PlanService.getRoutine(
        routineName: sd.routineName!,
        userId: widget.userId,
        goal: widget.goal,
      );
    }
    setState(() => _selectedRoutine = found);
  }

  void _onDayTapped(WeekDay day) {
    setState(() => _selectedDay = day);
    _loadRoutineFor(day);
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _openRoutineDetail() {
    final routine = _selectedRoutine;
    if (routine == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoutineDetailScreen(routine: routine, goal: widget.goal),
    ));
  }

  void _startWorkout() {
    final routine = _selectedRoutine;
    if (routine == null) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ActiveWorkoutScreen(routine: routine, goal: widget.goal),
    ));
  }

  void _openLibrary() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExerciseLibraryScreen(goal: widget.goal),
    ));
  }

  Future<void> _openCreateRoutine() async {
    final result = await Navigator.of(context).push<Routine>(
      MaterialPageRoute(
        builder: (_) => CreateRoutineScreen(
          goal: widget.goal,
          userId: widget.userId,
        ),
      ),
    );
    if (result != null) {
      setState(() => _userRoutines.add(result));
    }
  }

  Future<void> _openScheduleEditor() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ScheduleEditorScreen(
          goal: widget.goal,
          userId: widget.userId,
          initialSchedule: _schedule,
          availableRoutines: _allRoutines,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _schedule = result['schedule'] as List<ScheduleDay>;
        final newRoutines = result['routines'] as List<Routine>;
        // Merge any new user routines
        for (final r in newRoutines) {
          if (!_userRoutines.any((ur) => ur.id == r.id) && !r.isGenerated) {
            _userRoutines.add(r);
          }
        }
        _loadRoutineFor(_selectedDay);
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  ScheduleDay get _selectedSD =>
      _schedule.firstWhere((d) => d.day == _selectedDay);

  String get _sectionLabel {
    if (_selectedDay == _todayDay) return 'TODAY';
    final isPast = _selectedDay.index < _todayDay.index;
    final name = _selectedDay.full.toUpperCase();
    return isPast ? 'LAST $name' : 'THIS $name';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isToday = _selectedDay == _todayDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPad + 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    onLibraryTap: _openLibrary,
                    onScheduleTap: _openScheduleEditor,
                  ),
                  const SizedBox(height: 24),
                  _WeekGrid(
                    schedule: _schedule,
                    selectedDay: _selectedDay,
                    onDayTapped: _onDayTapped,
                    isDayCompleted: _isDayCompleted,
                  ),
                  const SizedBox(height: 32),
                  _SectionLabel(label: _sectionLabel),
                  const SizedBox(height: 12),
                  _DayCard(
                    scheduleDay: _selectedSD,
                    routine: _selectedRoutine,
                    isToday: isToday,
                    onTap: _openRoutineDetail,
                    onStart: _startWorkout,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── My Routines section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _SectionLabel(label: 'MY ROUTINES'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openCreateRoutine,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.add,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('New',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Seed routines
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final names = PlanService.seedRoutineNames(widget.goal);
                if (i >= names.length) return null;
                final r = PlanService.getRoutine(
                  routineName: names[i],
                  userId: widget.userId,
                  goal: widget.goal,
                );
                if (r == null) return null;
                return _RoutineTile(
                  routine: r,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        RoutineDetailScreen(routine: r, goal: widget.goal),
                  )),
                  onStart: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ActiveWorkoutScreen(routine: r, goal: widget.goal),
                    ));
                  },
                );
              },
              childCount: PlanService.seedRoutineNames(widget.goal).length,
            ),
          ),

          // User-created routines
          if (_userRoutines.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i >= _userRoutines.length) return null;
                  final r = _userRoutines[i];
                  return _RoutineTile(
                    routine: r,
                    isCustom: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          RoutineDetailScreen(routine: r, goal: widget.goal),
                    )),
                    onStart: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ActiveWorkoutScreen(routine: r, goal: widget.goal),
                      ));
                    },
                    onEdit: () async {
                      final result = await Navigator.of(context)
                          .push<Routine>(MaterialPageRoute(
                        builder: (_) => CreateRoutineScreen(
                          goal: widget.goal,
                          userId: widget.userId,
                          existingRoutine: r,
                        ),
                      ));
                      if (result != null) {
                        setState(() {
                          final idx =
                              _userRoutines.indexWhere((ur) => ur.id == r.id);
                          if (idx >= 0) _userRoutines[idx] = result;
                        });
                      }
                    },
                  );
                },
                childCount: _userRoutines.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Routine tile — shown in the My Routines list
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({
    required this.routine,
    required this.onTap,
    required this.onStart,
    this.onEdit,
    this.isCustom = false,
  });
  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback? onEdit;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(routine.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    if (isCustom) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2)),
                        ),
                        child: Text('CUSTOM',
                            style: GoogleFonts.dmSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 1,
                            )),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${routine.exerciseCount} exercises · ${routine.muscleGroupLabel} · ${routine.estimatedLabel}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Edit if custom
            if (isCustom && onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
            // Start button
            GestureDetector(
              onTap: onStart,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    size: 18, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 3.5,
          )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onLibraryTap, required this.onScheduleTap});
  final VoidCallback onLibraryTap;
  final VoidCallback onScheduleTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Your Plan',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              )),
        ),
        GestureDetector(
          onTap: onScheduleTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.textPrimary, size: 14),
              const SizedBox(width: 6),
              Text('Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  )),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onLibraryTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              const Icon(Icons.fitness_center,
                  color: AppColors.textPrimary, size: 14),
              const SizedBox(width: 6),
              Text('Library',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  )),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week Grid — identical layout math as original
// ─────────────────────────────────────────────────────────────────────────────

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.schedule,
    required this.selectedDay,
    required this.onDayTapped,
    required this.isDayCompleted,
  });
  final List<ScheduleDay> schedule;
  final WeekDay selectedDay;
  final ValueChanged<WeekDay> onDayTapped;
  final bool Function(WeekDay) isDayCompleted;

  @override
  Widget build(BuildContext context) {
    final todayIdx = schedule.indexWhere((d) => d.isToday);
    final today = schedule[todayIdx >= 0 ? todayIdx : 0];
    final others = <ScheduleDay>[];
    for (int i = 1; i <= 6; i++) {
      others.add(schedule[(todayIdx + i) % 7]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final gap = (W * 0.014).roundToDouble();
        final cSmall = (W - 2 * gap) / 3.6;
        final cHero = cSmall * 1.6;
        final rShort = cSmall * 0.75;
        final rTall = rShort * 1.6;
        final totalH = rTall + rShort * 2 + gap * 2;

        final x0 = 0.0;
        final x1 = cSmall + gap;
        final x2 = cSmall * 2 + gap * 2;
        final y0 = 0.0;
        final y1 = rTall + gap;
        final y2 = rTall + rShort + gap * 2;

        return SizedBox(
          height: totalH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                  left: x2,
                  top: y0,
                  width: cHero,
                  height: rTall + gap + rShort,
                  child: GestureDetector(
                    onTap: () => onDayTapped(today.day),
                    child: _TodayHeroTile(
                        day: today, isSelected: selectedDay == today.day),
                  )),
              Positioned(
                  left: x0,
                  top: y0,
                  width: cSmall,
                  height: rTall,
                  child: _DayTile(
                      day: others[0],
                      isSelected: selectedDay == others[0].day,
                      isCompleted: isDayCompleted(others[0].day),
                      onTap: () => onDayTapped(others[0].day))),
              Positioned(
                  left: x1,
                  top: y0,
                  width: cSmall,
                  height: rTall,
                  child: _DayTile(
                      day: others[1],
                      isSelected: selectedDay == others[1].day,
                      isCompleted: isDayCompleted(others[1].day),
                      onTap: () => onDayTapped(others[1].day))),
              Positioned(
                  left: x0,
                  top: y1,
                  width: cSmall,
                  height: rShort,
                  child: _DayTile(
                      day: others[2],
                      isSelected: selectedDay == others[2].day,
                      isCompleted: isDayCompleted(others[2].day),
                      onTap: () => onDayTapped(others[2].day))),
              Positioned(
                  left: x1,
                  top: y1,
                  width: cSmall,
                  height: rShort,
                  child: _DayTile(
                      day: others[3],
                      isSelected: selectedDay == others[3].day,
                      isCompleted: isDayCompleted(others[3].day),
                      onTap: () => onDayTapped(others[3].day))),
              Positioned(
                  left: x0,
                  top: y2,
                  width: cSmall * 2 + gap,
                  height: rShort,
                  child: _DayTile(
                      day: others[4],
                      isSelected: selectedDay == others[4].day,
                      isCompleted: isDayCompleted(others[4].day),
                      onTap: () => onDayTapped(others[4].day))),
              Positioned(
                  left: x2,
                  top: y2,
                  width: cHero,
                  height: rShort,
                  child: _DayTile(
                      day: others[5],
                      isSelected: selectedDay == others[5].day,
                      isCompleted: isDayCompleted(others[5].day),
                      onTap: () => onDayTapped(others[5].day))),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today hero tile
// ─────────────────────────────────────────────────────────────────────────────

class _TodayHeroTile extends StatefulWidget {
  const _TodayHeroTile({required this.day, required this.isSelected});
  final ScheduleDay day;
  final bool isSelected;

  @override
  State<_TodayHeroTile> createState() => _TodayHeroTileState();
}

class _TodayHeroTileState extends State<_TodayHeroTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.day.isRest
        ? 'REST'
        : (widget.day.routineName?.split(' ').first.toUpperCase() ?? '?');

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: widget.isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TODAY · ${widget.day.day.short.toUpperCase()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                )),
            const SizedBox(height: 4),
            Text(displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                  height: 1.0,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular day tile
// ─────────────────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isSelected,
    required this.isCompleted,
    required this.onTap,
  });
  final ScheduleDay day;
  final bool isSelected;
  final bool isCompleted; // ← from real activity_ SharedPreferences data
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = WeekDay.fromDateTime(DateTime.now());
    final isPast = day.day.index < now.index;
    final isWorked = isCompleted; // ← real data, not day.isCompleted
    final isMissed = isPast && !isWorked && !day.isRest;

    Color bg, borderColor;
    double borderWidth;
    Color dayColor, nameColor;

    if (isWorked) {
      bg = const Color(0xFF0b1600);
      borderColor = isSelected
          ? AppColors.accent
          : AppColors.accent.withValues(alpha: 0.35);
      borderWidth = isSelected ? 1.5 : 1.0;
      dayColor = AppColors.accent.withValues(alpha: 0.6);
      nameColor = AppColors.accent;
    } else {
      bg = AppColors.surface;
      borderColor =
          isSelected ? Colors.white.withValues(alpha: 0.35) : AppColors.divider;
      borderWidth = isSelected ? 1.5 : 1.0;
      dayColor = AppColors.textSecondary;
      nameColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(day.day.short.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: dayColor,
                        letterSpacing: 2,
                      )),
                  if (day.isRest || isWorked) ...[
                    const SizedBox(height: 2),
                    Text(
                        day.isRest
                            ? 'REST'
                            : (day.routineName?.split(' ').first ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: nameColor,
                          letterSpacing: -0.3,
                          height: 1.1,
                        )),
                  ],
                ],
              ),
            ),
            if (isWorked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child: Center(
                      child: CustomPaint(
                          size: const Size(8, 8), painter: _TickPainter())),
                ),
              ),
            if (isMissed)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Text('zzz',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.08),
                        )),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 10;
    final sy = size.height / 10;
    canvas.drawPath(
      Path()
        ..moveTo(1.5 * sx, 5 * sy)
        ..lineTo(4 * sx, 7.5 * sy)
        ..lineTo(8.5 * sx, 2.5 * sy),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 1.8 * sx
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Card — today's workout card with parallax
// ─────────────────────────────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.scheduleDay,
    required this.routine,
    required this.isToday,
    required this.onTap,
    required this.onStart,
  });
  final ScheduleDay scheduleDay;
  final Routine? routine;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  final ValueNotifier<Offset> _bgOffsetNotifier = ValueNotifier(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEventStream().listen((e) {
      if (!mounted) return;
      _bgOffsetNotifier.value = Offset.lerp(
        _bgOffsetNotifier.value,
        Offset((-e.x * 6.0).clamp(-48.0, 48.0), (e.y * 6.0).clamp(-48.0, 48.0)),
        0.08,
      )!;
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _bgOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRest = widget.scheduleDay.isRest;
    final routineName = widget.scheduleDay.routineName ?? '';
    final displayName =
        isRest ? 'REST' : routineName.split(' ').first.toUpperCase();
    final muscles = widget.routine?.muscleGroupLabel ?? '';
    final glowColor = isRest ? Colors.grey : AppColors.accent;

    const double cardH = 150.0;
    const double hPad = 24.0;
    const double labelTop = 22.0;
    const double titleCY = cardH / 2;
    const double titleTop = titleCY - 30.0;
    const double musclesBot = 18.0;

    return GestureDetector(
      onTapDown: (_) {
        if (!isRest) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!isRest) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!isRest) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: cardH,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(23.5),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  // Parallax glows
                  Positioned.fill(
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _bgOffsetNotifier,
                      builder: (_, offset, __) => Stack(children: [
                        Positioned.fill(
                          child: Transform.translate(
                            offset: offset * 0.3,
                            child: Align(
                              alignment: const Alignment(0.6, -0.4),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    glowColor.withValues(alpha: 0.04),
                                    glowColor.withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Transform.translate(
                            offset: offset,
                            child: Align(
                              alignment: const Alignment(0.9, -0.7),
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    glowColor.withValues(alpha: 0.09),
                                    glowColor.withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // Edge shines
                  _buildEdgeShine(top: true),
                  _buildEdgeShine(top: false),

                  // Day label — pinned top-left
                  Positioned(
                    top: labelTop,
                    left: hPad,
                    right: hPad,
                    child: Text(widget.scheduleDay.day.full.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.25),
                          letterSpacing: 3,
                        )),
                  ),

                  // Title row — fixed vertical center
                  Positioned(
                    top: titleTop,
                    left: hPad,
                    right: hPad,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                                color: isRest
                                    ? AppColors.textSecondary
                                    : AppColors.accent,
                                letterSpacing: -2,
                                height: 1,
                              )),
                        ),
                        const SizedBox(width: 12),
                        // Start button — always takes space, invisible when not shown
                        Opacity(
                          opacity: (widget.isToday && !isRest) ? 1.0 : 0.0,
                          child: GestureDetector(
                            onTap: (widget.isToday && !isRest)
                                ? widget.onStart
                                : null,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 0.5),
                              ),
                              child: Center(
                                child: Transform.translate(
                                  offset: const Offset(2, 0),
                                  child: CustomPaint(
                                    size: const Size(18, 22),
                                    painter: _PlayIconPainter(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Muscles — pinned bottom
                  if (muscles.isNotEmpty)
                    Positioned(
                      bottom: musclesBot,
                      left: hPad,
                      right: hPad,
                      child: Text(muscles,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.22),
                            letterSpacing: 0.5,
                          )),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeShine({required bool top}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 20,
      right: 20,
      height: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: top ? 0.3 : 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
