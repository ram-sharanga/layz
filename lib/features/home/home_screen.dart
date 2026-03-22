import 'package:flutter/material.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/screens/weekly_schedule_screen.dart';

// ─── The 3-world shell ────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _worldController = PageController(initialPage: 1);

  @override
  void dispose() {
    _worldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _worldController,
        allowImplicitScrolling: true,
        // FIX: Add this for a fluid, elastic feel
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: const [
          _LeftWorld(), // index 0
          _CenterWorld(), // index 1
          _RightWorld(), // index 2
        ],
      ),
    );
  }
}

// ─── Left world (social — placeholder) ───────────────────────────────────────

class _LeftWorld extends StatelessWidget {
  const _LeftWorld();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Social',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Center world (main screen) ───────────────────────────────────────────────

class _CenterWorld extends StatelessWidget {
  const _CenterWorld();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Wordmark
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 20),
              child: Text(
                'LAYZ',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),

            // Start workout button — centred
            Center(
              child: _StartWorkoutButton(
                onTap: () {
                  // TODO: navigate to active workout screen
                },
              ),
            ),

            // Swipe hints
            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: _SwipeHints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: const Center(
          child: Text(
            'START\nWORKOUT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              height: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeHints extends StatelessWidget {
  const _SwipeHints();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            '← social',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Text(
            'you →',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Right world (plan · roadmap · profile) ───────────────────────────────────

class _RightWorld extends StatefulWidget {
  const _RightWorld();

  @override
  State<_RightWorld> createState() => _RightWorldState();
}

class _RightWorldState extends State<_RightWorld> {
  int _tab = 0; // 0 = Plan, 1 = Roadmap, 2 = Profile

  static const _tabs = ['Plan', 'Roadmap', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: const [_PlanTab(), _RoadmapTab(), _ProfileTab()],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        tabs: _tabs,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.tabs,
    required this.onTap,
  });

  final int current;
  final List<String> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: active
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: active ? 1.5 : 0.5,
                    ),
                    child: Text(tabs[i].toUpperCase()),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Tab placeholders ─────────────────────────────────────────────────────────

class _PlanTab extends StatelessWidget {
  const _PlanTab();

  @override
  Widget build(BuildContext context) {
    return WeeklyScheduleScreen(
      // TODO: replace with real goal + userId from Firebase Auth + Supabase
      goal: 'muscle',
      userId: 'test_user',
    );
  }
}

class _RoadmapTab extends StatelessWidget {
  const _RoadmapTab();

  @override
  Widget build(BuildContext context) {
    // TODO: build Roadmap screen
    return const Center(
      child: Text(
        'Roadmap',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    // TODO: fetch user data from Supabase and display here
    // Display: name, age, gender, goal, experience — all editable
    return const Center(
      child: Text(
        'Profile',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}
