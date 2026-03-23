// lib/features/plan/widgets/day_strip.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/split.dart';

class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final WeekDay                selected = WeekDay.monday;
  final WeekDay                selectedDay;
  final ValueChanged<WeekDay>  onDaySelected;

  @override
  Widget build(BuildContext context) {
    final today = WeekDay.fromDateTime(DateTime.now());
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: WeekDay.values.map((day) {
          final isSelected = day == selectedDay;
          final isToday    = day == today;
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day.short.substring(0, 1),
                      style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textSecondary,
                      )),
                  if (isToday)
                    Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}