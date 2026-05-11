import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Minimum display time so the splash is visible
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated logo ───────────────────────────────────────────
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 52)),
                  ),
                )
                .animate()
                .scale(duration: 700.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 1200.ms, color: Colors.white24),

            const SizedBox(height: 24),

            // ── App name ────────────────────────────────────────────────
            const Text(
              'AppForge',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

            const SizedBox(height: 8),

            // ── Tagline ─────────────────────────────────────────────────
            const Text(
              'Build apps without code',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 60),

            // ── Loading dots ────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) =>
                    Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(
                          begin: 0.6,
                          end: 1.2,
                          duration: 600.ms,
                          delay: Duration(milliseconds: i * 150),
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scaleXY(
                          begin: 1.2,
                          end: 0.6,
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 80),

            // ── Version ─────────────────────────────────────────────────
            const Text(
              'v1.0.0',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
