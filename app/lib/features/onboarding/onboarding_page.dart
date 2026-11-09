import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';
import '../auth/data/auth_providers.dart';

/// Onboarding_01..03: illustration, title, text, dots, NEXT / Skip.
/// Last page shows GET STARTED.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _count = 3;

  Future<void> _finish() async {
    await ref.read(appSessionProvider).completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_index == _count - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      (l.onb1Title, l.onb1Body),
      (l.onb2Title, l.onb2Body),
      (l.onb3Title, l.onb3Body),
    ];
    final last = _index == _count - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 12, end: 24),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LanguageSwitch(),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _count,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _Slide(index: i, title: pages[i].$1, body: pages[i].$2),
                  ),
                ),
                _Dots(count: _count, index: _index),
                const SizedBox(height: 69),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppButton(
                    label: last ? l.getStarted : l.next,
                    onPressed: _next,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: last
                      ? null
                      : TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.body,
                          ),
                          child: Text(
                            l.skip,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.index, required this.title, required this.body});

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Illustration is 240×292 in a 812-tall frame; shrink on short
        // screens so title and text always fit.
        final imgH = (c.maxHeight - 190).clamp(120.0, 292.0);
        return Column(
          children: [
            const Spacer(),
            _Illustration(index: index, height: imgH),
            const SizedBox(height: 63),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  color: AppColors.body,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

/// Uses `assets/images/onboarding_<n>.png` when present, otherwise the grey
/// 240×292 placeholder from the Figma file.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.index, required this.height});
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 240 / 292;
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Image.asset(
      'assets/images/onboarding_${index + 1}.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? AppColors.primary : AppColors.primaryPale,
            ),
          ),
      ],
    );
  }
}
