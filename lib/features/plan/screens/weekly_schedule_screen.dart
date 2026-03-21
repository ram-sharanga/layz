// lib/features/plan/screens/weekly_schedule_screen.dart
//
// pubspec.yaml — add this dependency:
//   sensors_plus: ^4.0.0

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/screens/exercise_library_screen.dart';
import 'package:layz/features/plan/screens/routine_detail_screen.dart';
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
  Routine? _todayRoutine;

  @override
  void initState() {
    super.initState();
    _schedule = PlanService.getSchedule(widget.goal);
    _todayDay = WeekDay.fromDateTime(DateTime.now());
    _loadTodayRoutine();
  }

  void _loadTodayRoutine() {
    final sd = _schedule.firstWhere((d) => d.day == _todayDay);
    if (sd.isRest) { setState(() => _todayRoutine = null); return; }
    setState(() => _todayRoutine = PlanService.getRoutine(
      routineName: sd.routineName!,
      userId: widget.userId,
      goal: widget.goal,
    ));
  }

  void _openRoutineDetail() {
    if (_todayRoutine == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoutineDetailScreen(routine: _todayRoutine!, goal: widget.goal),
    ));
  }

  void _openLibrary() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExerciseLibraryScreen(goal: widget.goal),
    ));
  }

  ScheduleDay get _todaySD => _schedule.firstWhere((d) => d.day == _todayDay);

  ScheduleDay? get _nextDay {
    final idx = _schedule.indexWhere((d) => d.day == _todayDay);
    if (idx < _schedule.length - 1) return _schedule[idx + 1];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onLibraryTap: _openLibrary),
              const SizedBox(height: 16),
              _WeekGrid(schedule: _schedule),
              const SizedBox(height: 16),
              // TODAY label
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('TODAY', style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 3,
                    )),
                  ],
                ),
              ),
              _TodayCard(
                scheduleDay: _todaySD,
                routine: _todayRoutine,
                onTap: _openRoutineDetail,
                onStart: _openRoutineDetail,
              ),
              const SizedBox(height: 20),
              if (_nextDay != null) _ComingUp(day: _nextDay!),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onLibraryTap});
  final VoidCallback onLibraryTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Your Plan', style: GoogleFonts.dmSans(
          fontSize: 26, fontWeight: FontWeight.w900,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ))),
        GestureDetector(
          onTap: onLibraryTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: AppColors.textPrimary, size: 14),
                const SizedBox(width: 6),
                Text('Library', style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Week Grid ────────────────────────────────────────────────────────────────
// grid-template-columns: 1.6fr 1fr 1fr
// grid-template-rows: 100px 60px 60px
// gap: 5px
// c1: col1 row1/3 — today hero spans rows 1+2
// c2: col2 row1 | c3: col3 row1
// c4: col2 row2 | c5: col3 row2
// c6: col1 row3 | c7: col2/4 row3

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.schedule});
  final List<ScheduleDay> schedule;

  @override
  Widget build(BuildContext context) {
    final todayIdx = schedule.indexWhere((d) => d.isToday);
    final today = schedule[todayIdx >= 0 ? todayIdx : 0];
    final others = <ScheduleDay>[];
    for (int i = 1; i <= 6; i++) {
      others.add(schedule[(todayIdx + i) % 7]);
    }

    const double gap = 5;
    const double r1 = 100;
    const double r2 = 60;
    const double r3 = 60;
    const double totalH = r1 + gap + r2 + gap + r3;

    return LayoutBuilder(builder: (context, constraints) {
      final W = constraints.maxWidth;
      final unit = (W - gap * 2) / 3.6;
      final c1w = unit * 1.6;
      final c2w = unit * 1.0;
      final c3w = unit * 1.0;
      final x1 = 0.0;
      final x2 = c1w + gap;
      final x3 = c1w + gap + c2w + gap;
      final y1 = 0.0;
      final y2 = r1 + gap;
      final y3 = r1 + gap + r2 + gap;

      return SizedBox(
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: x1, top: y1, width: c1w, height: r1 + gap + r2,
              child: _TodayHeroTile(day: today)),
            Positioned(left: x2, top: y1, width: c2w, height: r1,
              child: _DayTile(day: others[0])),
            Positioned(left: x3, top: y1, width: c3w, height: r1,
              child: _DayTile(day: others[1])),
            Positioned(left: x2, top: y2, width: c2w, height: r2,
              child: _DayTile(day: others[2])),
            Positioned(left: x3, top: y2, width: c3w, height: r2,
              child: _DayTile(day: others[3])),
            Positioned(left: x1, top: y3, width: c1w, height: r3,
              child: _DayTile(day: others[4])),
            Positioned(left: x2, top: y3, width: c2w + gap + c3w, height: r3,
              child: _DayTile(day: others[5])),
          ],
        ),
      );
    });
  }
}

// ── Today hero tile ──────────────────────────────────────────────────────────
// HTML: .today { background:#AAFF00; animation:throb 2s ease infinite }
// @keyframes throb {
//   0%,100% { box-shadow: 0 0 0 0 rgba(170,255,0,0.5), 0 0 10px rgba(170,255,0,0.08) }
//   55%     { box-shadow: 0 0 0 7px rgba(170,255,0,0), 0 0 22px rgba(170,255,0,0.22) }
// }
// No border. Outward box-shadow only. Text centered.
// TODAY · [DAY] at 12px w700 white 0.5 alpha
// Routine first word at 28px w900 white

class _TodayHeroTile extends StatefulWidget {
  const _TodayHeroTile({required this.day});
  final ScheduleDay day;

  @override
  State<_TodayHeroTile> createState() => _TodayHeroTileState();
}

class _TodayHeroTileState extends State<_TodayHeroTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = (math.sin(_ctrl.value * 2 * math.pi) * 0.5 + 0.5);
        // shadow1: spread 0→7, opacity 0.5→0
        // shadow2: blur 10→22, opacity 0.08→0.22
        return Container(
          // margin gives outward shadow room — doesn't touch neighbours
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            // solid bg so interior is blocked — glow shows on outside only
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5 * (1 - p)),
                blurRadius: 0,
                spreadRadius: 7 * p,
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08 + 0.14 * p),
                blurRadius: 10 + 12 * p,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TODAY · ${widget.day.day.short.toUpperCase()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.day.isRest
                    ? '—'
                    : (widget.day.routineName?.split(' ').first.toUpperCase() ?? '?'),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Regular day tile ─────────────────────────────────────────────────────────
// HTML states:
// worked: bg #0b1600, border rgba(170,255,0,0.35) 1px  ← HARDCODED: needs AppColors.workedBg
// missed: bg #060606, border #0f0f0f 0.5px              ← HARDCODED: near-black
// rest:   bg #040404, border #090909 0.5px              ← HARDCODED: near-black
// future: bg #080808, border #0e0e0e 0.5px              ← HARDCODED: near-black
// day label: 9px w700 | name: 15px w900

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});
  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    final now = WeekDay.fromDateTime(DateTime.now());
    final isPast = day.day.index < now.index;
    final isWorked = day.isCompleted;
    final isMissed = isPast && !isWorked && !day.isRest;

    // ── Colors per HTML state ──
    // HARDCODED note: 0xFF0b1600 = worked bg (dark lime tint, no AppColors equivalent)
    // HARDCODED note: 0xFF1a1a1a, 0xFF141414, 0xFF1c1c1c, 0xFF181818 = near-blacks
    // Suggestion: add AppColors.workedBg = Color(0xFF0b1600)
    Color bg;
    Color borderColor;
    double borderWidth;
    Color dayColor;
    Color nameColor;

    if (isWorked) {
      bg          = const Color(0xFF0b1600);
      borderColor = AppColors.accent.withValues(alpha: 0.35);
      borderWidth = 1.0;
      dayColor    = AppColors.accent.withValues(alpha: 0.6);
      nameColor   = AppColors.accent;
    } else if (isMissed) {
      bg          = AppColors.surface;
      borderColor = AppColors.divider;
      borderWidth = 1.0;
      dayColor    = AppColors.textSecondary;
      nameColor   = AppColors.textPrimary;
    } else if (day.isRest) {
      bg          = AppColors.surface;
      borderColor = AppColors.divider;
      borderWidth = 1.0;
      dayColor    = AppColors.textSecondary;
      nameColor   = AppColors.textPrimary;
    } else {
      bg          = AppColors.surface;
      borderColor = AppColors.divider;
      borderWidth = 1.0;
      dayColor    = AppColors.textSecondary;
      nameColor   = AppColors.textPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Content — day label + REST label if rest, day only otherwise
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  day.day.short.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: dayColor, letterSpacing: 2,
                  ),
                ),
                // only show name for rest and worked — others show day only
                if (day.isRest || isWorked) ...[
                  const SizedBox(height: 2),
                  Text(
                    day.isRest ? 'REST' : (day.routineName?.split(' ').first ?? ''),
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: nameColor, letterSpacing: -0.3, height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkmark for worked
          if (isWorked)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle,
                ),
                child: Center(child: CustomPaint(
                  size: const Size(8, 8), painter: _TickPainter(),
                )),
              ),
            ),

          // ZZZ — bottom right, tilted, ghost watermark style
          if (isMissed)
            Positioned(
              bottom: -4, right: -2,
              child: Transform.rotate(
                angle: -0.25,
                child: Text(
                  'zzz',
                  style: GoogleFonts.dmSans(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary.withValues(alpha: 0.15),
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tick painter ─────────────────────────────────────────────────────────────
// SVG: <polyline points="1.5,5 4,7.5 8.5,2.5"
//       stroke="#000" stroke-width="1.8"
//       stroke-linecap="round" stroke-linejoin="round"/>
// viewBox: 0 0 10 10, painted into Size(8,8)

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

// ── Today Card ───────────────────────────────────────────────────────────────
// Liquid glass: stronger bg + border + dual shine lines + glow
// Parallax: accelerometer tilt drives bg layer offset

class _TodayCard extends StatefulWidget {
  const _TodayCard({
    required this.scheduleDay,
    required this.routine,
    required this.onTap,
    required this.onStart,
  });
  final ScheduleDay scheduleDay;
  final Routine? routine;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  Offset _bgOffset = Offset.zero;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent e) {
      if (!mounted) return;
      setState(() {
        _bgOffset = Offset(
          (-e.x * 1.8).clamp(-18.0, 18.0),
          (e.y * 1.8).clamp(-18.0, 18.0),
        );
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRest = widget.scheduleDay.isRest;
    final routineName = widget.scheduleDay.routineName ?? '';
    final displayName = isRest ? 'REST' : routineName.split(' ').first.toUpperCase();
    final muscles = widget.routine?.muscleGroupLabel ?? '';
    final dayLabel = widget.scheduleDay.day.full.toUpperCase();

    return GestureDetector(
      onTap: isRest ? null : widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // liquid glass — visible frosted fill
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [

            // bg parallax layer — moves with device tilt
            Positioned(
              left: 0, top: 0, right: 0, height: 200,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  _bgOffset.dx, _bgOffset.dy, 0,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -40, right: 10,
                      width: 210, height: 210,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.22),
                              AppColors.accent.withValues(alpha: 0),
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // top shine — brighter for glass feel
            Positioned(
              top: 0, left: 20, right: 20, height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // bottom shine — subtle light catch
            Positioned(
              bottom: 0, left: 20, right: 20, height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // foreground — locked, never moves
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dayLabel, style: GoogleFonts.dmSans(
                          fontSize: 9, fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.25),
                          letterSpacing: 3,
                        )),
                        const SizedBox(height: 10),
                        Text(displayName, style: GoogleFonts.dmSans(
                          fontSize: 60, fontWeight: FontWeight.w900,
                          color: isRest ? AppColors.textSecondary : AppColors.accent,
                          letterSpacing: -2, height: 0.85,
                        )),
                        if (muscles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(muscles, style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.22),
                            letterSpacing: 0.5,
                          )),
                        ],
                      ],
                    ),
                  ),
                  if (!isRest)
                    GestureDetector(
                      onTap: widget.onStart,
                      child: Container(
                        width: 62, height: 62,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Center(
                          child: SizedBox(
                            width: 22, height: 26,
                            child: CustomPaint(painter: _StartIconPainter()),
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
    );
  }
}

// ── Start icon painter ───────────────────────────────────────────────────────
// viewBox 0 0 20 24
// trap: 0,0 → 3,3 → 3,21 → 0,24
// tri:  6,4 → 20,12 → 6,20

class _StartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()..moveTo(0,0)..lineTo(3,3)..lineTo(3,21)..lineTo(0,24)..close(),
      paint,
    );
    canvas.drawPath(
      Path()..moveTo(6,4)..lineTo(20,12)..lineTo(6,20)..close(),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Coming up ────────────────────────────────────────────────────────────────

class _ComingUp extends StatelessWidget {
  const _ComingUp({required this.day});
  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOMORROW', style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: AppColors.divider, letterSpacing: 2.5,
        )),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.6), width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08), width: 0.5,
                        ),
                      ),
                      child: Text(day.day.short.toUpperCase(), style: GoogleFonts.dmSans(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.25),
                        letterSpacing: 1.5,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      day.isRest ? 'Rest Day' : (day.routineName ?? '—'),
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF282828),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}