import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/i18n/locale_controller.dart';
import 'package:food_app/core/location/geocoding.dart';
import 'package:food_app/core/pdf/business_info.dart';
import 'package:food_app/core/utils/pick_image.dart';
import 'package:food_app/features/admin/data/admin_repository.dart';
import 'package:food_app/features/admin/pages/admin_receipt_pages.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:food_app/features/account/data/account_repository.dart';
import 'package:food_app/core/widgets/map_pin_picker.dart';
import 'package:food_app/features/catalog/data/catalog_repository.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:food_app/features/admin/data/admin_drivers.dart';
import 'package:food_app/features/restaurant_owner/data/owner_live.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/features/auth/data/auth_providers.dart';
import 'package:food_app/features/auth/data/auth_repository.dart';
import 'package:food_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_admin.dart';
import 'fake_data.dart';
import 'fake_driver.dart';
import 'fake_orders.dart';
import 'fake_owner_orders.dart';

export 'fake_admin.dart';
export 'fake_data.dart';
export 'fake_driver.dart';
export 'fake_orders.dart';
export 'fake_owner_orders.dart';

/// Address search without the network.
class FakeGeocoder implements Geocoder {
  final places = <Place>[
    const Place(
      label: '12, Rue Didouche Mourad, Alger Centre, Alger, Algérie',
      area: 'Alger Centre',
      lat: 36.7703,
      lng: 3.0560,
    ),
  ];

  @override
  Future<List<Place>> search(String query, {required String lang}) async =>
      query.trim().length < 3 ? const [] : places;

  @override
  Future<Place?> reverse(
    double lat,
    double lng, {
    required String lang,
  }) async => places.first;
}

class FakeBusinessInfoRepository implements BusinessInfoRepository {
  @override
  Future<AdminConfig> get() async => const AdminConfig(
    deliveryFee: 200,
    defaultCommissionRate: 0.08,
    businessName: 'Food DZ',
    businessPhone: '0550000000',
    businessTaxId: 'NIF123',
  );
}

/// 1×1 transparent PNG used as the fake camera's photo.
final fakePng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// In-memory auth backend: one code ("123456") for every email.
class FakeAuthRepository implements AuthRepository {
  static const validCode = '123456';

  final _users = <String, ({String name, String password, bool confirmed})>{};
  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  final calls = <String>[];

  /// email -> role; default 'customer'.
  final roles = <String, String>{};

  /// Mirrors Supabase "Confirm email": when false, sign-up signs in at once.
  bool requireEmailConfirmation = true;

  void seedUser(
    String email,
    String password, {
    String name = 'Karim',
    bool confirmed = true,
  }) {
    _users[email] = (name: name, password: password, confirmed: confirmed);
  }

  /// Starts the app already signed in as [email].
  void signInDirect(String email) => _setUser(email);

  void _setUser(String email) {
    final u = _users[email]!;
    _current = AppUser(id: 'id-$email', email: email, name: u.name);
    _ctrl.add(_current);
  }

  @override
  AppUser? get currentUser => _current;
  @override
  Stream<AppUser?> get userChanges => _ctrl.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    final u = _users[email];
    if (u == null || u.password != password) {
      throw const AuthError(AuthFailure.invalidCredentials);
    }
    if (!u.confirmed) throw const AuthError(AuthFailure.emailNotConfirmed);
    _setUser(email);
  }

  @override
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    calls.add('signUp:$email${phone == null ? '' : ':$phone'}');
    if (_users.containsKey(email)) {
      throw const AuthError(AuthFailure.userExists);
    }
    _users[email] = (
      name: name,
      password: password,
      confirmed: !requireEmailConfirmation,
    );
    if (requireEmailConfirmation) return false;
    _setUser(email);
    return true;
  }

  @override
  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) async {
    calls.add('verifySignup:$email:$code');
    if (code != validCode) throw const AuthError(AuthFailure.invalidCode);
    final u = _users[email]!;
    _users[email] = (name: u.name, password: u.password, confirmed: true);
    _setUser(email);
  }

  @override
  Future<void> resendSignupCode(String email) async =>
      calls.add('resend:$email');

  @override
  Future<void> sendRecoveryCode(String email) async =>
      calls.add('recovery:$email');

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    calls.add('verifyRecovery:$email:$code');
    if (code != validCode) throw const AuthError(AuthFailure.invalidCode);
    _setUser(email);
  }

  @override
  Future<void> updatePassword(String password) async {
    calls.add('updatePassword');
    final email = _current!.email;
    final u = _users[email]!;
    _users[email] = (name: u.name, password: password, confirmed: true);
  }

  @override
  Future<String> fetchRole() async =>
      _current == null ? 'customer' : (roles[_current!.email] ?? 'customer');

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _current = null;
    _ctrl.add(null);
  }
}

/// Pumps the whole app at phone size with a fake backend.
Future<FakeAuthRepository> pumpFoodApp(
  WidgetTester tester, {
  String lang = 'en',
  bool onboardingDone = true,
  bool locationAsked = true,
  FakeAuthRepository? repo,
  FakeCatalogRepository? catalog,
  FakeAccountRepository? account,
  FakeOwnerRepository? owner,
  FakeAdminRepository? admin,
  FakePdfOutput? pdf,
  FakeOrdersRepository? orders,
  FakeOwnerOrdersRepository? ownerOrders,
  FakeAlertSound? sound,
  FakeDriverRepository? driver,
  FakeAdminDriversRepository? adminDrivers,
  Size size = const Size(375, 812),
}) async {
  SharedPreferences.setMockInitialValues({
    'locale': lang,
    'onboarding_done': onboardingDone,
    'location_asked': locationAsked,
  });
  final prefs = await SharedPreferences.getInstance();
  final fake = repo ?? FakeAuthRepository();
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(fake),
        catalogRepositoryProvider.overrideWithValue(
          catalog ?? FakeCatalogRepository(),
        ),
        accountRepositoryProvider.overrideWithValue(
          account ?? FakeAccountRepository(),
        ),
        mapTileProvider.overrideWithValue(_NoCacheTiles()),
        ownerRepositoryProvider.overrideWithValue(
          owner ?? FakeOwnerRepository(),
        ),
        adminRepositoryProvider.overrideWithValue(
          admin ?? FakeAdminRepository(),
        ),
        pdfOutputProvider.overrideWithValue(pdf ?? FakePdfOutput()),
        ordersRepositoryProvider.overrideWithValue(
          orders ?? FakeOrdersRepository(),
        ),
        ownerOrdersRepositoryProvider.overrideWithValue(
          ownerOrders ?? FakeOwnerOrdersRepository(),
        ),
        alertSoundProvider.overrideWithValue(sound ?? FakeAlertSound()),
        driverRepositoryProvider.overrideWithValue(
          driver ?? FakeDriverRepository(),
        ),
        geocoderProvider.overrideWithValue(FakeGeocoder()),
        businessInfoRepositoryProvider.overrideWithValue(
          FakeBusinessInfoRepository(),
        ),
        // Fake camera: a 1×1 PNG.
        takeProofPhotoProvider.overrideWithValue(
          ({required bool camera}) async => PickedImage(fakePng, 'png'),
        ),
        adminDriversRepositoryProvider.overrideWithValue(
          adminDrivers ?? FakeAdminDriversRepository(),
        ),
      ],
      child: const FoodApp(),
    ),
  );
  // Splash: 900ms animation, then a 350ms timer. Step the fake clock so
  // timers created along the way also fire.
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  return fake;
}

/// Loads the real app fonts (tests default to a box font with very wide
/// glyphs), so layout and overflow checks match real devices.
Future<void> loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await family('Sen', [
    for (final w in [400, 700, 800]) 'assets/fonts/Sen-$w.ttf',
  ]);
  await family('NotoKufiArabic', [
    for (final w in [400, 700]) 'assets/fonts/NotoKufiArabic-$w.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  await family('MaterialIcons', [
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

class _NoCacheTiles extends NetworkTileProvider {
  _NoCacheTiles() : super(cachingProvider: const _NoCache());
}

class _NoCache with DisabledMapCachingProvider {
  const _NoCache();
}
