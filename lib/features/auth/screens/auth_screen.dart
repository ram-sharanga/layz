// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/onboarding/screens/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _continueWithProvider(String provider) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    // TODO: Replace with actual Supabase OAuth
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: size.height * 0.15,
              left: -60,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 0, 28, botPad + 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Spacer(flex: 2),

                    // Logo + wordmark
                    Text('LAYZ',
                        style: GoogleFonts.dmSans(
                          fontSize: 64, fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -3, height: 1,
                        )),
                    const SizedBox(height: 10),
                    Text('Your physique. Your pace.\nNo excuses.',
                        style: GoogleFonts.dmSans(
                          fontSize: 18, height: 1.5,
                          color: Colors.white.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w400,
                        )),

                    const Spacer(flex: 3),

                    // Auth buttons
                    if (_loading)
                      const Center(child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                    else ...[
                      _AuthButton(
                        label:   'Continue with Google',
                        icon:    _googleIcon(),
                        onTap:   () => _continueWithProvider('google'),
                        primary: false,
                      ),
                      const SizedBox(height: 12),
                      _AuthButton(
                        label:   'Continue with Apple',
                        icon:    const Icon(Icons.apple,
                            color: Colors.black, size: 20),
                        onTap:   () => _continueWithProvider('apple'),
                        primary: true,
                      ),
                    ],

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'By continuing, you agree to our Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.2),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth button
// ─────────────────────────────────────────────────────────────────────────────

class _AuthButton extends StatefulWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });
  final String     label;
  final Widget     icon;
  final VoidCallback onTap;
  final bool       primary;

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color:        widget.primary ? Colors.white : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: widget.primary ? null : Border.all(
              color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 12),
              Text(widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: widget.primary ? Colors.black : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google logo painter
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2;

    // Simplified 4-color G logo
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final sweeps = [90.0, 90.0, 90.0, 90.0];
    double start = -90;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start * (3.14159 / 180),
        sweeps[i] * (3.14159 / 180),
        true,
        Paint()..color = colors[i],
      );
      start += sweeps[i];
    }
    // White center hole
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
} 