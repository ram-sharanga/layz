import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/home/home_screen.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class OnboardingData {
  int? age;
  String? gender;   // 'male' | 'female' | 'other'
  String? goal;     // 'build' | 'shred' | 'lose_fat' | 'maintain'
  String? experience; // 'beginner' | 'intermediate' | 'advanced'
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingData _data = OnboardingData();
  int _currentPage = 0;
  static const int _totalPages = 4;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // TODO: upsert _data to Supabase here, set onboarding_complete = true
    // final supabase = Supabase.instance.client;
    // await supabase.from('users').upsert({ ...data, 'onboarding_complete': true });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: return _data.age != null && _data.age! >= 13 && _data.age! <= 100;
      case 1: return _data.gender != null;
      case 2: return _data.goal != null;
      case 3: return _data.experience != null;
      default: return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: _ProgressBar(current: _currentPage, total: _totalPages),
            ),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _AgeStep(
                    initialValue: _data.age,
                    onChanged: (v) => setState(() => _data.age = v),
                  ),
                  _ChoiceStep(
                    title: "What's your gender?",
                    options: const [
                      _Option(value: 'male',   label: 'Male'),
                      _Option(value: 'female', label: 'Female'),
                      _Option(value: 'other',  label: 'Prefer not to say'),
                    ],
                    selected: _data.gender,
                    onSelected: (v) => setState(() => _data.gender = v),
                  ),
                  _ChoiceStep(
                    title: "What's your goal?",
                    options: const [
                      _Option(value: 'build',    label: 'Build muscle'),
                      _Option(value: 'shred',    label: 'Shred & tone'),
                      _Option(value: 'lose_fat', label: 'Lose fat'),
                      _Option(value: 'maintain', label: 'Maintain'),
                    ],
                    selected: _data.goal,
                    onSelected: (v) => setState(() => _data.goal = v),
                  ),
                  _ChoiceStep(
                    title: 'Your experience level?',
                    options: const [
                      _Option(value: 'beginner',     label: 'Beginner'),
                      _Option(value: 'intermediate', label: 'Intermediate'),
                      _Option(value: 'advanced',     label: 'Advanced'),
                    ],
                    selected: _data.experience,
                    onSelected: (v) => setState(() => _data.experience = v),
                  ),
                ],
              ),
            ),

            // ── Continue button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: _ContinueButton(
                enabled: _canProceed(),
                isLast: _currentPage == _totalPages - 1,
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Age step ─────────────────────────────────────────────────────────────────

class _AgeStep extends StatefulWidget {
  const _AgeStep({required this.onChanged, this.initialValue});
  final ValueChanged<int?> onChanged;
  final int? initialValue;

  @override
  State<_AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<_AgeStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("How old are you?",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text("We use this to personalise your experience.",
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 40),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: '—',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
              suffixText: 'yrs',
              suffixStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              widget.onChanged(parsed);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Generic choice step ──────────────────────────────────────────────────────

class _Option {
  const _Option({required this.value, required this.label});
  final String value;
  final String label;
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<_Option> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 40),
          ...options.map((opt) => _ChoiceTile(
                label: opt.label,
                selected: selected == opt.value,
                onTap: () => onSelected(opt.value),
              )),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Continue button ──────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.isLast,
    required this.onTap,
  });

  final bool enabled;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.buttonDisabled,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            isLast ? 'Get started' : 'Continue',
            style: TextStyle(
              color: enabled ? AppColors.background : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}