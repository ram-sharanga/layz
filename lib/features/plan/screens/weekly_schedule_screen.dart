import 'dart:async';
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
  late WeekDay _selectedDay;
  Routine? _selectedRoutine;

  @override
  void initState() {
    super.initState();
    _schedule = PlanService.getSchedule(widget.goal);
    _todayDay = WeekDay.fromDateTime(DateTime.now());
    _selectedDay = _todayDay;
    _loadRoutineFor(_selectedDay);
  }

  void _loadRoutineFor(WeekDay day) {
    final sd = _schedule.firstWhere((d) => d.day == day);
    if (sd.isRest) {
      setState(() => _selectedRoutine = null);
      return;
    }
    setState(
      () => _selectedRoutine = PlanService.getRoutine(
        routineName: sd.routineName!,
        userId: widget.userId,
        goal: widget.goal,
      ),
    );
  }

  void _onDayTapped(WeekDay day) {
    setState(() => _selectedDay = day);
    _loadRoutineFor(day);
  }

  void _openRoutineDetail() {
    final routine = _selectedRoutine;
    if (routine == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RoutineDetailScreen(routine: routine, goal: widget.goal),
      ),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(goal: widget.goal),
      ),
    );
  }

  ScheduleDay get _selectedSD =>
      _schedule.firstWhere((d) => d.day == _selectedDay);

  ScheduleDay? get _nextDay {
    final idx = _schedule.indexWhere((d) => d.day == _todayDay);
    if (idx < _schedule.length - 1) return _schedule[idx + 1];
    return null;
  }

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onLibraryTap: _openLibrary),
              const SizedBox(height: 16),
              _WeekGrid(
                schedule: _schedule,
                selectedDay: _selectedDay,
                onDayTapped: _onDayTapped,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sectionLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              _DayCard(
                scheduleDay: _selectedSD,
                routine: _selectedRoutine,
                isToday: isToday,
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
        Expanded(
          child: Text(
            'Your Plan',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
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
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.textPrimary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Library',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Week Grid ────────────────────────────────────────────────────────────────

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.schedule,
    required this.selectedDay,
    required this.onDayTapped,
  });
  final List<ScheduleDay> schedule;
  final WeekDay selectedDay;
  final ValueChanged<WeekDay> onDayTapped;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final unit = (W - gap * 2) / 3.6;
        final c1w = unit * 1.6;
        final c2w = unit * 1.0;
        final c3w = unit * 1.0;

        final x1 = 0.0;
        final x2 = c3w + gap;
        final x3 = c3w + gap + c2w + gap;
        final y1 = 0.0;
        final y2 = r1 + gap;
        final y3 = r1 + gap + r2 + gap;

        return SizedBox(
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x3,
                top: y1,
                width: c1w,
                height: r1 + gap + r2,
                child: GestureDetector(
                  onTap: () => onDayTapped(today.day),
                  child: _TodayHeroTile(
                    day: today,
                    isSelected: selectedDay == today.day,
                  ),
                ),
              ),
              Positioned(
                left: x1,
                top: y1,
                width: c2w,
                height: r1,
                child: _DayTile(
                  day: others[0],
                  isSelected: selectedDay == others[0].day,
                  onTap: () => onDayTapped(others[0].day),
                ),
              ),
              Positioned(
                left: x2,
                top: y1,
                width: c3w,
                height: r1,
                child: _DayTile(
                  day: others[1],
                  isSelected: selectedDay == others[1].day,
                  onTap: () => onDayTapped(others[1].day),
                ),
              ),
              Positioned(
                left: x1,
                top: y2,
                width: c2w,
                height: r2,
                child: _DayTile(
                  day: others[2],
                  isSelected: selectedDay == others[2].day,
                  onTap: () => onDayTapped(others[2].day),
                ),
              ),
              Positioned(
                left: x2,
                top: y2,
                width: c3w,
                height: r2,
                child: _DayTile(
                  day: others[3],
                  isSelected: selectedDay == others[3].day,
                  onTap: () => onDayTapped(others[3].day),
                ),
              ),
              Positioned(
                left: x1,
                top: y3,
                width: c2w + gap + c3w,
                height: r3,
                child: _DayTile(
                  day: others[4],
                  isSelected: selectedDay == others[4].day,
                  onTap: () => onDayTapped(others[4].day),
                ),
              ),
              Positioned(
                left: x3,
                top: y3,
                width: c1w,
                height: r3,
                child: _DayTile(
                  day: others[5],
                  isSelected: selectedDay == others[5].day,
                  onTap: () => onDayTapped(others[5].day),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Today hero tile ──────────────────────────────────────────────────────────

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
    _opacity = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: widget.isSelected
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
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
                  : (widget.day.routineName?.split(' ').first.toUpperCase() ??
                        '?'),
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
      ),
    );
  }
}

// ── Regular day tile ─────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });
  final ScheduleDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = WeekDay.fromDateTime(DateTime.now());
    final isPast = day.day.index < now.index;
    final isWorked = day.isCompleted;
    final isMissed = isPast && !isWorked && !day.isRest;

    Color bg;
    Color borderColor;
    double borderWidth;
    Color dayColor;
    Color nameColor;

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
      borderColor = isSelected
          ? Colors.white.withValues(alpha: 0.35)
          : AppColors.divider;
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
                  Text(
                    day.day.short.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: dayColor,
                      letterSpacing: 2,
                    ),
                  ),
                  if (day.isRest || isWorked) ...[
                    const SizedBox(height: 2),
                    Text(
                      day.isRest
                          ? 'REST'
                          : (day.routineName?.split(' ').first ?? ''),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
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
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(8, 8),
                      painter: _TickPainter(),
                    ),
                  ),
                ),
              ),

            if (isMissed)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Text(
                      'zzz',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: AppColors.textSecondary.withValues(alpha: 0.08),
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

// ── Tick painter ─────────────────────────────────────────────────────────────

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

// ── Day Card ─────────────────────────────────────────────────────────────────

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
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent e) {
      if (!mounted) return;

      final targetOffset = Offset(
        (-e.x * 4.0).clamp(-32.0, 32.0),
        (e.y * 4.0).clamp(-32.0, 32.0),
      );

      _bgOffsetNotifier.value = Offset.lerp(
        _bgOffsetNotifier.value,
        targetOffset,
        0.15,
      )!;
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _bgOffsetNotifier.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.scheduleDay.isRest) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.scheduleDay.isRest) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (!widget.scheduleDay.isRest) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRest = widget.scheduleDay.isRest;
    final routineName = widget.scheduleDay.routineName ?? '';
    final displayName = isRest
        ? 'REST'
        : routineName.split(' ').first.toUpperCase();
    final muscles = widget.routine?.muscleGroupLabel ?? '';
    final dayLabel = widget.scheduleDay.day.full.toUpperCase();

    final glowColor = isRest ? Colors.grey : AppColors.accent;
    final parallaxMultiplier = isRest ? 0.3 : 1.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: 160,
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
                  Positioned.fill(
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _bgOffsetNotifier,
                      builder: (context, offset, child) {
                        final effectiveOffset = offset * parallaxMultiplier;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Transform.translate(
                                offset: effectiveOffset * 0.4,
                                child: Align(
                                  alignment: const Alignment(0.6, -0.4),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          glowColor.withValues(alpha: 0.04),
                                          glowColor.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Transform.translate(
                                offset: effectiveOffset,
                                child: Align(
                                  alignment: const Alignment(0.9, -0.7),
                                  child: Container(
                                    width: 280,
                                    height: 280,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          glowColor.withValues(alpha: 0.09),
                                          glowColor.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // top/bottom shine
                  _buildEdgeShine(top: true),
                  _buildEdgeShine(top: false),

                  // ── Content ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.25),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ), // Reduced to tighten vertical group
                        // Row specifically for Big Text and Play Button to lock center
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: isRest
                                      ? AppColors.textSecondary
                                      : AppColors.accent,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (widget.isToday && !isRest) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: widget.onStart,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 0.5,
                                    ),
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
                            ],
                          ],
                        ),

                        if (muscles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            muscles,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.22),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
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

// ── Play icon painter ────────────────────────────────────────────────────────
// Clean equilateral-ish triangle, white fill, no vertical bar.
// ViewBox 0 0 18 22 — visually centred in its Size.

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

// ── Start icon painter (kept for reference, unused) ──────────────────────────

class _StartIconPainter extends CustomPainter {
  const _StartIconPainter({this.color = Colors.white});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(3, 3)
        ..lineTo(3, 21)
        ..lineTo(0, 24)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 4)
        ..lineTo(20, 12)
        ..lineTo(6, 20)
        ..close(),
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
        Text(
          'TOMORROW',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.divider,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        day.day.short.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.25),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        day.isRest ? 'Rest Day' : (day.routineName ?? '—'),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF282828),
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
}
