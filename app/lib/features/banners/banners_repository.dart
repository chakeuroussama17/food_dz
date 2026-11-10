import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/utils/pick_image.dart';

/// Recommended banner shape: 1200 × 500 (2.4 : 1).
const bannerAspectRatio = 2.4;

/// A banner on the customer home.
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.restaurantSlug,
  });

  final String id;
  final String imageUrl;
  final String title;

  /// Opens this restaurant when tapped (null = just a picture).
  final String? restaurantSlug;

  factory HomeBanner.fromJson(Map<String, dynamic> j) => HomeBanner(
    id: j['id'] as String,
    imageUrl: j['image_url'] as String,
    title: (j['title'] as String?) ?? '',
    restaurantSlug: j['restaurant_slug'] as String?,
  );
}

/// A banner in the admin list (active or not).
class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.imageUrl,
    required this.isActive,
    this.title = '',
    this.restaurantId,
    this.restaurantName,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String? restaurantId;
  final String? restaurantName;
  final bool isActive;

  factory AdminBanner.fromJson(Map<String, dynamic> j) => AdminBanner(
    id: j['id'] as String,
    imageUrl: j['image_url'] as String,
    title: (j['title'] as String?) ?? '',
    restaurantId: j['restaurant_id'] as String?,
    restaurantName: j['restaurant_name'] as String?,
    isActive: j['is_active'] as bool,
  );
}

abstract interface class BannersRepository {
  Future<List<HomeBanner>> homeBanners();

  Future<List<AdminBanner>> adminList();
  Future<void> add(PickedImage image, {String title, String? restaurantId});
  Future<void> update(
    String id, {
    required String title,
    required String? restaurantId,
    required bool isActive,
  });

  /// -1 = one place up, +1 = one place down.
  Future<void> move(String id, int delta);
  Future<void> delete(String id);
}

class SupabaseBannersRepository implements BannersRepository {
  SupabaseBannersRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<HomeBanner>> homeBanners() async {
    final rows = await _db.rpc('home_banners') as List;
    return [
      for (final r in rows) HomeBanner.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<AdminBanner>> adminList() async {
    final rows = await _db.rpc('admin_list_banners') as List;
    return [
      for (final r in rows) AdminBanner.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> add(
    PickedImage image, {
    String title = '',
    String? restaurantId,
  }) async {
    final ext = image.extension;
    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _db.storage.from('banners');
    await bucket.uploadBinary(
      path,
      Uint8List.fromList(image.bytes),
      fileOptions: FileOptions(
        contentType: ext == 'png'
            ? 'image/png'
            : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg',
      ),
    );
    await _db.rpc(
      'admin_add_banner',
      params: {
        'p_image_url': bucket.getPublicUrl(path),
        'p_title': title,
        'p_restaurant_id': restaurantId,
      },
    );
  }

  @override
  Future<void> update(
    String id, {
    required String title,
    required String? restaurantId,
    required bool isActive,
  }) => _db.rpc(
    'admin_update_banner',
    params: {
      'p_id': id,
      'p_title': title,
      'p_restaurant_id': restaurantId,
      'p_is_active': isActive,
    },
  );

  @override
  Future<void> move(String id, int delta) =>
      _db.rpc('admin_move_banner', params: {'p_id': id, 'p_delta': delta});

  @override
  Future<void> delete(String id) async {
    final url = await _db.rpc('admin_delete_banner', params: {'p_id': id});
    // Remove the picture too (best effort).
    final marker = '/banners/';
    final s = url is String ? url : '';
    final i = s.lastIndexOf(marker);
    if (i >= 0) {
      try {
        await _db.storage.from('banners').remove([
          s.substring(i + marker.length),
        ]);
      } catch (_) {}
    }
  }
}

final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseBannersRepository(Supabase.instance.client);
});

final homeBannersProvider = FutureProvider<List<HomeBanner>>(
  (ref) => ref.watch(bannersRepositoryProvider).homeBanners(),
);

final adminBannersProvider = FutureProvider<List<AdminBanner>>(
  (ref) => ref.watch(bannersRepositoryProvider).adminList(),
);
