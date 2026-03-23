// lib/features/plan/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/exercise.dart';
import 'package:layz/features/plan/models/split.dart';
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

  static const _slideLabels = [
    'Starting position',
    'Form',
    'Grip',
    'Caution',
    'What to avoid',
  ];

  List<Exercise> get _substitutes => PlanService.getSubstitutes(widget.exercise);

  @override
  void dispose() {
    _slideshow.dispose();
    super.dispose();
  }

  void _showAddToRoutine() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddToRoutineSheet(
        exercise: widget.exercise,
        goal: widget.goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    final substitutes = _substitutes;
    final slideCount = widget.exercise.imageUrls.isEmpty
        ? _slideLabels.length
        : widget.exercise.imageUrls.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [

                // ── Full-bleed image slideshow ────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 280,
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

                      // Back button — floating over image
                      Positioned(
                        top: topPad + 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),

                      // Slide dots
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: _SlideDots(
                          count: slideCount,
                          current: _currentSlide,
                        ),
                      ),

                      // Bottom fade into background
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.background,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Name + tags ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              label: widget.exercise.equipmentLabel,
                              icon: Icons.fitness_center,
                            ),
                            _InfoChip(
                              label: widget.exercise.difficultyLabel,
                              icon: Icons.bar_chart_rounded,
                            ),
                            _InfoChip(
                              label: widget.exercise.secondaryMuscles.isNotEmpty
                                  ? 'Compound'
                                  : 'Isolation',
                              icon: Icons.hub_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Muscles ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('MUSCLES'),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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

                // ── Rep ranges ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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

                // ── Substitutes ───────────────────────────────────────────
                if (substitutes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                                  color: AppColors.accent
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...substitutes.map((s) => _SubstituteRow(
                                exercise: s,
                                onTap: () =>
                                    Navigator.of(context).pushReplacement(
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

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isFavourited
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isFavourited
                            ? AppColors.accent.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      _isFavourited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavourited
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Add to routine
                Expanded(
                  child: GestureDetector(
                    onTap: _showAddToRoutine,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'ADD TO ROUTINE',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
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

// ── Add to routine bottom sheet ────────────────────────────────────────────

class _AddToRoutineSheet extends StatelessWidget {
  const _AddToRoutineSheet({
    required this.exercise,
    required this.goal,
  });

  final Exercise exercise;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final splitType = SplitLabel.fromGoal(goal);
    final routineNames = SplitGenerator.routineNamesFor(splitType);

    // TODO: append user-created routines from Supabase here once auth is wired
    // final userRoutines = await PlanService.getUserRoutines(userId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Add to routine',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.name,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.accent.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Routine list
          ...routineNames.map((name) => _RoutineRow(
                name: name,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added to $name',
                        style: GoogleFonts.dmSans(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // TODO: PlanService.addExerciseToRoutine(routineName: name, exercise: exercise)
                },
              )),

          // Divider
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // Create new routine
          _RoutineRow(
            name: '+ Create new routine',
            isCreate: true,
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Coming soon',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.name,
    required this.onTap,
    this.isCreate = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool isCreate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCreate
                      ? AppColors.accent.withValues(alpha: 0.7)
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (!isCreate)
              Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.2),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder slideshow ──────────────────────────────────────────────────

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
              color: Colors.white.withValues(alpha: 0.1),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              labels[i],
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide dots ─────────────────────────────────────────────────────────────

class _SlideDots extends StatelessWidget {
  const _SlideDots({required this.count, required this.current});

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
                : Colors.white.withValues(alpha: 0.25),
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
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.35),
            letterSpacing: 2.5,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Muscle column ──────────────────────────────────────────────────────────

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
            color: Colors.white.withValues(alpha: 0.25),
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...muscles.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                m,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isAccent
                      ? AppColors.textPrimary
                      : Colors.white.withValues(alpha: 0.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentGoal
            ? AppColors.accent.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentGoal
              ? AppColors.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                const SizedBox(height: 3),
                Text(
                  range!.note,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${range!.min}–${range!.max}',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isCurrentGoal
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.5),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.primaryMuscleLabel} · ${exercise.equipmentLabel}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}