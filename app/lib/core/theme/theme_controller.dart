import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/locale_controller.dart';

const _prefsKey = 'theme_mode';

/// System / light / dark, kept between launches.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(sharedPrefsProvider).getString(_prefsKey);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_prefsKey, mode.name);
  }
}

/// Whether [mode] means dark right now, given the phone's own setting.
bool resolveDark(ThemeMode mode, Brightness platform) => switch (mode) {
  ThemeMode.dark => true,
  ThemeMode.light => false,
  ThemeMode.system => platform == Brightness.dark,
};
