import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/locale_controller.dart';
import '../theme/app_colors.dart';

/// Compact "AR · FR · EN" segmented switch. Each label is written in its
/// own language so it is readable whatever the current language is.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  /// Translucent white style for the dark auth header.
  final bool onDark;

  static const _labels = {'ar': 'ع', 'fr': 'FR', 'en': 'EN'};
  static const _names = {'ar': 'العربية', 'fr': 'Français', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: .12) : AppColors.field,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in supportedLocales)
            Semantics(
              selected: l.languageCode == current,
              button: true,
              label: _names[l.languageCode],
              child: GestureDetector(
                onTap: () => ref.read(localeProvider.notifier).set(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 38,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: l.languageCode == current
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _labels[l.languageCode]!,
                    style: TextStyle(
                      fontFamily: l.languageCode == 'ar'
                          ? 'NotoKufiArabic'
                          : 'Sen',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: l.languageCode == current || onDark
                          ? Colors.white
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
