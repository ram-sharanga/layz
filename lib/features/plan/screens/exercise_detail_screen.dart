// lib/features/plan/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/services/plan_service.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.goal,
  });

  final Exercise exercise;
  final String   goal;

  @override
  Widget build(BuildContext context) {
    final topPad     = MediaQuery.of(context).padding.top;
    final repRange   = exercise.repRangeFor(goal);
    final substitutes = PlanService.getSubstitutes(exercise);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // Image / header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  width: double.infinity, height: 280,
                  color: const Color(0xFF0C0C0C),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 48, color: Colors.white.withValues(alpha: 0.06)),
                        const SizedBox(height: 10),
                        Text('GIF / IMAGE',
                            style: GoogleFonts.dmSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.07),
                              letterSpacing: 3,
                            )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: topPad + 14, left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Name + muscle
                  Text(exercise.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary, letterSpacing: -1,
                      )),
                  const SizedBox(height: 6),
                  Row(children: [
                    _Chip(label: exercise.primaryMuscle.label, accent: true),
                    const SizedBox(width: 8),
                    _Chip(label: exercise.equipment.label),
                    const SizedBox(width: 8),
                    _Chip(label: exercise.difficulty.name),
                  ]),

                  if (exercise.description != null) ...[
                    const SizedBox(height: 20),
                    Text(exercise.description!,
                        style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textSecondary,
                          height: 1.6,
                        )),
                  ],

                  if (repRange != null) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('REP RANGE FOR YOUR GOAL'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Text('${repRange.min}–${repRange.max} reps',
                            style: GoogleFonts.dmSans(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                            )),
                        const Spacer(),
                        Text(goal.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppColors.accent.withValues(alpha: 0.5),
                              letterSpacing: 2,
                            )),
                      ]),
                    ),
                  ],

                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('SECONDARY MUSCLES'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: exercise.secondaryMuscles
                          .map((m) => _Chip(label: m.label))
                          .toList(),
                    ),
                  ],

                  if (substitutes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('SUBSTITUTES'),
                    const SizedBox(height: 10),
                    ...substitutes.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ExerciseDetailScreen(
                              exercise: s, goal: goal),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      )),
                                  Text(s.equipment.label,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12, color: AppColors.textSecondary,
                                      )),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16,
                                color: Colors.white.withValues(alpha: 0.15)),
                          ]),
                        ),
                      ),
                    )),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.3), letterSpacing: 2.5,
        ));
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent = false});
  final String label;
  final bool   accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? AppColors.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: accent ? AppColors.accent : AppColors.textSecondary,
          )),
    );
  }
}