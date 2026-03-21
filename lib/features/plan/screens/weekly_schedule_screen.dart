import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/screens/exercise_library_screen.dart';
import 'package:layz/features/plan/screens/routine_detail_screen.dart';
import 'package:layz/features/plan/services/plan_service.dart';
import 'package:layz/features/plan/widgets/day_strip.dart';
import 'package:layz/features/plan/widgets/today_card.dart';

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
  late WeekDay _selectedDay;
  Routine? _selectedRoutine;

  @override
  void initState() {
    super.initState();
    _schedule = PlanService.getSchedule(widget.goal);

    // Default selected day = today
    _selectedDay = WeekDay.fromDateTime(DateTime.now());

    // Load today's routine
    _loadRoutineFor(_selectedDay);
  }

  void _loadRoutineFor(WeekDay day) {
    final scheduleDay = _schedule.firstWhere((d) => d.day == day);
    if (scheduleDay.isRest) {
      setState(() => _selectedRoutine = null);
      return;
    }
    final routine = PlanService.getRoutine(
      routineName: scheduleDay.routineName!,
      userId: widget.userId,
      goal: widget.goal,
    );
    setState(() => _selectedRoutine = routine);
  }

  void _onDayTapped(WeekDay day) {
    setState(() => _selectedDay = day);
    _loadRoutineFor(day);
  }

  void _openRoutineDetail() {
    if (_selectedRoutine == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineDetailScreen(
          routine: _selectedRoutine!,
          goal: widget.goal,
        ),
      ),
    );
  }

  void _startWorkout() {
    // TODO: navigate to warm up screen then active workout
    // For now opens routine detail
    _openRoutineDetail();
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(goal: widget.goal),
      ),
    );
  }

  ScheduleDay get _currentScheduleDay =>
      _schedule.firstWhere((d) => d.day == _selectedDay);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ── Header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Plan',
                      style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Exercise library shortcut
                  GestureDetector(
                    onTap: _openLibrary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: AppColors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Library',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Day strip ────────────────────────────────
          SliverToBoxAdapter(
            child: DayStrip(
              days: _schedule,
              selectedDay: _selectedDay,
              onDayTapped: _onDayTapped,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Today card ───────────────────────────────
          SliverToBoxAdapter(
            child: TodayCard(
              scheduleDay: _currentScheduleDay,
              routine: _selectedRoutine,
              onStart: _startWorkout,
              onTap: _openRoutineDetail,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Upcoming days this week ───────────────────
          SliverToBoxAdapter(
            child: _UpcomingSection(
              schedule: _schedule,
              selectedDay: _selectedDay,
              onDayTapped: _onDayTapped,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Upcoming section ───────────────────────────────────────────────────────
// Shows remaining days this week after today — restful, minimal

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({
    required this.schedule,
    required this.selectedDay,
    required this.onDayTapped,
  });

  final List<ScheduleDay> schedule;
  final WeekDay selectedDay;
  final ValueChanged<WeekDay> onDayTapped;

  @override
  Widget build(BuildContext context) {
    // Show days after selected day
    final selectedIndex = schedule.indexWhere((d) => d.day == selectedDay);
    final upcoming = schedule.skip(selectedIndex + 1).toList();

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMING UP',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          ...upcoming.map((day) => _UpcomingRow(
                day: day,
                onTap: () => onDayTapped(day.day),
              )),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.day, required this.onTap});

  final ScheduleDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.isRest ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Day label
            SizedBox(
              width: 36,
              child: Text(
                day.day.short,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Routine or rest
            Expanded(
              child: Text(
                day.isRest ? 'Rest' : (day.routineName ?? '—'),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: day.isRest
                      ? FontWeight.w400
                      : FontWeight.w500,
                  color: day.isRest
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textPrimary,
                ),
              ),
            ),
            // Arrow for workout days
            if (!day.isRest)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}