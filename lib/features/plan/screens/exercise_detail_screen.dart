// lib/features/plan/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/services/plan_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.goal,
  });

  final Exercise exercise;
  final String goal;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final PageController _slideshow = PageController();
  int _currentSlide = 0;
  bool _isFavourited = false;

  // Placeholder slide labels — replaced by real images from Supabase later
  static const _slideLabels = [
    'Starting position',
    'Form',
    'Grip',
    'Caution',
    'What to avoid',
  ];

  List<Exercise> get _substitutes =>
      PlanService.getSubstitutes(widget.exercise);

  @override
  void dispose() {
    _slideshow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    final repRange = widget.exercise.repRangeFor(widget.goal);
    final substitutes = _substitutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Content ──────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [

                // ── Image slideshow ──────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Slides
                      SizedBox(
                        height: 260,
                        child: widget.exercise.imageUrls.isEmpty
                            ? _PlaceholderSlideshow(
                                labels: _slideLabels,
                                controller: _slideshow,
                                currentIndex: _currentSlide,
                                onPageChanged: (i) =>
                                    setState(() => _currentSlide = i),
                              )
                            : PageView.builder(
                                controller: _slideshow,
                                itemCount: widget.exercise.imageUrls.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentSlide = i),
                                itemBuilder: (_, i) => Image.network(
                                  widget.exercise.imageUrls[i],
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),

                      // Back button
                      Positioned(
                        top: topPad + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Dot indicators
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: _DotIndicators(
                          count: widget.exercise.imageUrls.isEmpty
                              ? _slideLabels.length
                              : widget.exercise.imageUrls.length,
                          current: _currentSlide,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Name + tags ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              label: widget.exercise.equipmentLabel,
                              icon: Icons.fitness_center,
                            ),
                            _InfoChip(
                              label: widget.exercise.difficultyLabel,
                              icon: Icons.bar_chart,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Muscle groups ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('MUSCLES'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MuscleColumn(
                                label: 'PRIMARY',
                                muscles: widget.exercise.primaryMuscles
                                    .map((m) => m.label)
                                    .toList(),
                                isAccent: true,
                              ),
                            ),
                            if (widget.exercise.secondaryMuscles.isNotEmpty)
                              Expanded(
                                child: _MuscleColumn(
                                  label: 'SECONDARY',
                                  muscles: widget.exercise.secondaryMuscles
                                      .map((m) => m.label)
                                      .toList(),
                                  isAccent: false,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Rep ranges ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('REP RANGES BY GOAL'),
                        const SizedBox(height: 12),
                        _RepRangeRow(
                          goalLabel: 'Get lean',
                          range: widget.exercise.repRangeFor('lean'),
                          isCurrentGoal: widget.goal == 'lean',
                        ),
                        const SizedBox(height: 8),
                        _RepRangeRow(
                          goalLabel: 'Build muscle',
                          range: widget.exercise.repRangeFor('muscle'),
                          isCurrentGoal: widget.goal == 'muscle',
                        ),
                        const SizedBox(height: 8),
                        _RepRangeRow(
                          goalLabel: 'Get fit',
                          range: widget.exercise.repRangeFor('fit'),
                          isCurrentGoal: widget.goal == 'fit',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Substitutes ──────────────────────────
                if (substitutes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _SectionLabel("CAN'T DO THIS?"),
                              const SizedBox(width: 8),
                              Text(
                                'Alternatives',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...substitutes.map((s) => _SubstituteRow(
                                exercise: s,
                                onTap: () => Navigator.of(context)
                                    .pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseDetailScreen(
                                      exercise: s,
                                      goal: widget.goal,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Fixed bottom action bar ──────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [

                // Favourite
                GestureDetector(
                  onTap: () {
                    setState(() => _isFavourited = !_isFavourited);
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isFavourited
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isFavourited
                            ? AppColors.accent.withValues(alpha: 0.4)
                            : AppColors.divider,
                      ),
                    ),
                    child: Icon(
                      _isFavourited
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _isFavourited
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Add to routine
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // TODO: show bottom sheet to pick which routine to add to
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'ADD TO ROUTINE',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder slideshow ──────────────────────────────────────────────────
// Shows labelled grey boxes until real images are loaded from Supabase

class _PlaceholderSlideshow extends StatelessWidget {
  const _PlaceholderSlideshow({
    required this.labels,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> labels;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: labels.length,
      onPageChanged: onPageChanged,
      itemBuilder: (_, i) => Container(
        color: AppColors.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              labels[i],
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot indicators ─────────────────────────────────────────────────────────

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 2.5,
      ),
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Muscle group column ────────────────────────────────────────────────────

class _MuscleColumn extends StatelessWidget {
  const _MuscleColumn({
    required this.label,
    required this.muscles,
    required this.isAccent,
  });

  final String label;
  final List<String> muscles;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        ...muscles.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                m,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isAccent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            )),
      ],
    );
  }
}

// ── Rep range row ──────────────────────────────────────────────────────────

class _RepRangeRow extends StatelessWidget {
  const _RepRangeRow({
    required this.goalLabel,
    required this.range,
    required this.isCurrentGoal,
  });

  final String goalLabel;
  final RepRange? range;
  final bool isCurrentGoal;

  @override
  Widget build(BuildContext context) {
    if (range == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentGoal
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentGoal
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      goalLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCurrentGoal
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentGoal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOUR GOAL',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  range!.note,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${range!.min}–${range!.max}',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isCurrentGoal
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Substitute row ─────────────────────────────────────────────────────────

class _SubstituteRow extends StatelessWidget {
  const _SubstituteRow({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${exercise.primaryMuscleLabel} · ${exercise.equipmentLabel}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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