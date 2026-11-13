import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_tracker.dart';
import '../core/i18n/locale_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/data/auth_providers.dart';
import '../l10n/app_localizations.dart';
import 'pages/portal_dashboard_page.dart';
import 'pages/portal_hours_page.dart';
import 'pages/portal_menu_page.dart';
import 'pages/portal_invoices_page.dart';
import 'pages/portal_login_page.dart';
import 'pages/portal_orders_page.dart';
import 'pages/portal_reviews_page.dart';
import 'pages/portal_outlets_page.dart';
import 'pages/portal_reports_page.dart';
import 'pages/portal_team_page.dart';
import 'portal_shell.dart';

/// Where the portal sends a user. Pure, for tests.
///   signed out           -> /login
///   role not known yet   -> /loading
///   not a restaurant     -> /not-partner
///   restaurant on entry  -> /
String? portalRedirect({
  required String path,
  required bool signedIn,
  String? role,
}) {
  const entry = {'/login', '/loading', '/not-partner'};
  if (!signedIn) return path == '/login' ? null : '/login';
  if (role == null) return path == '/loading' ? null : '/loading';
  if (role != 'restaurant') {
    return path == '/not-partner' ? null : '/not-partner';
  }
  return entry.contains(path) ? '/' : null;
}

final portalRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(appSessionProvider);
  Page<void> page(Widget child) => NoTransitionPage(child: child);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) => portalRedirect(
      path: state.uri.path,
      signedIn: session.signedIn,
      role: session.role,
    ),
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const PortalLoginPage()),
      GoRoute(
        path: '/loading',
        builder: (_, _) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      GoRoute(
        path: '/not-partner',
        builder: (_, _) => const PortalNotPartnerPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            PortalShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, _) => page(const PortalDashboardPage()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (_, _) => page(const PortalOrdersPage()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (_, _) => page(const PortalReportsPage()),
          ),
          GoRoute(
            path: '/invoices',
            pageBuilder: (_, _) => page(const PortalInvoicesPage()),
          ),
          GoRoute(
            path: '/outlets',
            pageBuilder: (_, _) => page(const PortalOutletsPage()),
          ),
          GoRoute(
            path: '/team',
            pageBuilder: (_, _) => page(const PortalTeamPage()),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (_, _) => page(const PortalMenuPage()),
          ),
          GoRoute(
            path: '/hours',
            pageBuilder: (_, _) => page(const PortalHoursPage()),
          ),
          GoRoute(
            path: '/reviews',
            pageBuilder: (_, _) => page(const PortalReviewsPage()),
          ),
          for (final p in ['/marketing', '/notifications'])
            GoRoute(
              path: p,
              pageBuilder: (context, _) => page(
                Builder(
                  builder: (context) => ComingSoonPage(
                    title: portalNav(
                      AppLocalizations.of(context),
                    ).firstWhere((i) => i.path == p).label,
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
});

/// The restaurant partner portal (web). Same accounts, data, languages
/// and themes as the app.
class PortalApp extends ConsumerStatefulWidget {
  const PortalApp({super.key});

  @override
  ConsumerState<PortalApp> createState() => _PortalAppState();
}

class _PortalAppState extends ConsumerState<PortalApp>
    with WidgetsBindingObserver {
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

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    ref.watch(sessionTouchProvider(locale.languageCode));
    final dark = resolveDark(
      ref.watch(themeModeProvider),
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    AppColors.setDark(dark);
    return MaterialApp.router(
      key: ValueKey(dark),
      title: 'foodfennec Partner',
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
      routerConfig: ref.watch(portalRouterProvider),
    );
  }
}
