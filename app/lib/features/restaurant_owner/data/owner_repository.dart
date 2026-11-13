import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../auth/data/auth_providers.dart';
import '../../catalog/data/catalog_models.dart';

/// The owner's own restaurant, including private fields (approval).
class OwnedRestaurant {
  const OwnedRestaurant({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.phone = '',
    this.address = '',
    this.area = '',
    this.lat,
    this.lng,
    this.coverUrl,
    this.logoUrl,
    this.prepMinutes = 20,
    this.isActive = false,
    this.isOpen = false,
    this.role = 'owner',
  });

  /// The signed-in user's role here: owner, manager or staff.
  final String role;
  bool get isOwner => role == 'owner';

  /// Menu, details, reports, statements.
  bool get canManage => role == 'owner' || role == 'manager';

  final String id;
  final String slug;
  final String name;
  final String description;
  final String phone;
  final String address;
  final String area;
  final double? lat;
  final double? lng;
  final String? coverUrl;
  final String? logoUrl;
  final int prepMinutes;

  /// Approved by the admin (visible to customers).
  final bool isActive;
  final bool isOpen;

  OwnedRestaurant copyWith({bool? isOpen}) => OwnedRestaurant(
    id: id,
    slug: slug,
    name: name,
    description: description,
    phone: phone,
    address: address,
    area: area,
    lat: lat,
    lng: lng,
    coverUrl: coverUrl,
    logoUrl: logoUrl,
    prepMinutes: prepMinutes,
    isActive: isActive,
    isOpen: isOpen ?? this.isOpen,
    role: role,
  );

  factory OwnedRestaurant.fromJson(Map<String, dynamic> j) => OwnedRestaurant(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    description: (j['description'] as String?) ?? '',
    phone: (j['phone'] as String?) ?? '',
    address: (j['address'] as String?) ?? '',
    area: (j['area'] as String?) ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    coverUrl: j['cover_url'] as String?,
    logoUrl: j['logo_url'] as String?,
    prepMinutes: (j['prep_minutes'] as num?)?.toInt() ?? 20,
    isActive: (j['is_active'] as bool?) ?? false,
    isOpen: (j['is_open'] as bool?) ?? false,
    role: (j['my_role'] as String?) ?? 'owner',
  );
}

/// Fields of the registration form (restaurant part).
class RestaurantRegistration {
  const RestaurantRegistration({
    required this.name,
    required this.phone,
    required this.address,
    this.area = '',
    this.prepMinutes = 20,
    this.lat,
    this.lng,
  });

  final String name;
  final String phone;
  final String address;
  final String area;
  final int prepMinutes;
  final double? lat;
  final double? lng;
}

/// Editable restaurant details (profile page).
class RestaurantDetailsInput {
  const RestaurantDetailsInput({
    required this.name,
    required this.description,
    required this.phone,
    required this.address,
    required this.area,
    required this.prepMinutes,
    this.lat,
    this.lng,
    this.coverUrl,
    this.logoUrl,
  });

  final String name;
  final String description;
  final String phone;
  final String address;
  final String area;
  final int prepMinutes;
  final double? lat;
  final double? lng;
  final String? coverUrl;
  final String? logoUrl;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'phone': phone,
    'address': address.trim(),
    'area': area.trim(),
    'prep_minutes': prepMinutes,
    'lat': lat,
    'lng': lng,
    'cover_url': coverUrl,
    'logo_url': logoUrl,
  };
}

/// Add / edit dish form.
class MenuItemInput {
  const MenuItemInput({
    required this.name,
    required this.price,
    this.description = '',
    this.categoryId,
    this.photoUrl,
    this.isAvailable = true,
  });

  final String name;
  final int price;
  final String description;
  final String? categoryId;
  final String? photoUrl;
  final bool isAvailable;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'price': price,
    'description': description.trim(),
    'category_id': categoryId,
    'photo_url': photoUrl,
    'is_available': isAvailable,
  };
}

abstract interface class OwnerRepository {
  /// Every outlet the account belongs to, with its role there.
  Future<List<OwnedRestaurant>> myRestaurants();

  /// The outlet's team. Managers and owners.
  Future<List<TeamMember>> team(String restaurantId);

  /// Owners only. Throws [TeamError].
  Future<void> addMember(String restaurantId, String email, String role);
  Future<void> setMemberRole(String restaurantId, String userId, String role);
  Future<void> removeMember(String restaurantId, String userId);

  /// Makes the signed-in account a restaurant owner (inactive until the
  /// admin approves). Returns the restaurant id.
  Future<String> register(RestaurantRegistration r);

  Future<void> updateDetails(String restaurantId, RestaurantDetailsInput input);
  Future<void> setOpen(String restaurantId, bool open);

  Future<List<MenuItem>> items(String restaurantId);

  /// Returns the new dish's id.
  Future<String> addItem(String restaurantId, MenuItemInput input);
  Future<void> updateItem(String itemId, MenuItemInput input);
  Future<void> setItemAvailable(String itemId, bool available);
  Future<void> deleteItem(String itemId);

  /// Uploads a photo to `restaurant-media/<restaurant id>/` and returns its URL.
  Future<String> uploadImage(
    String restaurantId,
    Uint8List bytes,
    String extension,
  );

  /// Deletes the login; the restaurant is archived (hidden) and its orders
  /// and statements kept. Throws [DeleteRestaurantError].
  Future<void> deleteMyAccount();
}

enum DeleteRestaurantFailure {
  activeOrders,
  cashPending,
  unpaidCommission,
  network,
}

class DeleteRestaurantError implements Exception {
  const DeleteRestaurantError(this.failure);
  final DeleteRestaurantFailure failure;
  @override
  String toString() => 'DeleteRestaurantError($failure)';
}

const _itemCols =
    'id, restaurant_id, category_id, name, description, price, photo_url, '
    'is_available, sort_order';

class SupabaseOwnerRepository implements OwnerRepository {
  SupabaseOwnerRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<OwnedRestaurant>> myRestaurants() async {
    List rows;
    try {
      rows = await _db.rpc('my_restaurants') as List;
    } on PostgrestException {
      // Database not updated yet (outlets SQL): one restaurant.
      rows = await _db.rpc('my_restaurant') as List;
    }
    return [
      for (final r in rows) OwnedRestaurant.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<TeamMember>> team(String restaurantId) async {
    final rows =
        await _db.rpc(
              'restaurant_team',
              params: {'p_restaurant_id': restaurantId},
            )
            as List;
    return [
      for (final r in rows) TeamMember.fromJson(r as Map<String, dynamic>),
    ];
  }

  Future<void> _team(String fn, Map<String, dynamic> params) async {
    try {
      await _db.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      final m = e.message;
      throw TeamError(switch (m) {
        _ when m.contains('user_not_found') => TeamFailure.userNotFound,
        _ when m.contains('user_has_other_role') => TeamFailure.otherRole,
        _ when m.contains('already_member') => TeamFailure.alreadyMember,
        _ when m.contains('last_owner') => TeamFailure.lastOwner,
        _ => TeamFailure.notAllowed,
      });
    } catch (_) {
      throw const TeamError(TeamFailure.network);
    }
  }

  @override
  Future<void> addMember(String restaurantId, String email, String role) =>
      _team('owner_add_member', {
        'p_restaurant_id': restaurantId,
        'p_email': email.trim(),
        'p_role': role,
      });

  @override
  Future<void> setMemberRole(String restaurantId, String userId, String role) =>
      _team('owner_set_member_role', {
        'p_restaurant_id': restaurantId,
        'p_user_id': userId,
        'p_role': role,
      });

  @override
  Future<void> removeMember(String restaurantId, String userId) => _team(
    'owner_remove_member',
    {'p_restaurant_id': restaurantId, 'p_user_id': userId},
  );

  @override
  Future<String> register(RestaurantRegistration r) async {
    final id = await _db.rpc(
      'register_restaurant',
      params: {
        'p_name': r.name.trim(),
        'p_phone': r.phone,
        'p_address': r.address.trim(),
        'p_area': r.area.trim(),
        'p_lat': r.lat,
        'p_lng': r.lng,
        'p_prep_minutes': r.prepMinutes,
      },
    );
    return id as String;
  }

  @override
  Future<void> updateDetails(String id, RestaurantDetailsInput input) =>
      _db.from('restaurants').update(input.toJson()).eq('id', id);

  @override
  Future<void> setOpen(String id, bool open) =>
      _db.from('restaurants').update({'is_open': open}).eq('id', id);

  @override
  Future<List<MenuItem>> items(String restaurantId) async {
    final rows = await _db
        .from('menu_items')
        .select(_itemCols)
        .eq('restaurant_id', restaurantId)
        .order('sort_order')
        .order('created_at');
    return rows.map(MenuItem.fromJson).toList();
  }

  @override
  Future<String> addItem(String restaurantId, MenuItemInput input) async {
    final row = await _db
        .from('menu_items')
        .insert({...input.toJson(), 'restaurant_id': restaurantId})
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> updateItem(String itemId, MenuItemInput input) =>
      _db.from('menu_items').update(input.toJson()).eq('id', itemId);

  @override
  Future<void> setItemAvailable(String itemId, bool available) => _db
      .from('menu_items')
      .update({'is_available': available})
      .eq('id', itemId);

  @override
  Future<void> deleteItem(String itemId) =>
      _db.from('menu_items').delete().eq('id', itemId);

  @override
  Future<String> uploadImage(
    String restaurantId,
    Uint8List bytes,
    String extension,
  ) async {
    final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final path = '$restaurantId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _db.storage.from('restaurant-media');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return bucket.getPublicUrl(path);
  }

  @override
  Future<void> deleteMyAccount() async {
    try {
      await _db.rpc('delete_my_restaurant_account');
    } on PostgrestException catch (e) {
      final m = e.message;
      throw DeleteRestaurantError(
        m.contains('active_orders')
            ? DeleteRestaurantFailure.activeOrders
            : m.contains('cash_pending')
            ? DeleteRestaurantFailure.cashPending
            : m.contains('unpaid_commission')
            ? DeleteRestaurantFailure.unpaidCommission
            : DeleteRestaurantFailure.network,
      );
    } catch (_) {
      throw const DeleteRestaurantError(DeleteRestaurantFailure.network);
    }
  }
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseOwnerRepository(Supabase.instance.client);
});

/// Every outlet of the signed-in account (reloads on login / logout).
final myRestaurantsProvider = FutureProvider<List<OwnedRestaurant>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerRepositoryProvider).myRestaurants();
});

/// The outlet the app shows (chosen in the header, kept on the device).
class SelectedOutlet extends Notifier<String?> {
  static const _key = 'outlet_id';

  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_key);

  Future<void> select(String id) async {
    state = id;
    await ref.read(sharedPrefsProvider).setString(_key, id);
  }
}

final selectedOutletProvider = NotifierProvider<SelectedOutlet, String?>(
  SelectedOutlet.new,
);

/// The outlet shown in the app: the chosen one, else the first.
final myRestaurantProvider = FutureProvider<OwnedRestaurant?>((ref) async {
  final all = await ref.watch(myRestaurantsProvider.future);
  if (all.isEmpty) return null;
  final id = ref.watch(selectedOutletProvider);
  return all.where((r) => r.id == id).firstOrNull ?? all.first;
});

/// Outlet filter for the order calls: null with a single outlet (works
/// before the outlets SQL is applied), else the shown outlet.
final outletFilterProvider = FutureProvider<String?>((ref) async {
  final all = await ref.watch(myRestaurantsProvider.future);
  if (all.length < 2) return null;
  return (await ref.watch(myRestaurantProvider.future))?.id;
});

/// Someone on an outlet's team.
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.since,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final DateTime? since;

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    userId: j['user_id'] as String,
    name: (j['full_name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    role: j['role'] as String,
    since: j['created_at'] == null
        ? null
        : DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

enum TeamFailure {
  userNotFound,
  otherRole,
  alreadyMember,
  lastOwner,
  notAllowed,
  network,
}

class TeamError implements Exception {
  const TeamError(this.failure);
  final TeamFailure failure;
  @override
  String toString() => 'TeamError($failure)';
}

final teamProvider = FutureProvider.family<List<TeamMember>, String>(
  (ref, restaurantId) => ref.watch(ownerRepositoryProvider).team(restaurantId),
);

final myItemsProvider = FutureProvider.family<List<MenuItem>, String>(
  (ref, restaurantId) => ref.watch(ownerRepositoryProvider).items(restaurantId),
);
