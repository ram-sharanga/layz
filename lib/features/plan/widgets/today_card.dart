// lib/features/plan/widgets/today_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';

class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.scheduleDay,
    required this.routine,
    required this.onTap,
    required this.onStart,
  });

  final ScheduleDay  scheduleDay;
  final Routine?     routine;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (scheduleDay.isRest) return const _RestCard();
    return _WorkoutContent(
      routineName: scheduleDay.routineName ?? '',
      routine:     routine,
      onTap:       onTap,
      onStart:     onStart,
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bedtime_outlined,
              size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rest Day',
                  style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text('Recovery is progress',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutContent extends StatelessWidget {
  const _WorkoutContent({
    required this.routineName,
    required this.routine,
    required this.onTap,
    required this.onStart,
  });

  final String       routineName;
  final Routine?     routine;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routineName,
                      style: GoogleFonts.dmSans(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 4),
                  if (routine != null)
                    Text(
                      '${routine!.exerciseCount} exercises · ${routine!.muscleGroupLabel}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onStart();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('START WORKOUT', // ← FIXED TYPO
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      letterSpacing: 1.5, color: AppColors.background,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}