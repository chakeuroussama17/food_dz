import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/account/data/account_repository.dart';
import '../features/account/pages/account_page.dart';
import '../features/account/pages/address_form_page.dart';
import '../features/account/pages/addresses_page.dart';
import '../features/account/pages/edit_profile_page.dart';
import '../features/account/pages/personal_info_page.dart';
import '../features/account/pages/terms_page.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/pages/forgot_password_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/reset_password_page.dart';
import '../features/auth/pages/signup_page.dart';
import '../features/auth/pages/verify_page.dart';
import '../features/cart/cart_page.dart';
import '../features/catalog/pages/category_page.dart';
import '../features/catalog/pages/item_page.dart';
import '../features/catalog/pages/restaurant_page.dart';
import '../features/catalog/pages/search_page.dart';
import '../features/dev/gallery_page.dart';
import '../features/driver/pages/driver_home_page.dart';
import '../features/driver/pages/driver_order_page.dart';
import '../features/driver/pages/driver_other_pages.dart';
import '../features/driver/pages/driver_register_page.dart';
import '../features/admin/pages/admin_drivers_page.dart';
import '../features/admin/pages/admin_banners_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/location_access_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/onboarding/splash_page.dart';
import '../features/orders/pages/my_orders_page.dart';
import '../features/orders/pages/order_page.dart';
import '../features/orders/pages/order_placed_page.dart';
import '../features/admin/pages/admin_dashboard_page.dart';
import '../features/admin/pages/admin_orders_page.dart';
import '../features/admin/pages/admin_receipt_pages.dart';
import '../features/admin/pages/admin_receipts_page.dart';
import '../features/admin/pages/admin_restaurants_page.dart';
import '../features/admin/pages/admin_settings_page.dart';
import '../features/catalog/data/catalog_models.dart';
import '../features/restaurant_owner/data/owner_repository.dart';
import '../features/restaurant_owner/pages/owner_dashboard_page.dart';
import '../features/restaurant_owner/pages/owner_item_form_page.dart';
import '../features/restaurant_owner/pages/owner_menu_page.dart';
import '../features/restaurant_owner/pages/owner_orders_page.dart';
import '../features/restaurant_owner/pages/owner_profile_page.dart';
import '../features/restaurant_owner/pages/owner_statements_page.dart';
import '../features/restaurant_owner/pages/restaurant_register_page.dart';

/// Pages only for signed-out users.
const _authPaths = {
  '/welcome',
  '/login',
  '/signup',
  '/verify',
  '/forgot-password',
};

/// Restaurant sign-up form: open to visitors and to signed-in customers.
const restaurantRegisterPath = '/restaurant/register';

/// Driver sign-up form: same rule.
const driverRegisterPath = '/driver/register';

bool _isRegisterPath(String p) =>
    p == restaurantRegisterPath || p == driverRegisterPath;

/// Where each role lands after login.
String homeFor(String role) => switch (role) {
  'restaurant' => '/restaurant',
  'admin' => '/admin',
  'driver' => '/driver',
  _ => '/home',
};

bool _isAdminArea(String path) =>
    path == '/admin' || path.startsWith('/admin/');

bool _isOwnerArea(String path) =>
    (path == '/restaurant' || path.startsWith('/restaurant/')) &&
    path != restaurantRegisterPath;

bool _isDriverArea(String path) =>
    (path == '/driver' || path.startsWith('/driver/')) &&
    path != driverRegisterPath;

/// Can [role] open [path]? Owners stay in /restaurant/..., the admin in
/// /admin/...; customers can open neither.
bool _allowedFor(String role, String path) => switch (role) {
  'restaurant' => _isOwnerArea(path),
  'admin' => _isAdminArea(path),
  'driver' => _isDriverArea(path),
  _ => !_isOwnerArea(path) && !_isAdminArea(path) && !_isDriverArea(path),
};

/// Only same-app paths, never an external URL.
String? _safeFrom(String? from) =>
    from != null && from.startsWith('/') && !from.startsWith('//')
    ? from
    : null;

/// Pure routing rule, kept separate so it can be unit-tested.
///
/// * Signed-out visitors opening a private page (e.g. a restaurant's QR
///   link `/r/slug`) go to `/login?from=/r/slug` and come back after login.
/// * Signed-in users wait on `/loading` until their role is known, then go
///   to their area: customers `/home`, restaurant owners `/restaurant`.
String? authRedirect({
  required String path,
  required bool signedIn,
  required bool recoveringPassword,
  String? role,
  bool registeringRestaurant = false,
  String? from,
  String? fullLocation,
}) {
  if (path == '/' || path.startsWith('/dev/')) return null;
  if (path == '/reset-password') {
    return signedIn && recoveringPassword ? null : '/login';
  }
  if (signedIn && recoveringPassword) return '/reset-password';

  if (!signedIn) {
    if (_authPaths.contains(path) || _isRegisterPath(path)) {
      return null;
    }
    if (path == '/loading') return '/login';
    final target = fullLocation ?? path;
    return target == '/home'
        ? '/login'
        : Uri(path: '/login', queryParameters: {'from': target}).toString();
  }

  // Signed in.
  if (registeringRestaurant) return null; // the form finishes its work
  final entry = path == '/loading' || _authPaths.contains(path);
  if (role == null) {
    if (path == '/loading') return null;
    final back = entry ? _safeFrom(from) : (fullLocation ?? path);
    return back == null
        ? '/loading'
        : Uri(path: '/loading', queryParameters: {'from': back}).toString();
  }
  if (entry) {
    final back = _safeFrom(from);
    if (back != null && _allowedFor(role, Uri.parse(back).path)) return back;
    return homeFor(role);
  }
  if (!_allowedFor(role, path)) return homeFor(role);
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(appSessionProvider);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) => authRedirect(
      path: state.uri.path,
      signedIn: session.signedIn,
      recoveringPassword: session.recoveringPassword,
      role: session.role,
      registeringRestaurant: session.registeringRestaurant,
      from: state.uri.queryParameters['from'],
      fullLocation: state.uri.toString(),
    ),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
      GoRoute(
        path: '/verify',
        builder: (_, state) => VerifyPage(
          email: state.uri.queryParameters['email'] ?? '',
          purpose: state.uri.queryParameters['purpose'] == 'recovery'
              ? VerifyPurpose.recovery
              : VerifyPurpose.signup,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(path: '/loading', builder: (_, _) => const _LoadingPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/location', builder: (_, _) => const LocationAccessPage()),
      GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
      GoRoute(
        path: '/category/:slug',
        builder: (_, s) => CategoryPage(slug: s.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/r/:slug',
        builder: (_, s) => RestaurantPage(slug: s.pathParameters['slug']!),
        routes: [
          GoRoute(
            path: 'item/:itemId',
            builder: (_, s) => ItemPage(
              slug: s.pathParameters['slug']!,
              itemId: s.pathParameters['itemId']!,
            ),
          ),
        ],
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartPage()),
      GoRoute(path: '/terms', builder: (_, _) => const TermsPage()),
      GoRoute(
        path: '/orders',
        builder: (_, _) => const MyOrdersPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) => OrderPage(orderId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'placed',
                builder: (_, s) =>
                    OrderPlacedPage(orderId: s.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      // Admin.
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminDashboardPage(),
        routes: [
          GoRoute(
            path: 'restaurants',
            builder: (_, _) => const AdminRestaurantsPage(),
          ),
          GoRoute(path: 'orders', builder: (_, _) => const AdminOrdersPage()),
          GoRoute(
            path: 'receipts',
            builder: (_, _) => const AdminReceiptsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, s) => AdminNewReceiptPage(
                  restaurantId: s.uri.queryParameters['restaurant'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    AdminReceiptPage(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (_, _) => const AdminSettingsPage(),
          ),
          GoRoute(
            path: 'customers',
            builder: (_, _) => const AdminCustomersPage(),
          ),
          GoRoute(path: 'drivers', builder: (_, _) => const AdminDriversPage()),
          GoRoute(path: 'banners', builder: (_, _) => const AdminBannersPage()),
        ],
      ),
      // Drivers.
      GoRoute(
        path: '/driver',
        builder: (_, _) => const DriverHomePage(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (_, _) => const DriverRegisterPage(),
          ),
          GoRoute(
            path: 'deliveries',
            builder: (_, _) => const DriverDeliveriesPage(),
          ),
          GoRoute(
            path: 'account',
            builder: (_, _) => const DriverAccountPage(),
          ),
          GoRoute(
            path: 'orders/:id',
            builder: (_, s) =>
                DriverOrderPage(orderId: s.pathParameters['id']!),
          ),
        ],
      ),
      // Restaurant owners.
      GoRoute(
        path: '/restaurant',
        builder: (_, _) => const OwnerDashboardPage(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (_, _) => const RestaurantRegisterPage(),
          ),
          GoRoute(
            path: 'menu',
            builder: (_, _) => const OwnerMenuPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const OwnerItemFormPage(),
              ),
              GoRoute(
                path: ':itemId',
                builder: (_, s) => _EditItemRoute(
                  id: s.pathParameters['itemId']!,
                  passed: s.extra as MenuItem?,
                ),
              ),
            ],
          ),
          GoRoute(path: 'profile', builder: (_, _) => const OwnerProfilePage()),
          GoRoute(
            path: 'statements',
            builder: (_, _) => const OwnerStatementsPage(),
          ),
          GoRoute(
            path: 'orders',
            builder: (_, s) => OwnerOrdersPage(
              key: ValueKey(s.uri.queryParameters['tab']),
              initialTab: switch (s.uri.queryParameters['tab']) {
                'new' => OwnerOrdersTab.fresh,
                'running' => OwnerOrdersTab.running,
                'history' => OwnerOrdersTab.history,
                _ => null,
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        builder: (_, _) => const AccountPage(),
        routes: [
          GoRoute(
            path: 'personal',
            builder: (_, _) => const PersonalInfoPage(),
          ),
          GoRoute(path: 'edit', builder: (_, _) => const EditProfilePage()),
          GoRoute(
            path: 'addresses',
            builder: (_, _) => const AddressesPage(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const AddressFormPage()),
              GoRoute(
                path: ':id',
                builder: (_, s) => _EditAddressRoute(
                  id: s.pathParameters['id']!,
                  passed: s.extra as Address?,
                ),
              ),
            ],
          ),
        ],
      ),
      if (kDebugMode)
        GoRoute(path: '/dev/gallery', builder: (_, _) => const GalleryPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Edit form for an address: uses the one passed from the list, or loads it
/// (e.g. after a browser refresh).
class _EditAddressRoute extends ConsumerWidget {
  const _EditAddressRoute({required this.id, this.passed});
  final String id;
  final Address? passed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (passed != null) return AddressFormPage(existing: passed);
    final list = ref.watch(addressesProvider);
    return list.when(
      data: (all) {
        final a = all.where((x) => x.id == id).firstOrNull;
        return a == null ? const AddressesPage() : AddressFormPage(existing: a);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => const AddressesPage(),
    );
  }
}

/// Shown for a moment after login while the account's role loads.
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

/// Edit form for a dish: uses the one passed from the menu list, or loads
/// it (after a browser refresh).
class _EditItemRoute extends ConsumerWidget {
  const _EditItemRoute({required this.id, this.passed});
  final String id;
  final MenuItem? passed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (passed != null) return OwnerItemFormPage(existing: passed);
    final r = ref.watch(myRestaurantProvider).value;
    if (r == null) return const _LoadingPage();
    return ref
        .watch(myItemsProvider(r.id))
        .when(
          data: (items) {
            final it = items.where((i) => i.id == id).firstOrNull;
            return it == null
                ? const OwnerMenuPage()
                : OwnerItemFormPage(existing: it);
          },
          loading: () => const _LoadingPage(),
          error: (_, _) => const OwnerMenuPage(),
        );
  }
}
