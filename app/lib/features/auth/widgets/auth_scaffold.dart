import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/language_switch.dart';
import '../../../core/widgets/sunburst.dart';

/// Shared layout of Log In / Sign Up / Verification / Forgot Password:
/// dark (#121223) header with a faint sunburst top-left and an orange dashed
/// line on the right, centred title + subtitle, then a white card with 24px
/// top radius starting at y=233 that holds the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.subtitleEmphasis,
  });

  final String title;
  final String subtitle;

  /// Second, bold subtitle line (the email on Verification).
  final String? subtitleEmphasis;
  final Widget child;
  final bool showBack;

  static const _cardTop = 233.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(
        children: [
          // Faint sunburst: SVG circle at (135.5,135.5) r88.5 w94 dash 4,
          // white 5%, placed at (-130,-141) → centre (5.5,-5.5).
          const Positioned(
            left: 5.5 - 135.5,
            top: -5.5 - 135.5,
            child: Sunburst(
              radius: 88.5,
              strokeWidth: 94,
              dash: 4,
              color: Color(0x0DFFFFFF),
            ),
          ),
          // Orange dashed curve on the right (pre-dashed paths, 20% opacity).
          // Decorative art is not mirrored in Arabic, same as the sunburst.
          Positioned(
            left: -130,
            top: -141,
            child: IgnorePointer(
              child: SvgPicture.asset(
                'assets/images/auth_header_pattern.svg',
                width: 600.5,
                height: 497.5,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _cardTop + topInset,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          start: 24,
                          top: 50 - 20,
                          child: showBack
                              ? CircleIconButton.back(context, onImage: true)
                              : const SizedBox.shrink(),
                        ),
                        const PositionedDirectional(
                          end: 24,
                          top: 50 - 20 + 6,
                          child: LanguageSwitch(onDark: true),
                        ),
                        Positioned.fill(
                          top: 98,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 26 / 16,
                                    color: Colors.white.withValues(alpha: .85),
                                  ),
                                ),
                                if (subtitleEmphasis != null)
                                  Text(
                                    subtitleEmphasis!,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
