// lib/features/plan/screens/routine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'active_workout_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({
    super.key,
    required this.routine,
    required this.goal,
  });

  final Routine routine;
  final String  goal;

  void _startWorkout(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ActiveWorkoutScreen(routine: routine, goal: goal),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    const Spacer(),
                    if (routine.isGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text('GENERATED',
                            style: GoogleFonts.dmSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary, letterSpacing: 1.5,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(routine.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.5, height: 1,
                    )),
                const SizedBox(height: 6),
                Text(
                  '${routine.exerciseCount} exercises · ${routine.muscleGroupLabel} · ${routine.estimatedLabel}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: routine.exercises.length,
              itemBuilder: (_, i) {
                final re   = routine.exercises[i];
                final wuCount = re.warmUpSets.length;
                final wsCount = re.workingSets.length;

                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      // Order number
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(re.exercise.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (wuCount > 0) '$wuCount warm-up',
                                '$wsCount working ${wsCount == 1 ? 'set' : 'sets'}',
                                re.exercise.primaryMuscle.label,
                              ].join(' · '),
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rep range
                      Builder(builder: (_) {
                        final rr = re.exercise.repRangeFor(goal);
                        if (rr == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${rr.min}–${rr.max}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.accent.withValues(alpha: 0.7),
                              )),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Start button ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, botPad + 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: GestureDetector(
              onTap: () => _startWorkout(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('START WORKOUT',
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 2.5, color: AppColors.background,
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}