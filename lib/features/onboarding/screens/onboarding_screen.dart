// lib/features/onboarding/screens/onboarding_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/home/home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — 3 steps: age, bio, goal
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _page = PageController();
  int _step = 0;

  // Data
  int    _age = 22;
  String _bio = 'male';
  String _goal = 'muscle';

  // Animations
  late AnimationController _progressCtrl;
  late Animation<double>   _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 1 / 3)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _page.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.mediumImpact();
    if (_step < 2) {
      _step++;
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut);
      final target = (_step + 1) / 3;
      _progressAnim = Tween<double>(
              begin: _progressAnim.value, end: target)
          .animate(CurvedAnimation(
              parent: _progressCtrl..reset()..forward(),
              curve: Curves.easeOut));
      setState(() {});
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      HapticFeedback.selectionClick();
      _step--;
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut);
      final target = (_step + 1) / 3;
      _progressAnim = Tween<double>(
              begin: _progressAnim.value, end: target)
          .animate(CurvedAnimation(
              parent: _progressCtrl..reset()..forward(),
              curve: Curves.easeOut));
      setState(() {});
    }
  }

  void _finish() {
    HapticFeedback.heavyImpact();
    // TODO: save to Supabase — for now just navigate
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Progress bar
          SizedBox(height: topPad + 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_step > 0)
                  GestureDetector(
                    onTap: _back,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(Icons.arrow_back,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 3,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnim.value,
                          child: Container(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text('${_step + 1}/3',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pages
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AgeStep(
                  age:       _age,
                  onChanged: (v) => setState(() => _age = v),
                ),
                _BioStep(
                  bio:       _bio,
                  onChanged: (v) => setState(() => _bio = v),
                ),
                _GoalStep(
                  goal:      _goal,
                  onChanged: (v) => setState(() => _goal = v),
                ),
              ],
            ),
          ),

          // Continue button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, botPad + 24),
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _step < 2 ? 'CONTINUE' : 'START YOUR JOURNEY',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      letterSpacing: 2, color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Age drum
// ─────────────────────────────────────────────────────────────────────────────

class _AgeStep extends StatefulWidget {
  const _AgeStep({required this.age, required this.onChanged});
  final int age;
  final ValueChanged<int> onChanged;

  @override
  State<_AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<_AgeStep> {
  late FixedExtentScrollController _ctrl;
  static const _minAge = 13;
  static const _maxAge = 80;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
        initialItem: widget.age - _minAge);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('How old are you?',
              style: GoogleFonts.dmSans(
                fontSize: 34, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.5, height: 1.1,
              )),
          const SizedBox(height: 8),
          Text('We use this to personalise your plan.',
              style: GoogleFonts.dmSans(
                fontSize: 15, color: AppColors.textSecondary)),

          const Spacer(),

          // Drum
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                ListWheelScrollView.useDelegate(
                  controller: _ctrl,
                  itemExtent: 64,
                  physics: const FixedExtentScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  perspective: 0.002,
                  diameterRatio: 1.8,
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    widget.onChanged(i + _minAge);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _maxAge - _minAge + 1,
                    builder: (_, i) {
                      final age = i + _minAge;
                      return Center(
                        child: Text('$age',
                            style: GoogleFonts.dmSans(
                              fontSize: 36, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                      );
                    },
                  ),
                ),
                // Selection band
                Center(
                  child: IgnorePointer(
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top fade
                Positioned(
                  top: 0, left: 0, right: 0, height: 100,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.background, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom fade
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 100,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppColors.background, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Bio (biological sex)
// ─────────────────────────────────────────────────────────────────────────────

class _BioStep extends StatelessWidget {
  const _BioStep({required this.bio, required this.onChanged});
  final String bio;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Your biology',
              style: GoogleFonts.dmSans(
                fontSize: 34, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.5, height: 1.1,
              )),
          const SizedBox(height: 8),
          Text('Helps us calibrate rep ranges and recovery.',
              style: GoogleFonts.dmSans(
                fontSize: 15, color: AppColors.textSecondary)),

          const Spacer(),

          _BioOption(
            label:       'Male',
            description: 'Higher baseline testosterone — more aggressive progression',
            emoji:       '♂',
            selected:    bio == 'male',
            onTap:       () => onChanged('male'),
          ),
          const SizedBox(height: 14),
          _BioOption(
            label:       'Female',
            description: 'Higher recovery rate — volume responds well',
            emoji:       '♀',
            selected:    bio == 'female',
            onTap:       () => onChanged('female'),
          ),
          const SizedBox(height: 14),
          _BioOption(
            label:       'Prefer not to say',
            description: 'We\'ll use neutral defaults',
            emoji:       '○',
            selected:    bio == 'other',
            onTap:       () => onChanged('other'),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _BioOption extends StatelessWidget {
  const _BioOption({
    required this.label,
    required this.description,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String     label, description, emoji;
  final bool       selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji,
                style: TextStyle(
                  fontSize: 24,
                  color: selected
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.3),
                )),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Text(description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 13, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Goal
// ─────────────────────────────────────────────────────────────────────────────

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.goal, required this.onChanged});
  final String goal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Your goal',
              style: GoogleFonts.dmSans(
                fontSize: 34, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.5, height: 1.1,
              )),
          const SizedBox(height: 8),
          Text('This shapes your entire training split and rep ranges.',
              style: GoogleFonts.dmSans(
                fontSize: 15, color: AppColors.textSecondary)),

          const Spacer(),

          _GoalCard(
            id:          'muscle',
            label:       'Build Muscle',
            description: '4–5 days/week · Heavy compound lifts · 6–12 reps · Long rests',
            emoji:       '💪',
            selected:    goal == 'muscle',
            onTap:       () => onChanged('muscle'),
          ),
          const SizedBox(height: 14),
          _GoalCard(
            id:          'lean',
            label:       'Get Lean',
            description: '3–5 days/week · Circuit + supersets · 12–20 reps · Short rests',
            emoji:       '⚡',
            selected:    goal == 'lean',
            onTap:       () => onChanged('lean'),
          ),
          const SizedBox(height: 14),
          _GoalCard(
            id:          'fit',
            label:       'Get Fit',
            description: '3–4 days/week · Balanced training · 10–15 reps · Moderate rests',
            emoji:       '🎯',
            selected:    goal == 'fit',
            onTap:       () => onChanged('fit'),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String     id, label, description, emoji;
  final bool       selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: selected ? AppColors.accent : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary, height: 1.5,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}