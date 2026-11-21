import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';

/// Apple asks for "Sign in with Apple" whenever an iPhone app offers
/// Google or Facebook login. Shown on iPhone only.
bool get showAppleSignIn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// "or continue with" + Google, Facebook (and Apple on iPhone). New users
/// get an account on first use; the terms are accepted on the next screen.
class SocialButtons extends ConsumerStatefulWidget {
  const SocialButtons({super.key});

  @override
  ConsumerState<SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends ConsumerState<SocialButtons> {
  String? _busy;

  Future<void> _go(String provider) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = provider);
    try {
      await ref.read(authRepositoryProvider).signInWithProvider(provider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errSocialLogin, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget button({
      required String provider,
      required String label,
      required Widget icon,
      Color? background,
      Color? foreground,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 54,
        child: OutlinedButton(
          key: Key('social:$provider'),
          style: OutlinedButton.styleFrom(
            backgroundColor: background ?? AppColors.surface,
            foregroundColor: foreground ?? AppColors.ink,
            side: BorderSide(color: background ?? AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _busy == null ? () => _go(provider) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_busy == provider)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground ?? AppColors.primary,
                  ),
                )
              else
                icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l.orContinueWith,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        button(
          provider: 'google',
          label: l.continueWithGoogle,
          icon: const _GoogleG(),
        ),
        button(
          provider: 'facebook',
          label: l.continueWithFacebook,
          icon: const Icon(Icons.facebook, color: Colors.white, size: 24),
          background: const Color(0xFF1877F2),
          foreground: Colors.white,
        ),
        if (showAppleSignIn)
          button(
            provider: 'apple',
            label: l.continueWithApple,
            icon: const Icon(Icons.apple, color: Colors.white, size: 24),
            background: Colors.black,
            foreground: Colors.white,
          ),
      ],
    );
  }
}

/// The four-colour "G" (drawn, no image file).
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (r) => const SweepGradient(
      colors: [
        Color(0xFFEA4335),
        Color(0xFFFBBC05),
        Color(0xFF34A853),
        Color(0xFF4285F4),
        Color(0xFFEA4335),
      ],
      stops: [0, .25, .5, .75, 1],
    ).createShader(r),
    child: const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
      ),
    ),
  );
}
