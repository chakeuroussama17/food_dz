import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
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
  });

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
  /// Null when the account has no restaurant.
  Future<OwnedRestaurant?> myRestaurant();

  /// Makes the signed-in account a restaurant owner (inactive until the
  /// admin approves). Returns the restaurant id.
  Future<String> register(RestaurantRegistration r);

  Future<void> updateDetails(String restaurantId, RestaurantDetailsInput input);
  Future<void> setOpen(String restaurantId, bool open);

  Future<List<MenuItem>> items(String restaurantId);
  Future<void> addItem(String restaurantId, MenuItemInput input);
  Future<void> updateItem(String itemId, MenuItemInput input);
  Future<void> setItemAvailable(String itemId, bool available);
  Future<void> deleteItem(String itemId);

  /// Uploads a photo to `restaurant-media/<restaurant id>/` and returns its URL.
  Future<String> uploadImage(
    String restaurantId,
    Uint8List bytes,
    String extension,
  );
}

const _itemCols =
    'id, restaurant_id, category_id, name, description, price, photo_url, '
    'is_available, sort_order';

class SupabaseOwnerRepository implements OwnerRepository {
  SupabaseOwnerRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<OwnedRestaurant?> myRestaurant() async {
    final rows = await _db.rpc('my_restaurant') as List;
    if (rows.isEmpty) return null;
    return OwnedRestaurant.fromJson(rows.first as Map<String, dynamic>);
  }

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
  Future<void> addItem(String restaurantId, MenuItemInput input) => _db
      .from('menu_items')
      .insert({...input.toJson(), 'restaurant_id': restaurantId});

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
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseOwnerRepository(Supabase.instance.client);
});

/// The signed-in owner's restaurant (reloads on login / logout).
final myRestaurantProvider = FutureProvider<OwnedRestaurant?>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerRepositoryProvider).myRestaurant();
});

final myItemsProvider = FutureProvider.family<List<MenuItem>, String>(
  (ref, restaurantId) => ref.watch(ownerRepositoryProvider).items(restaurantId),
);
