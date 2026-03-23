import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/home/home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — single page, three questions, zero scroll
// Age picker | Bio profile | Goal → motivational message → let's go
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingData {
  int? age;
  String? bio; // 'male' | 'female' | 'other'
  String? goal; // 'lean' | 'muscle' | 'fit'
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingData _data = OnboardingData();

  late final FixedExtentScrollController _ageController;
  static const int _minAge = 13;
  static const int _maxAge = 80;
  static const int _defaultAge = 22;

  late final AnimationController _motiveCtrl;
  late final Animation<double> _motiveFade;
  late final Animation<Offset> _motiveSlide;

  bool get _canProceed =>
      _data.age != null && _data.bio != null && _data.goal != null;

  @override
  void initState() {
    super.initState();
    _data.age = _defaultAge;
    _ageController = FixedExtentScrollController(
      initialItem: _defaultAge - _minAge,
    );
    _motiveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _motiveFade = CurvedAnimation(parent: _motiveCtrl, curve: Curves.easeOut);
    _motiveSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _motiveCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ageController.dispose();
    _motiveCtrl.dispose();
    super.dispose();
  }

  void _selectGoal(String goal) {
    setState(() => _data.goal = goal);
    HapticFeedback.lightImpact();
    _motiveCtrl.forward(from: 0);
  }

  void _proceed() {
    if (!_canProceed) return;
    HapticFeedback.mediumImpact();
    // TODO: upsert _data to Supabase, set onboarding_complete = true
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: const HomeScreen()),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final screenH = mq.size.height;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Tell us about\nyourself.',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              // ── Top row: Age + Bio ────────────────────────
              SizedBox(
                height: screenH * 0.27,
                child: Row(
                  children: [
                    // Age
                    Expanded(
                      flex: 4,
                      child: _AgeBox(
                        controller: _ageController,
                        minAge: _minAge,
                        maxAge: _maxAge,
                        onChanged: (v) => setState(() => _data.age = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Bio
                    Expanded(
                      flex: 6,
                      child: _BioBox(
                        selected: _data.bio,
                        onSelected: (v) {
                          setState(() => _data.bio = v);
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Goal label ────────────────────────────────
              Text(
                'YOUR GOAL',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5,
                ),
              ),

              const SizedBox(height: 10),

              // ── Goal tiles ────────────────────────────────
              Row(
                children: [
                  _GoalTile(
                    label: 'Get lean',
                    sub: 'Burn fat',
                    value: 'lean',
                    selected: _data.goal == 'lean',
                    onTap: () => _selectGoal('lean'),
                  ),
                  const SizedBox(width: 8),
                  _GoalTile(
                    label: 'Build muscle',
                    sub: 'Get strong',
                    value: 'muscle',
                    selected: _data.goal == 'muscle',
                    onTap: () => _selectGoal('muscle'),
                  ),
                  const SizedBox(width: 8),
                  _GoalTile(
                    label: 'Get fit',
                    sub: 'Stay active',
                    value: 'fit',
                    selected: _data.goal == 'fit',
                    onTap: () => _selectGoal('fit'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Motivation message ────────────────────────
              FadeTransition(
                opacity: _motiveFade,
                child: SlideTransition(
                  position: _motiveSlide,
                  child: const _Motivation(),
                ),
              ),

              const Spacer(),

              // ── CTA ──────────────────────────────────────
              _CtaButton(enabled: _canProceed, onTap: _proceed),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Age drum-roller box
// ─────────────────────────────────────────────────────────────────────────────

class _AgeBox extends StatelessWidget {
  const _AgeBox({
    required this.controller,
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int minAge;
  final int maxAge;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Drum roller
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 46,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            diameterRatio: 1.5,
            onSelectedItemChanged: (i) => onChanged(minAge + i),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxAge - minAge + 1,
              builder: (_, i) => Center(
                child: Text(
                  '${minAge + i}',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Lime selection band
          Center(
            child: IgnorePointer(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top fade-out
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom fade-out + label
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
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'AGE',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
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
// Bio picker box — stacked rows, looks like the age box's sibling
// ─────────────────────────────────────────────────────────────────────────────

class _BioBox extends StatelessWidget {
  const _BioBox({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  static const _opts = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Prefer not to say'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BIOLOGY',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          ..._opts.map((opt) {
            final active = selected == opt.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? AppColors.accent : AppColors.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt.$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? AppColors.background
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Goal tile
// ─────────────────────────────────────────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label, sub, value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.background
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: selected
                      ? AppColors.background.withValues(alpha: 0.55)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivation block
// ─────────────────────────────────────────────────────────────────────────────

class _Motivation extends StatelessWidget {
  const _Motivation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accent, width: 2)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.75,
          ),
          children: [
            const TextSpan(text: 'The first 21 days set the habit. '),
            TextSpan(
              text: 'Show up',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const TextSpan(
              text:
                  ' for three weeks and your body starts '
                  'rewarding you. By 90 days — you\'ll see it, '
                  'feel it, own it.\n',
            ),
            TextSpan(
              text: '\nNOTHING BEATS CONSISTENCY.',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.buttonDisabled,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "LET'S GO",
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: enabled ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
