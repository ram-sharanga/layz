import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/services/tooltip_service.dart';

class TodayCard extends StatefulWidget {
  const TodayCard({
    super.key,
    required this.scheduleDay,
    this.routine,
    required this.onStart,
    required this.onTap,
  });

  final ScheduleDay scheduleDay;
  final Routine? routine;
  final VoidCallback onStart;
  final VoidCallback onTap;

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard>
    with SingleTickerProviderStateMixin {

  bool _showTooltip = false;
  late final AnimationController _tooltipCtrl;
  late final Animation<double> _tooltipFade;

  @override
  void initState() {
    super.initState();
    _tooltipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tooltipFade = CurvedAnimation(
      parent: _tooltipCtrl,
      curve: Curves.easeOut,
    );
    _checkTooltip();
  }

  Future<void> _checkTooltip() async {
    final shouldShow = await TooltipService.showOnce(TooltipKeys.planTapDay);
    if (shouldShow && mounted) {
      setState(() => _showTooltip = true);
      _tooltipCtrl.forward();
      // Auto-dismiss after 3 seconds
      await Future.delayed(const Duration(milliseconds: 3000));
      if (mounted) {
        await _tooltipCtrl.reverse();
        setState(() => _showTooltip = false);
      }
    }
  }

  @override
  void dispose() {
    _tooltipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            widget.scheduleDay.isToday ? 'TODAY' : widget.scheduleDay.day.full.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2.5,
            ),
          ),
        ),

        // First-time tooltip
        if (_showTooltip)
          FadeTransition(
            opacity: _tooltipFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Tap any day above to customise your plan.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),

        // Card
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: widget.scheduleDay.isRest
                ? _RestContent()
                : _WorkoutContent(
                    scheduleDay: widget.scheduleDay,
                    routine: widget.routine,
                    onStart: widget.onStart,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Rest day content ───────────────────────────────────────────────────────

class _RestContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Day',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recovery is part of the plan.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Rest icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(
            Icons.bedtime_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ── Workout day content ────────────────────────────────────────────────────

class _WorkoutContent extends StatelessWidget {
  const _WorkoutContent({
    required this.scheduleDay,
    required this.routine,
    required this.onStart,
  });

  final ScheduleDay scheduleDay;
  final Routine? routine;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final r = routine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Routine name
                  Text(
                    scheduleDay.routineName ?? '—',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Muscle groups
                  Text(
                    r?.muscleGroupLabel ?? '—',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Exercise count badge
            if (r != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  '${r.exerciseCount} exercises',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Start button
        GestureDetector(
          onTap: onStart,
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'START WORKOUT',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.background,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}