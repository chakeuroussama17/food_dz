import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/sunburst.dart';
import '../auth/data/auth_providers.dart';

/// Splash Page_01 → 02: the logo on white (also shown by web/index.html
/// while Flutter loads), then the two sunbursts sweep in. Afterwards it
/// routes to onboarding, login or home.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final session = ref.read(appSessionProvider);
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    await Future.wait([
      session.applyRememberMe(),
      reduceMotion
          ? Future<void>.value()
          : _anim.forward().orCancel.catchError((_) {}),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final next = !session.onboardingDone
        ? '/welcome'
        : session.signedIn
        ? '/home'
        : '/login';
    context.go(next);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnimatedBuilder(
        animation: curve,
        builder: (context, _) {
          final t = curve.value;
          return Stack(
            children: [
              // Grey sunburst, top-left. Figma: centre (48.5,-32.5),
              // r 88.5, stroke 94, dash 4, #1E1E2E @ 5%.
              Positioned(
                left: 48.5 - 135.5,
                top: -32.5 - 135.5,
                child: Sunburst(
                  radius: 88.5,
                  strokeWidth: 94,
                  dash: 4,
                  color: const Color(0x0D1E1E2E),
                  progress: t,
                ),
              ),
              // Orange sunburst, bottom-right. Figma: centre (405.5, 812)
              // relative to a 375×812 frame, r ≈147, stroke 200, dash 6,
              // gradient #FFD88C → #FF7622 (light on the right).
              Positioned(
                right: 375 - 405.5 - 247,
                bottom: -247,
                child: Sunburst(
                  radius: 147,
                  strokeWidth: 200,
                  dash: 6,
                  progress: t,
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFFFFD88C), Color(0xFFFF7622)],
                  ),
                ),
              ),
              const Center(child: BrandLogo()),
            ],
          );
        },
      ),
    );
  }
}
