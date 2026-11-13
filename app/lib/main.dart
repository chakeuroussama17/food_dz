import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/session/session_tracker.dart';
import 'core/config/env.dart';
import 'core/i18n/locale_controller.dart';
import 'core/push/push_service.dart';
import 'features/sanctions/restriction_gate.dart';
import 'features/auth/data/auth_providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs on web (/r/my-restaurant instead of /#/r/my-restaurant)
  // so QR codes stay short.
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const FoodApp(),
    ),
  );
}

class FoodApp extends ConsumerStatefulWidget {
  const FoodApp({super.key});

  @override
  ConsumerState<FoodApp> createState() => _FoodAppState();
}

class _FoodAppState extends ConsumerState<FoodApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The phone switched between light and dark ("Auto" follows it).
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final dark = resolveDark(
      ref.watch(themeModeProvider),
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    // Set the palette before anything below reads a colour.
    AppColors.setDark(dark);

    // Push alerts: register this phone once signed in (and again when the
    // language changes, so alerts come in the right language).
    void startPush() {
      if (ref.read(currentUserIdProvider).value == null) return;
      ref
          .read(pushServiceProvider)
          .start(
            lang: ref.read(localeProvider).languageCode,
            onOpen: (route) => ref.read(routerProvider).go(route),
          );
    }

    ref.listen(currentUserIdProvider, (prev, next) {
      if (next.value != null && next.value != prev?.value) startPush();
    });
    ref.listen(localeProvider, (prev, next) {
      if (prev?.languageCode != next.languageCode) startPush();
    });
    // Last seen, app version, phone model (admin analysis).
    ref.watch(sessionTouchProvider(locale.languageCode));
    return MaterialApp.router(
      // A new key rebuilds every page with the new palette.
      key: ValueKey(dark),
      title: 'foodfennec',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(locale, dark: dark),
      routerConfig: ref.watch(routerProvider),
      // Suspended / banned: only the reason; warnings shown once.
      builder: (context, child) =>
          RestrictionGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
