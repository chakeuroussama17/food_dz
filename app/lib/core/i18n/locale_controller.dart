import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [Locale('ar'), Locale('fr'), Locale('en')];
const _prefsKey = 'locale';

/// Overridden in main() with the instance loaded at startup.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider not overridden'),
);

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_prefsKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      return Locale(saved);
    }
    // Default: device language if supported, otherwise Arabic.
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return supportedLocales.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => const Locale('ar'),
    );
  }

  void set(Locale locale) {
    state = locale;
    ref.read(sharedPrefsProvider).setString(_prefsKey, locale.languageCode);
  }
}
