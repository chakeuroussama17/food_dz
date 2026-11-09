import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/config/env.dart';
import 'core/i18n/locale_controller.dart';
import 'core/push/push_service.dart';
import 'features/auth/data/auth_providers.dart';
import 'core/theme/app_theme.dart';
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

class FoodApp extends ConsumerWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

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
    return MaterialApp.router(
      title: 'Food App',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(locale),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
