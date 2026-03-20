import 'dart:math';
import 'package:flutter/material.dart';
import 'package:layz/features/auth/screens/auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
// Cinematic entry point. Layers:
//   1. Base image (climb.png) with Ken Burns zoom
//   2. Vignette overlay
//   3. Headlamp light cone (lime, flickering)
//   4. Snow / ice particle system (CustomPainter)
//   5. Lightning flash (AnimatedOpacity)
//   6. Darkness breathing overlay
//   7. LAYZ wordmark — fades in at end
//   8. Auto-navigates after ~4.2s total
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Master ticker — drives everything
  late final AnimationController _master;

  // Ken Burns — slow zoom in over full duration
  late final Animation<double> _kenBurns;

  // Headlamp flicker — fast irregular pulse
  late final AnimationController _flicker;
  late final Animation<double> _flickerAnim;

  // Darkness breath — slow sinusoidal overlay
  late final AnimationController _breath;

  // Lightning — triggered manually on a timer
  late final AnimationController _lightning;

  // Wordmark fade
  late final AnimationController _wordmark;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  // Final fade out before navigation
  late final AnimationController _fadeOut;

  // Particle painter key to allow repaint
  final _particleKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // ── Master (5.5s total scene) ──────────────────
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _kenBurns = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _master, curve: Curves.easeInOut),
    );

    _master.forward();

    // ── Headlamp flicker ───────────────────────────
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _flickerAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _flicker, curve: Curves.easeInOut),
    );
    _runFlicker();

    // ── Darkness breath ────────────────────────────
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // ── Lightning ──────────────────────────────────
    _lightning = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scheduleLightning();

    // ── Wordmark ───────────────────────────────────
    _wordmark = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmark, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordmark, curve: Curves.easeOut));

    // Trigger wordmark at 1.8s
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _wordmark.forward();
    });

    // ── Navigate at 4.8s — auth screen fades IN over splash ───
    // Splash stays fully visible. AuthScreen animates in on top.
    _fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1), // instant — not used for fade
    );

    Future.delayed(const Duration(milliseconds: 4800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const AuthScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 900),
            reverseTransitionDuration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  // Irregular flicker: random duration, random delay
  void _runFlicker() async {
    final rng = Random();
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 60 + rng.nextInt(340)));
      if (!mounted) break;
      await _flicker.forward();
      await _flicker.reverse();
      // Occasional double-flicker
      if (rng.nextDouble() < 0.3) {
        await Future.delayed(const Duration(milliseconds: 30));
        await _flicker.forward();
        await _flicker.reverse();
      }
    }
  }

  // Lightning: fires 1-2 times during the scene
  void _scheduleLightning() async {
    final rng = Random();
    await Future.delayed(Duration(milliseconds: 800 + rng.nextInt(800)));
    if (!mounted) return;
    await _lightning.forward();
    await _lightning.reverse();
    await Future.delayed(const Duration(milliseconds: 60));
    await _lightning.forward();
    await _lightning.reverse();

    await Future.delayed(Duration(milliseconds: 600 + rng.nextInt(600)));
    if (!mounted) return;
    await _lightning.forward();
    await _lightning.reverse();
  }

  @override
  void dispose() {
    _master.dispose();
    _flicker.dispose();
    _breath.dispose();
    _lightning.dispose();
    _wordmark.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Headlamp position — top-right area of image (matches reference)
    final lampX = size.width * 0.72;
    final lampY = size.height * 0.28;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _master, _flicker, _breath, _lightning, _wordmark, _fadeOut,
        ]),
        builder: (context, _) {
          return Stack(
              fit: StackFit.expand,
              children: [

                // ── 1. BASE IMAGE — Ken Burns zoom ────────────
                // BoxFit.cover fills screen but anchors top so
                // the climber (top half of image) is always visible.
                // Ken Burns is subtle — 1.0 → 1.06 so aspect ratio
                // never feels distorted.
                Transform.scale(
                  scale: _kenBurns.value,
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/climb.png',
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                    alignment: Alignment.topCenter,
                  ),
                ),

                // ── 2. DARKNESS BREATH ────────────────────────
                // Subtle darkening pulse — like clouds passing over
                Opacity(
                  opacity: 0.18 + (_breath.value * 0.14),
                  child: Container(color: Colors.black),
                ),

                // ── 3. VIGNETTE ───────────────────────────────
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),

                // ── 4. HEADLAMP LIGHT CONE ────────────────────
                Positioned(
                  left: lampX - 120,
                  top: lampY - 80,
                  child: Opacity(
                    opacity: _flickerAnim.value * 0.75,
                    child: CustomPaint(
                      size: const Size(240, 260),
                      painter: _HeadlampPainter(),
                    ),
                  ),
                ),

                // Headlamp core bloom
                Positioned(
                  left: lampX - 40,
                  top: lampY - 40,
                  child: Opacity(
                    opacity: _flickerAnim.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFAAFF00).withValues(alpha: 0.55),
                            const Color(0xFFCCFF66).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 5. SNOW PARTICLE SYSTEM ───────────────────
                RepaintBoundary(
                  child: CustomPaint(
                    key: _particleKey,
                    painter: _SnowPainter(tick: _master.value),
                    size: size,
                  ),
                ),

                // ── 6. LIGHTNING FLASH ────────────────────────
                Opacity(
                  opacity: _lightning.value * 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.3, -0.6),
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── 7. WORDMARK ───────────────────────────────
                Positioned(
                  bottom: size.height * 0.12,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _wordmarkFade,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: const _Wordmark(),
                    ),
                  ),
                ),

              ],
            );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Headlamp light cone painter
// ─────────────────────────────────────────────────────────────────────────────

class _HeadlampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Cone — radiates bottom-left from top-right source
    final path = Path()
      ..moveTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width * 0.05, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.3, size.height * 1.0,
        size.width * 0.55, size.height * 0.95,
      )
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..close();

    paint.shader = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0x55AAFF00),
        Color(0x18AAFF00),
        Color(0x00000000),
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Snow / ice particle painter
// Driven by master tick (0.0 → 1.0 over 4.2s)
// Particles are seeded deterministically so they're consistent across repaints
// ─────────────────────────────────────────────────────────────────────────────

class _SnowPainter extends CustomPainter {
  final double tick;
  static final _rng = Random(42); // fixed seed = consistent particle layout
  static final List<_Particle> _particles = _initParticles();

  const _SnowPainter({required this.tick});

  static List<_Particle> _initParticles() {
    return List.generate(420, (i) {
      return _Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 1.4 + 0.2,
        speedX: -(_rng.nextDouble() * 0.18 + 0.08), // strong left wind
        speedY: _rng.nextDouble() * 0.04 + 0.005,
        opacity: _rng.nextDouble() * 0.55 + 0.12,
        isStreak: _rng.nextDouble() < 0.55, // majority are streaks
        wobble: _rng.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()..style = PaintingStyle.fill;
    final paintStreak = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    for (final p in _particles) {
      // Advance position based on tick
      final t = tick * 4.2; // scale tick to seconds
      var px = (p.x + p.speedX * t * 1.8) % 1.0;
      if (px < 0) px += 1.0;
      var py = (p.y + p.speedY * t + sin(p.wobble + t * 2.2) * 0.008) % 1.0;

      final sx = px * size.width;
      final sy = py * size.height;

      if (p.isStreak) {
        // Horizontal ice streak
        paintStreak.color = Color.fromRGBO(
          200, 218, 240, p.opacity * 0.65,
        );
        paintStreak.strokeWidth = p.size * 0.45;
        canvas.drawLine(
          Offset(sx, sy),
          Offset(sx + p.speedX * size.width * 0.12, sy + p.speedY * size.height * 0.05),
          paintStreak,
        );
      } else {
        // Fine ice dot
        paintDot.color = Color.fromRGBO(
          210, 225, 245, p.opacity,
        );
        canvas.drawCircle(Offset(sx, sy), p.size * 0.5, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) => old.tick != tick;
}

class _Particle {
  final double x, y, size, speedX, speedY, opacity, wobble;
  final bool isStreak;
  const _Particle({
    required this.x, required this.y,
    required this.size, required this.speedX, required this.speedY,
    required this.opacity, required this.wobble, required this.isStreak,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYZ wordmark
// ─────────────────────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LAYZ',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 16,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFFAAFF00),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}