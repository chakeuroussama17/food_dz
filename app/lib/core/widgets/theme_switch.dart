import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Compact "auto · ☀ · ☾" segmented switch, same style as the language
/// switch. Sits next to it on every account / settings page.
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(themeModeProvider);
    final items = [
      (ThemeMode.system, Icons.brightness_auto_rounded, l.themeSystem),
      (ThemeMode.light, Icons.light_mode_rounded, l.themeLight),
      (ThemeMode.dark, Icons.dark_mode_rounded, l.themeDark),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, icon, label) in items)
            Semantics(
              selected: mode == current,
              button: true,
              label: label,
              child: Tooltip(
                message: label,
                child: GestureDetector(
                  onTap: () => ref.read(themeModeProvider.notifier).set(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 38,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mode == current
                          ? AppColors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: mode == current ? Colors.white : AppColors.inkSoft,
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
