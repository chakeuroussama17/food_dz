import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import 'catalog_models.dart';

/// Read-only access to the public catalogue.
abstract interface class CatalogRepository {
  Future<List<FoodCategory>> categories();
  Future<List<RestaurantSummary>> restaurants({String? categorySlug});

  /// Null when the slug doesn't exist or the restaurant is inactive.
  Future<RestaurantDetail?> restaurant(String slug);

  /// Dishes of one category across all restaurants.
  Future<List<MenuItem>> itemsInCategory(String categoryId);
  Future<List<SearchHit>> search(String query);
  Future<int> deliveryFee();

  /// Current price and availability of these dishes (cart refresh).
  /// Dishes that no longer exist or are hidden are missing from the result.
  Future<List<MenuItem>> itemsByIds(List<String> ids);
}

// Explicit columns: the anon/authenticated roles only have SELECT on these
// (no owner, email, commission), so `select('*')` would be refused.
const _restaurantCols =
    'id, slug, name, description, area, lat, lng, cover_url, logo_url, '
    'prep_minutes, is_open';
const _itemCols =
    'id, restaurant_id, category_id, name, description, price, photo_url, '
    'is_available, sort_order';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<FoodCategory>> categories() async {
    final rows = await _db
        .from('categories')
        .select('id, slug, name_ar, name_fr, name_en, image_url')
        .order('sort_order');
    return rows.map(FoodCategory.fromJson).toList();
  }

  @override
  Future<List<RestaurantSummary>> restaurants({String? categorySlug}) async {
    final rows = await _db.rpc(
      'list_restaurants',
      params: {'p_category_slug': categorySlug},
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(RestaurantSummary.fromJson)
        .toList();
  }

  @override
  Future<RestaurantDetail?> restaurant(String slug) async {
    final r = await _db
        .from('restaurants')
        .select(_restaurantCols)
        .eq('slug', slug)
        .maybeSingle();
    if (r == null) return null;
    final items = await _db
        .from('menu_items')
        .select(_itemCols)
        .eq('restaurant_id', r['id'] as String)
        .order('sort_order');
    return RestaurantDetail(
      restaurant: RestaurantSummary.fromJson(r),
      items: items.map(MenuItem.fromJson).toList(),
    );
  }

  @override
  Future<List<MenuItem>> itemsInCategory(String categoryId) async {
    final rows = await _db
        .from('menu_items')
        .select('$_itemCols, restaurants(name, slug)')
        .eq('category_id', categoryId)
        .eq('is_available', true)
        .order('sort_order')
        .limit(40);
    return rows.map(MenuItem.fromJson).toList();
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final rows = await _db.rpc('search_catalog', params: {'p_query': q});
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(SearchHit.fromJson)
        .toList();
  }

  @override
  Future<List<MenuItem>> itemsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _db
        .from('menu_items')
        .select(_itemCols)
        .inFilter('id', ids);
    return rows.map(MenuItem.fromJson).toList();
  }

  @override
  Future<int> deliveryFee() async {
    final row = await _db
        .from('app_config')
        .select('delivery_fee')
        .maybeSingle();
    return (row?['delivery_fee'] as num?)?.toInt() ?? 200;
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseCatalogRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<FoodCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

final restaurantsProvider =
    FutureProvider.family<List<RestaurantSummary>, String?>(
      (ref, categorySlug) => ref
          .watch(catalogRepositoryProvider)
          .restaurants(categorySlug: categorySlug),
    );

final restaurantDetailProvider =
    FutureProvider.family<RestaurantDetail?, String>(
      (ref, slug) => ref.watch(catalogRepositoryProvider).restaurant(slug),
    );

final categoryItemsProvider = FutureProvider.family<List<MenuItem>, String>(
  (ref, categoryId) =>
      ref.watch(catalogRepositoryProvider).itemsInCategory(categoryId),
);

final deliveryFeeProvider = FutureProvider<int>(
  (ref) => ref.watch(catalogRepositoryProvider).deliveryFee(),
);
