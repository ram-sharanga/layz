import 'dart:async';
import 'package:flutter/material.dart';
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
              const SizedBox(height: 24),
              _WeekGrid(
                schedule: _schedule,
                selectedDay: _selectedDay,
                onDayTapped: _onDayTapped,
              ),
              const SizedBox(height: 32),
              _SectionLabel(label: _sectionLabel),
              const SizedBox(height: 12),
              _DayCard(
                scheduleDay: _selectedSD,
                routine: _selectedRoutine,
                isToday: isToday,
                onTap: _openRoutineDetail,
                onStart: _openRoutineDetail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

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

    // All sizing is relative to available width — nothing hardcoded in pixels.
    // Gap is 1.4% of screen width so it scales too.
    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final gap = (W * 0.014).roundToDouble(); // ~5px on 360w, scales up

        // Column width ratios: left pair : middle pair : right hero = 1 : 1 : 1.6
        // Total ratio units = 1 + gap + 1 + gap + 1.6 = 3.6 + 2*gap_ratio
        // Solve: cSmall = (W - 2*gap) / 3.6
        final cSmall = (W - 2 * gap) / 3.6;
        final cHero = cSmall * 1.6;

        // Row height ratios: top : mid : bottom = 1.6 : 1 : 1
        // Total ratio units = 1.6 + 1 + 1 + 2*gap = 3.6 + 2*gap
        // We let height = width of the two small columns + gaps (square-ish feel)
        final rShort = cSmall * 0.75; // proportional to column width
        final rTall = rShort * 1.6; // maintains the tall:short = 1.6:1 ratio
        final totalH = rTall + rShort * 2 + gap * 2;

        final x0 = 0.0;
        final x1 = cSmall + gap;
        final x2 = cSmall * 2 + gap * 2; // hero starts here

        final y0 = 0.0;
        final y1 = rTall + gap;
        final y2 = rTall + rShort + gap * 2;

        return SizedBox(
          height: totalH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Hero tile — today, spans top two rows
              Positioned(
                left: x2,
                top: y0,
                width: cHero,
                height: rTall + gap + rShort,
                child: GestureDetector(
                  onTap: () => onDayTapped(today.day),
                  child: _TodayHeroTile(
                    day: today,
                    isSelected: selectedDay == today.day,
                  ),
                ),
              ),
              // Row 1, col 0
              Positioned(
                left: x0,
                top: y0,
                width: cSmall,
                height: rTall,
                child: _DayTile(
                  day: others[0],
                  isSelected: selectedDay == others[0].day,
                  onTap: () => onDayTapped(others[0].day),
                ),
              ),
              // Row 1, col 1
              Positioned(
                left: x1,
                top: y0,
                width: cSmall,
                height: rTall,
                child: _DayTile(
                  day: others[1],
                  isSelected: selectedDay == others[1].day,
                  onTap: () => onDayTapped(others[1].day),
                ),
              ),
              // Row 2, col 0
              Positioned(
                left: x0,
                top: y1,
                width: cSmall,
                height: rShort,
                child: _DayTile(
                  day: others[2],
                  isSelected: selectedDay == others[2].day,
                  onTap: () => onDayTapped(others[2].day),
                ),
              ),
              // Row 2, col 1
              Positioned(
                left: x1,
                top: y1,
                width: cSmall,
                height: rShort,
                child: _DayTile(
                  day: others[3],
                  isSelected: selectedDay == others[3].day,
                  onTap: () => onDayTapped(others[3].day),
                ),
              ),
              // Row 3, col 0+1 merged (wide short tile)
              Positioned(
                left: x0,
                top: y2,
                width: cSmall * 2 + gap,
                height: rShort,
                child: _DayTile(
                  day: others[4],
                  isSelected: selectedDay == others[4].day,
                  onTap: () => onDayTapped(others[4].day),
                ),
              ),
              // Row 3, hero col (short)
              Positioned(
                left: x2,
                top: y2,
                width: cHero,
                height: rShort,
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
    // Derive display name — show REST instead of '—' for rest days
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
              displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        (-e.x * 6.0).clamp(-48.0, 48.0),
        (e.y * 6.0).clamp(-48.0, 48.0),
      );

      _bgOffsetNotifier.value = Offset.lerp(
        _bgOffsetNotifier.value,
        targetOffset,
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

    // Card height is fixed so rest vs workout, today vs other — all identical height.
    // Internally we use a Stack with Positioned elements so nothing shifts:
    //   • Day label  — pinned top-left
    //   • Title row  — always vertically centered in the card
    //   • Muscles    — pinned bottom-left, only rendered when non-empty
    // Play button sits in the title row alongside the display name.
    // Since both display name and button are 60px tall and CrossAxisAlignment.start,
    // their tops are locked — no shift whether button is present or not.
    const double cardHeight = 150.0;
    const double hPad = 24.0;
    const double labelTop = 22.0;
    // Center of card minus half of title height (60px font, height:1.0 = 60px)
    const double titleCenterY = cardHeight / 2;
    const double titleTop = titleCenterY - 30.0; // 30 = 60/2
    const double musclesBottom = 18.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: cardHeight,
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
                  // ── Parallax glows ─────────────────────────────────────────
                  Positioned.fill(
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _bgOffsetNotifier,
                      builder: (context, offset, child) {
                        final effectiveOffset = offset * parallaxMultiplier;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Transform.translate(
                                offset: effectiveOffset * 0.3,
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

                  // ── Edge shines ────────────────────────────────────────────
                  _buildEdgeShine(top: true),
                  _buildEdgeShine(top: false),

                  // ── Day label — pinned top-left ────────────────────────────
                  Positioned(
                    top: labelTop,
                    left: hPad,
                    right: hPad,
                    child: Text(
                      dayLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.25),
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  // ── Title row — always at fixed vertical center ────────────
                  // Play button (60×60) is always in the Row.
                  // On non-today or rest days it is Opacity(0) so it takes
                  // up space without rendering — title position never shifts.
                  Positioned(
                    top: titleTop,
                    left: hPad,
                    right: hPad,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Button slot — always present, invisible when not needed
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
                        ),
                      ],
                    ),
                  ),

                  // ── Muscles — pinned bottom-left, only when present ─────────
                  if (muscles.isNotEmpty)
                    Positioned(
                      bottom: musclesBottom,
                      left: hPad,
                      right: hPad,
                      child: Text(
                        muscles,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.22),
                          letterSpacing: 0.5,
                        ),
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
