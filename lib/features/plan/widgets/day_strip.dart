// lib/features/plan/widgets/day_strip.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/split.dart';

class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDayTapped,
  });

  final List<ScheduleDay> days;
  final WeekDay selectedDay;
  final ValueChanged<WeekDay> onDayTapped;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto scroll to today after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(DayStrip old) {
    super.didUpdateWidget(old);
    if (old.selectedDay != widget.selectedDay) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = widget.days
        .indexWhere((d) => d.day == widget.selectedDay);
    if (index < 0) return;

    // Each item is 64px wide + 8px gap
    final offset = (index * 72.0) - 16;
    _scroll.animateTo(
      offset.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = widget.days[i];
          final isSelected = day.day == widget.selectedDay;
          final isToday = day.isToday;

          return _DayCell(
            day: day,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onDayTapped(day.day);
            },
          );
        },
      ),
    );
  }
}

// ── Single day cell ────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final ScheduleDay day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : isToday
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Day label — Mon, Tue etc
            Text(
              day.day.short,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 6),

            // Content — rest dash or routine initial or checkmark
            if (day.isCompleted)
              Icon(
                Icons.check,
                size: 16,
                color: isSelected
                    ? AppColors.background
                    : AppColors.accent,
              )
            else if (day.isRest)
              Text(
                '—',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isSelected
                      ? AppColors.background.withValues(alpha: 0.5)
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              )
            else
              // Routine initial — P for Push, L for Legs etc
              Text(
                day.routineName?[0] ?? '?',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textPrimary,
                ),
              ),

            const SizedBox(height: 6),

            // Today indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday && !isSelected
                    ? AppColors.accent
                    : Colors.transparent,
              ),
            ),

          ],
        ),
      ),
    );
  }
}