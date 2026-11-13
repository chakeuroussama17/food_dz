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

  /// Tax on the food after discount (0.01 = 1 %).
  Future<double> taxRate();

  /// Current price and availability of these dishes (cart refresh).
  /// Dishes that no longer exist or are hidden are missing from the result.
  Future<List<MenuItem>> itemsByIds(List<String> ids);
}

// Explicit columns: the anon/authenticated roles only have SELECT on these
// (no owner, email, commission), so `select('*')` would be refused.
const _restaurantCols =
    'id, slug, name, description, area, lat, lng, cover_url, logo_url, '
    'prep_minutes, is_open';
const _baseItemCols =
    'id, restaurant_id, category_id, name, description, price, photo_url, '
    'is_available, sort_order';
const _optionCols =
    'menu_item_groups(sort_order, option_groups(id, name, min_select, '
    'max_select, option_choices(id, name, price, is_available, sort_order)))';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._db);
  final SupabaseClient _db;

  /// False once the database answered that it has no dish options yet
  /// (SQL not applied): the menu then loads without them.
  bool _options = true;

  String get _itemCols =>
      _options ? '$_baseItemCols, $_optionCols' : _baseItemCols;

  Future<T> _withOptions<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException {
      if (!_options) rethrow;
      _options = false;
      return run();
    }
  }

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
    // Open now = switch on AND within the opening hours.
    var restaurant = RestaurantSummary.fromJson(r);
    try {
      final st =
          await _db.rpc('restaurant_status', params: {'p_id': r['id']}) as List;
      if (st.isNotEmpty) {
        final s = st.first as Map<String, dynamic>;
        restaurant = restaurant.withStatus(
          open: (s['open_now'] as bool?) ?? false,
          nextOpenAt: s['next_open_at'] == null
              ? null
              : DateTime.parse(s['next_open_at'] as String).toLocal(),
          ratingAvg: (s['rating_avg'] as num?)?.toDouble(),
          ratingCount: (s['rating_count'] as num?)?.toInt(),
        );
      }
    } on PostgrestException {
      // Database without opening hours yet: the switch decides.
    }
    final items = await _withOptions(
      () => _db
          .from('menu_items')
          .select(_itemCols)
          .eq('restaurant_id', r['id'] as String)
          .order('sort_order'),
    );
    return RestaurantDetail(
      restaurant: restaurant,
      items: items.map(MenuItem.fromJson).toList(),
    );
  }

  @override
  Future<List<MenuItem>> itemsInCategory(String categoryId) async {
    final rows = await _withOptions(
      () => _db
          .from('menu_items')
          .select('$_itemCols, restaurants(name, slug)')
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('sort_order')
          .limit(40),
    );
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
    final rows = await _withOptions(
      () => _db.from('menu_items').select(_itemCols).inFilter('id', ids),
    );
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

  @override
  Future<double> taxRate() async {
    try {
      final row = await _db.from('app_config').select('tax_rate').maybeSingle();
      return (row?['tax_rate'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      // Before the checkout SQL is applied: no tax column yet.
      return 0;
    }
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

final taxRateProvider = FutureProvider<double>(
  (ref) => ref.watch(catalogRepositoryProvider).taxRate(),
);

final deliveryFeeProvider = FutureProvider<int>(
  (ref) => ref.watch(catalogRepositoryProvider).deliveryFee(),
);
