/// Plain data classes for the public catalogue (mirrors the SQL schema).
library;

class FoodCategory {
  const FoodCategory({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameFr,
    required this.nameEn,
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String nameAr;
  final String nameFr;
  final String nameEn;
  final String? imageUrl;

  String name(String languageCode) => switch (languageCode) {
    'ar' => nameAr,
    'fr' => nameFr,
    _ => nameEn,
  };

  factory FoodCategory.fromJson(Map<String, dynamic> j) => FoodCategory(
    id: j['id'] as String,
    slug: j['slug'] as String,
    nameAr: j['name_ar'] as String,
    nameFr: j['name_fr'] as String,
    nameEn: j['name_en'] as String,
    imageUrl: j['image_url'] as String?,
  );
}

/// Row of `list_restaurants()`: what a restaurant card needs.
class RestaurantSummary {
  const RestaurantSummary({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.area = '',
    this.lat,
    this.lng,
    this.coverUrl,
    this.logoUrl,
    this.prepMinutes = 20,
    this.isOpen = false,
    this.categorySlugs = const [],
    this.minPrice,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final String area;
  final double? lat;
  final double? lng;
  final String? coverUrl;
  final String? logoUrl;
  final int prepMinutes;
  final bool isOpen;
  final List<String> categorySlugs;
  final int? minPrice;

  factory RestaurantSummary.fromJson(Map<String, dynamic> j) =>
      RestaurantSummary(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        area: (j['area'] as String?) ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        coverUrl: j['cover_url'] as String?,
        logoUrl: j['logo_url'] as String?,
        prepMinutes: (j['prep_minutes'] as num?)?.toInt() ?? 20,
        isOpen: (j['is_open'] as bool?) ?? false,
        categorySlugs: ((j['category_slugs'] as List?) ?? const [])
            .cast<String>(),
        minPrice: (j['min_price'] as num?)?.toInt(),
      );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.categoryId,
    this.description = '',
    this.photoUrl,
    this.isAvailable = true,
    this.restaurantName,
    this.restaurantSlug,
  });

  final String id;
  final String restaurantId;
  final String? categoryId;
  final String name;
  final String description;

  /// Whole DZD.
  final int price;
  final String? photoUrl;
  final bool isAvailable;

  /// Filled when items come from a cross-restaurant query.
  final String? restaurantName;
  final String? restaurantSlug;

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    final r = j['restaurants'] as Map<String, dynamic>?;
    return MenuItem(
      id: j['id'] as String,
      restaurantId: j['restaurant_id'] as String,
      categoryId: j['category_id'] as String?,
      name: j['name'] as String,
      description: (j['description'] as String?) ?? '',
      price: (j['price'] as num).toInt(),
      photoUrl: j['photo_url'] as String?,
      isAvailable: (j['is_available'] as bool?) ?? true,
      restaurantName: r?['name'] as String?,
      restaurantSlug: r?['slug'] as String?,
    );
  }

  /// Same shape as [MenuItem.fromJson] reads (used to save the cart).
  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'photo_url': photoUrl,
    'is_available': isAvailable,
    if (restaurantName != null || restaurantSlug != null)
      'restaurants': {'name': restaurantName, 'slug': restaurantSlug},
  };
}

/// A restaurant page: details + full menu.
class RestaurantDetail {
  const RestaurantDetail({required this.restaurant, required this.items});
  final RestaurantSummary restaurant;
  final List<MenuItem> items;
}

/// Row of `search_catalog()`.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.restaurantSlug,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.price,
  });

  /// 'restaurant' or 'item'.
  final String kind;
  final String id;
  final String restaurantSlug;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int? price;

  bool get isRestaurant => kind == 'restaurant';

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
    kind: j['kind'] as String,
    id: j['id'] as String,
    restaurantSlug: j['restaurant_slug'] as String,
    title: j['title'] as String,
    subtitle: (j['subtitle'] as String?) ?? '',
    imageUrl: j['image_url'] as String?,
    price: (j['price'] as num?)?.toInt(),
  );
}
