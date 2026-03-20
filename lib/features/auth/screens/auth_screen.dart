import 'package:flutter/material.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/onboarding/screens/onboarding_screen.dart';

// TODO: Add these packages to pubspec.yaml:
//   firebase_core, firebase_auth, google_sign_in, sign_in_with_apple

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // --- Auth handlers (wire Firebase here) ---

  Future<void> _signInWithGoogle(BuildContext context) async {
    // TODO:
    // final googleUser = await GoogleSignIn().signIn();
    // final googleAuth = await googleUser?.authentication;
    // final credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth?.accessToken,
    //   idToken: googleAuth?.idToken,
    // );
    // await FirebaseAuth.instance.signInWithCredential(credential);
    // Then check Supabase for onboarding_complete flag and route.

    // Placeholder navigation for now:
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  Future<void> _signInWithApple(BuildContext context) async {
    // TODO: implement Sign in with Apple
    // Requires Apple Developer account + entitlements.
    // Use the `sign_in_with_apple` package.
  }

  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),

              // Wordmark
              Text(
                'LAYZ',
                style: Theme.of(context).textTheme.displayLarge,
              ),

              const SizedBox(height: 12),

              Text(
                'Train. Track. Evolve.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
              ),

              const Spacer(flex: 3),

              // Google button
              _OAuthButton(
                label: 'Continue with Google',
                icon: _GoogleIcon(),
                onTap: () => _signInWithGoogle(context),
              ),

              const SizedBox(height: 12),

              // Apple button
              _OAuthButton(
                label: 'Continue with Apple',
                icon: const Icon(
                  Icons.apple,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onTap: () => _signInWithApple(context),
              ),

              const Spacer(flex: 1),

              // Legal note
              Center(
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable OAuth button ────────────────────────────────────────────────────

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Minimal Google 'G' icon (no asset needed) ───────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Coloured arc segments approximation using solid circle + wedges
    // Simple approach: draw the 4 colour arcs
    final colors = [
      const Color(0xFF4285F4), // blue   — right
      const Color(0xFF34A853), // green  — bottom
      const Color(0xFFFBBC05), // yellow — left
      const Color(0xFFEA4335), // red    — top-right
    ];

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;

    const sweeps = [1.2, 1.6, 1.2, 2.45]; // rough arc lengths in radians
    double start = -0.45;

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 1.5),
        start,
        sweeps[i],
        false,
        paint,
      );
      start += sweeps[i];
    }

    // White horizontal bar for the 'G' cutout
    final barPaint = Paint()
      ..color = const Color(0xFF111111) // matches surface
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r, cy),
      barPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - 2),
      Offset(cx, cy + 2),
      barPaint..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}