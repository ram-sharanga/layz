import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SafeArea(child: _HomeContent()),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      setState(() => _t += 0.008);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1 — Particle field + atmospheric background
        Positioned.fill(
          child: CustomPaint(painter: _AtmospherePainter(_t)),
        ),

        // 2 — Scanline overlay
        Positioned.fill(child: _ScanlineOverlay()),

        // 3 — Wordmark
        const Positioned(
          top: 20,
          left: 28,
          child: _Wordmark(),
        ),

        // 4 — Status indicator
        const Positioned(
          top: 28,
          right: 28,
          child: _StatusIndicator(),
        ),

        // 5 — Day streak
        const Positioned(
          top: 76,
          left: 28,
          child: _StreakBar(completedDays: 5),
        ),

        // 6 — THE BUTTON
        Center(
          child: _StartButton(t: _t, onTap: () {}),
        ),

        // 7 — Stats strip
        const Positioned(
          bottom: 88,
          left: 0,
          right: 0,
          child: _StatsStrip(),
        ),

        // 8 — Swipe hints
        const Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: _SwipeHints(),
        ),
      ],
    );
  }
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'LAYZ',
      style: TextStyle(
        fontFamily: 'BebasNeue', // add to pubspec assets
        fontSize: 42,
        letterSpacing: 8,
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ─── Status indicator ─────────────────────────────────────────────────────────

class _StatusIndicator extends StatefulWidget {
  const _StatusIndicator();

  @override
  State<_StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<_StatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fade = Tween(begin: 1.0, end: 0.25).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _fade,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFAAFF00),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'READY',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2.5,
            color: Color(0xFFAAFF00),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Streak bar ───────────────────────────────────────────────────────────────

class _StreakBar extends StatelessWidget {
  const _StreakBar({required this.completedDays});
  final int completedDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(7, (i) {
          final done = i < completedDays;
          return Container(
            width: 20,
            height: 4,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: done
                  ? const Color(0xFFAAFF00)
                  : const Color(0xFFAAFF00),
              boxShadow: done
                  ? [
                      const BoxShadow(
                        color: Color(0x80AAFF00),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text(
          '5 DAY STREAK',
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 1.5,
            color: Color(0x66999999),
          ),
        ),
      ],
    );
  }
}

// ─── THE BUTTON ───────────────────────────────────────────────────────────────

class _StartButton extends StatefulWidget {
  const _StartButton({required this.t, required this.onTap});
  final double t;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with TickerProviderStateMixin {
  bool _pressed = false;
  final List<_RippleState> _ripples = [];
  late final AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    setState(() {
      _ripples.add(_RippleState(
        ctrl: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..forward().then((_) {
            setState(() => _ripples.removeWhere((r) => r.ctrl.isCompleted));
          }),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit rings
          _OrbitRing(size: 260, duration: 12000, reverse: false, t: widget.t, dotBottom: false),
          _OrbitRing(size: 300, duration: 20000, reverse: true, t: widget.t, dotBottom: true),
          _OrbitRing(size: 340, duration: 30000, reverse: false, t: widget.t, dotBottom: false),

          // Breathe glow
          _BreatheGlow(t: widget.t),

          // Ripples
          ..._ripples.map((r) => AnimatedBuilder(
                animation: r.ctrl,
                builder: (_, __) {
                  final v = r.ctrl.value;
                  final size = 200.0 + v * 160;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFAAFF00),
                        width: 1,
                      ),
                    ),
                  );
                },
              )),

          // The actual button
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: _handleTap,
            child: AnimatedScale(
              scale: _pressed ? 0.93 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: _GlassButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleState {
  final AnimationController ctrl;
  _RippleState({required this.ctrl});
}

// ─── Glass button face ────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassButtonPainter(),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'START',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: Color(0xFFAAFF00),
                shadows: [
                  Shadow(
                    color: Color(0x99AAFF00),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 20,
              height: 0.5,
              color: const Color(0x66AAFF00),
            ),
            const SizedBox(height: 8),
            const Text(
              'WORKOUT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 3,
                color: Color(0xB3AAFF00),
                shadows: [
                  Shadow(
                    color: Color(0x66AAFF00),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0x99AAFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, r - 0.5, borderPaint);

    // Outer glow
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = const Color(0x26AAFF00);
    canvas.drawCircle(center, r + 10, glowPaint);

    // Glass fill — dark base
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          const Color(0xFF0A0A0A),
          const Color(0xFF000000),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, r - 0.75, basePaint);
    canvas.save();
    canvas.restore();

    // Inner ring
    final innerPaint = Paint()
      ..color = const Color(0x33AAFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, r - 18, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Orbit ring ───────────────────────────────────────────────────────────────

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    required this.size,
    required this.duration,
    required this.reverse,
    required this.t,
    required this.dotBottom,
    this.dotted = false,
  });

  final double size;
  final int duration;
  final bool reverse;
  final double t;
  final bool dotBottom;
  final bool dotted;

  @override
  Widget build(BuildContext context) {
    final speed = (2 * math.pi) / (duration / 10);
    final angle = reverse ? -t * speed * 125 : t * speed * 125;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OrbitRingPainter(
          angle: angle,
          dotted: dotted,
          dotBottom: dotBottom,
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final double angle;
  final bool dotted;
  final bool dotBottom;

  _OrbitRingPainter({
    required this.angle,
    required this.dotted,
    required this.dotBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Ring
    final paint = Paint()
      ..color = const Color(0xFFAAFF00).withOpacity(dotted ? 0.07 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (dotted) {
      // Draw dashed ring manually
      const dashLen = 4.0;
      const gapLen = 6.0;
      final circumference = 2 * math.pi * r;
      final totalDashes = (circumference / (dashLen + gapLen)).floor();
      for (int i = 0; i < totalDashes; i++) {
        final startA = (i / totalDashes) * 2 * math.pi;
        final endA = startA + (dashLen / circumference) * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          startA,
          endA - startA,
          false,
          paint,
        );
      }
    } else {
      canvas.drawCircle(center, r, paint);
    }

    // Dot
    if (!dotted) {
      final dotAngle = dotBottom ? angle + math.pi : angle;
      final dotX = center.dx + r * math.cos(dotAngle);
      final dotY = center.dy + r * math.sin(dotAngle);

      final glowPaint = Paint()
        ..color = const Color(0x80AAFF00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), 5, glowPaint);

      final dotPaint = Paint()..color = const Color(0xFFAAFF00);
      canvas.drawCircle(Offset(dotX, dotY), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) => old.angle != angle;
}

// ─── Breathe glow ─────────────────────────────────────────────────────────────

class _BreatheGlow extends StatelessWidget {
  const _BreatheGlow({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + math.sin(t * 1.5) * 0.06;
    final opacity = 0.6 + math.sin(t * 1.5) * 0.4;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFAAFF00).withOpacity(0.07 * opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Atmosphere painter (particles + grid spokes) ─────────────────────────────

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.t) {
    if (_particles.isEmpty) _initParticles();
    _updateParticles(t);
  }

  final double t;

  static final List<_Particle> _particles = [];
  static double _prevT = 0;
  static Size _lastSize = Size.zero;

  static void _initParticles() {
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final radius = 120 + rng.nextDouble() * 200;
      _particles.add(_Particle(
        x: 195 + math.cos(angle) * radius,
        y: 422 + math.sin(angle) * radius,
        vx: (rng.nextDouble() - 0.5) * 0.3,
        vy: (rng.nextDouble() - 0.5) * 0.3,
        size: rng.nextDouble() * 1.5 + 0.3,
        baseOpacity: rng.nextDouble() * 0.5 + 0.1,
        isLime: rng.nextDouble() > 0.7,
        twinkleSpeed: rng.nextDouble() * 0.02 + 0.005,
        twinklePhase: rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  static void _updateParticles(double t) {
    const cx = 195.0;
    const cy = 422.0;
    for (final p in _particles) {
      p.twinklePhase += p.twinkleSpeed;
      final dx = cx - p.x;
      final dy = cy - p.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > 110) {
        p.vx += (dx / dist) * 0.002;
        p.vy += (dy / dist) * 0.002;
      } else {
        p.vx -= (dx / dist) * 0.003;
        p.vy -= (dy / dist) * 0.003;
      }
      final spd = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      if (spd > 0.6) { p.vx *= 0.6 / spd; p.vy *= 0.6 / spd; }
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) p.x = 390;
      if (p.x > 390) p.x = 0;
      if (p.y < 0) p.y = 844;
      if (p.y > 844) p.y = 0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background gradient
    final bgGrad = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        const Color(0xFF080C00),
        const Color(0xFF030600),
        Colors.black,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = bgGrad,
    );

    // Subtle spokes
    final spokeCount = 8;
    for (int i = 0; i < spokeCount; i++) {
      final angle = (i / spokeCount) * math.pi * 2;
      final paint = Paint()
        ..color = const Color(0xFFAAFF00).withOpacity(0.03)
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * 600, cy + math.sin(angle) * 600),
        paint,
      );
    }

    // Core pulse glow
    final pulse = 1.0 + math.sin(t * 1.5) * 0.04;
    final coreGrad = RadialGradient(
      colors: [
        const Color(0xFFAAFF00).withOpacity(0.04),
        const Color(0xFFAAFF00).withOpacity(0.015),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(cx, cy),
      radius: 140 * pulse,
    ));
    canvas.drawCircle(
      Offset(cx, cy),
      300,
      Paint()..shader = coreGrad,
    );

    // Particles
    for (final p in _particles) {
      final twinkle = 0.5 + 0.5 * math.sin(p.twinklePhase);
      final alpha = p.baseOpacity * twinkle;

      if (p.isLime) {
        if (twinkle > 0.8) {
          final glow = Paint()
            ..color = const Color(0xFFAAFF00).withOpacity(alpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(p.x, p.y), p.size * 4, glow);
        }
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size,
          Paint()..color = const Color(0xFFAAFF00).withOpacity(alpha),
        );
      } else {
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size,
          Paint()..color = Colors.white.withOpacity(alpha * 0.5),
        );
      }
    }

    // Vignette
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = vignette,
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) => old.t != t;
}

class _Particle {
  double x, y, vx, vy, size, baseOpacity, twinkleSpeed, twinklePhase;
  bool isLime;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.baseOpacity,
    required this.isLime,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}

// ─── Scanline overlay ─────────────────────────────────────────────────────────

class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ScanlinePainter()),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y + 2), Offset(size.width, y + 2), paint);
      y += 4;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Stats strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _StatItem(value: '42', label: 'Sessions'),
        _StatDivider(),
        _StatItem(value: '6.2K', label: 'Volume'),
        _StatDivider(),
        _StatItem(value: '38m', label: 'Avg Time'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            letterSpacing: 2,
            color: Color(0x80999999),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

// ─── Swipe hints ─────────────────────────────────────────────────────────────

class _SwipeHints extends StatelessWidget {
  const _SwipeHints();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 24),
          child: Text(
            '← social',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Color(0x33999999),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 24),
          child: Text(
            'you →',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Color(0x33999999),
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
