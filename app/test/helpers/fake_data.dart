import 'dart:typed_data';

import 'package:food_app/features/account/data/account_repository.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/catalog/data/catalog_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';

const _burger = FoodCategory(
  id: 'c-burger',
  slug: 'burger',
  nameAr: 'برغر',
  nameFr: 'Burger',
  nameEn: 'Burger',
);
const _pizza = FoodCategory(
  id: 'c-pizza',
  slug: 'pizza',
  nameAr: 'بيتزا',
  nameFr: 'Pizza',
  nameEn: 'Pizza',
);

/// Same shape as supabase/seed.sql, trimmed.
class FakeCatalogRepository implements CatalogRepository {
  final cats = [_burger, _pizza];

  final restaurantsList = <RestaurantSummary>[
    RestaurantSummary(
      id: 'r1',
      slug: 'pizzeria-el-bahdja',
      name: 'Pizzeria El Bahdja',
      description: 'Pizzas au feu de bois.',
      area: 'Bab Ezzouar',
      lat: 36.7213,
      lng: 3.1834,
      prepMinutes: 25,
      isOpen: true,
      categorySlugs: ['pizza'],
      minPrice: 700,
    ),
    RestaurantSummary(
      id: 'r2',
      slug: 'burger-house-hydra',
      name: 'Burger House',
      area: 'Hydra',
      isOpen: true,
      categorySlugs: ['burger'],
      minPrice: 750,
    ),
    RestaurantSummary(
      id: 'r3',
      slug: 'dar-lgharbi',
      name: 'Dar Lgharbi',
      area: 'Kouba',
      isOpen: false,
      categorySlugs: [],
    ),
  ];

  final items = <MenuItem>[
    MenuItem(
      id: 'i1',
      restaurantId: 'r1',
      categoryId: 'c-pizza',
      name: 'Pizza Margherita',
      price: 700,
      restaurantName: 'Pizzeria El Bahdja',
      restaurantSlug: 'pizzeria-el-bahdja',
    ),
    MenuItem(
      id: 'i2',
      restaurantId: 'r1',
      categoryId: 'c-pizza',
      name: 'Pizza Thon',
      price: 900,
      restaurantName: 'Pizzeria El Bahdja',
      restaurantSlug: 'pizzeria-el-bahdja',
    ),
    MenuItem(
      id: 'i3',
      restaurantId: 'r2',
      categoryId: 'c-burger',
      name: 'Smash Burger',
      price: 850,
      restaurantName: 'Burger House',
      restaurantSlug: 'burger-house-hydra',
    ),
    MenuItem(
      id: 'i4',
      restaurantId: 'r2',
      categoryId: 'c-burger',
      name: 'Burger Royal',
      price: 1300,
      isAvailable: false,
      restaurantName: 'Burger House',
      restaurantSlug: 'burger-house-hydra',
    ),
  ];

  @override
  Future<List<FoodCategory>> categories() async => cats;

  @override
  Future<List<RestaurantSummary>> restaurants({String? categorySlug}) async =>
      categorySlug == null
      ? restaurantsList
      : restaurantsList
            .where((r) => r.categorySlugs.contains(categorySlug))
            .toList();

  @override
  Future<RestaurantDetail?> restaurant(String slug) async {
    final r = restaurantsList.where((r) => r.slug == slug).firstOrNull;
    if (r == null) return null;
    return RestaurantDetail(
      restaurant: r,
      items: items.where((i) => i.restaurantId == r.id).toList(),
    );
  }

  @override
  Future<List<MenuItem>> itemsInCategory(String categoryId) async =>
      items.where((i) => i.categoryId == categoryId && i.isAvailable).toList();

  @override
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return [
      for (final r in restaurantsList.where(
        (r) => r.name.toLowerCase().contains(q),
      ))
        SearchHit(
          kind: 'restaurant',
          id: r.id,
          restaurantSlug: r.slug,
          title: r.name,
          subtitle: r.area,
        ),
      for (final i in items.where((i) => i.name.toLowerCase().contains(q)))
        SearchHit(
          kind: 'item',
          id: i.id,
          restaurantSlug: i.restaurantSlug!,
          title: i.name,
          subtitle: i.restaurantName!,
          price: i.price,
        ),
    ];
  }

  @override
  Future<int> deliveryFee() async => 200;

  /// Older tests check exact totals: no tax unless a test asks.
  double taxRateValue = 0;

  @override
  Future<double> taxRate() async => taxRateValue;

  /// Price overrides for [itemsByIds] (simulates a restaurant changing a
  /// price after the dish was added to the cart).
  final priceChanges = <String, int>{};

  @override
  Future<List<MenuItem>> itemsByIds(List<String> ids) async => [
    for (final i in items.where((i) => ids.contains(i.id)))
      MenuItem(
        id: i.id,
        restaurantId: i.restaurantId,
        categoryId: i.categoryId,
        name: i.name,
        price: priceChanges[i.id] ?? i.price,
        photoUrl: i.photoUrl,
        isAvailable: i.isAvailable,
        restaurantName: i.restaurantName,
        restaurantSlug: i.restaurantSlug,
      ),
  ];
}

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({String name = 'Karim Benali'})
    : profile = Profile(id: 'u1', fullName: name, email: 'k@mail.dz');

  Profile profile;
  final addressList = <Address>[];
  var _next = 0;

  @override
  Future<Profile> myProfile() async => profile;

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    profile = Profile(
      id: profile.id,
      fullName: fullName.trim(),
      email: profile.email,
      phone: phone,
      avatarUrl: profile.avatarUrl,
      birthDate: profile.birthDate,
      gender: profile.gender,
      wilaya: profile.wilaya,
      commune: profile.commune,
      referral: profile.referral,
      promptAnswered: profile.promptAnswered,
    );
  }

  final detailCalls = <String>[];

  @override
  Future<void> updateDetails(ProfileDetails d, {bool complete = false}) async {
    final b = d.birthDate;
    if (b != null &&
        (b.isAfter(DateTime.now().subtract(const Duration(days: 13 * 365))) ||
            b.year < DateTime.now().year - 100)) {
      throw const DetailsError(DetailsFailure.invalidBirthDate);
    }
    detailCalls.add(
      'details:${b?.year}:${d.gender}:${d.wilaya}:${d.commune}:${d.referral}:$complete',
    );
    profile = profile.copyWith(
      details: d,
      promptAnswered: complete || profile.promptAnswered,
    );
  }

  @override
  Future<void> skipProfilePrompt() async {
    detailCalls.add('skip');
    profile = profile.copyWith(promptAnswered: true);
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) async =>
      'https://example.com/a.jpg';

  @override
  Future<List<Address>> addresses() async =>
      [...addressList]
        ..sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));

  Address _from(String id, AddressInput i, bool def) => Address(
    id: id,
    label: i.label,
    addressText: i.addressText.trim(),
    area: i.area.trim(),
    details: i.details.trim(),
    lat: i.lat,
    lng: i.lng,
    isDefault: def,
  );

  @override
  Future<Address> addAddress(
    AddressInput input, {
    bool makeDefault = false,
  }) async {
    if (addressList.length >= 10) throw Exception('address limit reached');
    final a = _from('a${_next++}', input, false);
    addressList.add(a);
    if (makeDefault) await setDefaultAddress(a.id);
    return a;
  }

  @override
  Future<void> updateAddress(String id, AddressInput input) async {
    final i = addressList.indexWhere((a) => a.id == id);
    addressList[i] = _from(id, input, addressList[i].isDefault);
  }

  @override
  Future<void> deleteAddress(String id) async =>
      addressList.removeWhere((a) => a.id == id);

  /// Calls to [deleteMyAccount]; set [deleteFails] to simulate a refusal.
  int deleted = 0;
  DeleteAccountFailure? deleteFails;

  @override
  Future<void> deleteMyAccount() async {
    final f = deleteFails;
    if (f != null) throw DeleteAccountError(f);
    deleted++;
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    for (var i = 0; i < addressList.length; i++) {
      final a = addressList[i];
      addressList[i] = Address(
        id: a.id,
        label: a.label,
        addressText: a.addressText,
        area: a.area,
        details: a.details,
        lat: a.lat,
        lng: a.lng,
        isDefault: a.id == id,
      );
    }
  }
}

/// In-memory owner backend. [register] also flips the account's role in
/// the fake auth, like the real `register_restaurant` function.
class FakeOwnerRepository implements OwnerRepository {
  FakeOwnerRepository({this.onRegistered});

  /// Called with the new restaurant, e.g. to set the role in fake auth.
  void Function()? onRegistered;

  OwnedRestaurant? restaurant;
  final dishes = <MenuItem>[];
  var _n = 0;
  RestaurantRegistration? lastRegistration;

  /// More outlets of the same account (after [restaurant]).
  final otherOutlets = <OwnedRestaurant>[];

  @override
  Future<List<OwnedRestaurant>> myRestaurants() async => [
    ?restaurant,
    ...otherOutlets,
  ];

  /// Team per outlet id.
  final teams = <String, List<TeamMember>>{};

  /// Emails of accounts that exist (can be added to a team).
  final knownEmails = <String, String>{};

  @override
  Future<List<TeamMember>> team(String restaurantId) async => [
    ...?teams[restaurantId],
  ];

  @override
  Future<void> addMember(String restaurantId, String email, String role) async {
    final e = email.trim().toLowerCase();
    final name = knownEmails[e];
    if (name == null) throw const TeamError(TeamFailure.userNotFound);
    final t = teams.putIfAbsent(restaurantId, () => []);
    if (t.any((m) => m.email == e)) {
      throw const TeamError(TeamFailure.alreadyMember);
    }
    t.add(TeamMember(userId: 'u-$e', name: name, email: e, role: role));
  }

  @override
  Future<void> setMemberRole(
    String restaurantId,
    String userId,
    String role,
  ) async {
    final t = teams[restaurantId]!;
    final i = t.indexWhere((m) => m.userId == userId);
    final m = t[i];
    if (m.role == 'owner' &&
        role != 'owner' &&
        t.where((x) => x.role == 'owner').length == 1) {
      throw const TeamError(TeamFailure.lastOwner);
    }
    t[i] = TeamMember(
      userId: m.userId,
      name: m.name,
      email: m.email,
      role: role,
    );
  }

  @override
  Future<void> removeMember(String restaurantId, String userId) async {
    final t = teams[restaurantId]!;
    final m = t.firstWhere((x) => x.userId == userId);
    if (m.role == 'owner' && t.where((x) => x.role == 'owner').length == 1) {
      throw const TeamError(TeamFailure.lastOwner);
    }
    t.remove(m);
  }

  /// Set to make account deletion fail.
  DeleteRestaurantFailure? deleteFailure;
  bool deleted = false;

  @override
  Future<void> deleteMyAccount() async {
    final f = deleteFailure;
    if (f != null) throw DeleteRestaurantError(f);
    deleted = true;
    restaurant = null;
  }

  @override
  Future<String> register(RestaurantRegistration r) async {
    lastRegistration = r;
    if (restaurant != null) {
      // An owner adding another outlet.
      otherOutlets.add(
        OwnedRestaurant(
          id: 'own${otherOutlets.length + 2}',
          slug: 'outlet-${otherOutlets.length + 2}',
          name: r.name.trim(),
          phone: r.phone,
          address: r.address,
          area: r.area,
        ),
      );
      return 'own${otherOutlets.length + 1}';
    }
    restaurant = OwnedRestaurant(
      id: 'own1',
      slug: 'chez-omar',
      name: r.name.trim(),
      phone: r.phone,
      address: r.address,
      area: r.area,
      prepMinutes: r.prepMinutes,
    );
    onRegistered?.call();
    return 'own1';
  }

  @override
  Future<void> updateDetails(String id, RestaurantDetailsInput i) async {
    final o = restaurant!;
    restaurant = OwnedRestaurant(
      id: o.id,
      slug: o.slug,
      name: i.name.trim(),
      description: i.description.trim(),
      phone: i.phone,
      address: i.address.trim(),
      area: i.area.trim(),
      lat: i.lat,
      lng: i.lng,
      coverUrl: i.coverUrl,
      logoUrl: i.logoUrl,
      prepMinutes: i.prepMinutes,
      isActive: o.isActive,
      isOpen: o.isOpen,
    );
  }

  @override
  Future<void> setOpen(String id, bool open) async {
    if (!restaurant!.isActive) throw Exception('not approved');
    restaurant = restaurant!.copyWith(isOpen: open);
  }

  @override
  Future<List<MenuItem>> items(String restaurantId) async => [...dishes];

  MenuItem _make(String id, MenuItemInput i) => MenuItem(
    id: id,
    restaurantId: restaurant!.id,
    categoryId: i.categoryId,
    name: i.name.trim(),
    description: i.description.trim(),
    price: i.price,
    photoUrl: i.photoUrl,
    isAvailable: i.isAvailable,
  );

  @override
  Future<String> addItem(String restaurantId, MenuItemInput input) async {
    final id = 'm${_n++}';
    dishes.add(_make(id, input));
    return id;
  }

  @override
  Future<void> updateItem(String itemId, MenuItemInput input) async {
    final i = dishes.indexWhere((x) => x.id == itemId);
    dishes[i] = _make(itemId, input);
  }

  @override
  Future<void> setItemAvailable(String itemId, bool available) async {
    final i = dishes.indexWhere((x) => x.id == itemId);
    final o = dishes[i];
    dishes[i] = MenuItem(
      id: o.id,
      restaurantId: o.restaurantId,
      categoryId: o.categoryId,
      name: o.name,
      description: o.description,
      price: o.price,
      photoUrl: o.photoUrl,
      isAvailable: available,
    );
  }

  @override
  Future<void> deleteItem(String itemId) async =>
      dishes.removeWhere((x) => x.id == itemId);

  @override
  Future<String> uploadImage(String r, Uint8List b, String e) async =>
      'https://example.com/p.jpg';
}
