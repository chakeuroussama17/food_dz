import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_providers.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
}

enum AddressLabel { home, work, other }

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.addressText,
    this.area = '',
    this.details = '',
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  final String id;
  final AddressLabel label;
  final String addressText;
  final String area;
  final String details;
  final double? lat;
  final double? lng;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'] as String,
    label: AddressLabel.values.byName(j['label'] as String),
    addressText: j['address_text'] as String,
    area: (j['area'] as String?) ?? '',
    details: (j['details'] as String?) ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    isDefault: (j['is_default'] as bool?) ?? false,
  );
}

/// Data the address form sends (no id yet for new addresses).
class AddressInput {
  const AddressInput({
    required this.label,
    required this.addressText,
    this.area = '',
    this.details = '',
    this.lat,
    this.lng,
  });

  final AddressLabel label;
  final String addressText;
  final String area;
  final String details;
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
    'label': label.name,
    'address_text': addressText.trim(),
    'area': area.trim(),
    'details': details.trim(),
    'lat': lat,
    'lng': lng,
  };
}

abstract interface class AccountRepository {
  Future<Profile> myProfile();
  Future<void> updateProfile({required String fullName, String? phone});

  /// Uploads a profile photo and stores its public URL. Returns the URL.
  Future<String> uploadAvatar(Uint8List bytes, String extension);

  Future<List<Address>> addresses();
  Future<Address> addAddress(AddressInput input, {bool makeDefault = false});
  Future<void> updateAddress(String id, AddressInput input);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);
}

class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this._db);
  final SupabaseClient _db;

  User get _user {
    final u = _db.auth.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u;
  }

  @override
  Future<Profile> myProfile() async {
    final u = _user;
    final row = await _db
        .from('profiles')
        .select('id, full_name, phone, avatar_url')
        .eq('id', u.id)
        .single();
    return Profile(
      id: u.id,
      email: u.email ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      phone: row['phone'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    await _db
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': (phone == null || phone.isEmpty) ? null : phone,
        })
        .eq('id', _user.id);
    // Keep the auth metadata in sync (used for the greeting).
    await _db.auth.updateUser(
      UserAttributes(data: {'full_name': fullName.trim()}),
    );
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    // New file name each time so cached old photos don't linger.
    final path = '${_user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _db.storage.from('avatars');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    final url = bucket.getPublicUrl(path);
    await _db.from('profiles').update({'avatar_url': url}).eq('id', _user.id);
    return url;
  }

  @override
  Future<List<Address>> addresses() async {
    final rows = await _db
        .from('addresses')
        .select('id, label, address_text, area, details, lat, lng, is_default')
        .order('is_default', ascending: false)
        .order('created_at');
    return rows.map(Address.fromJson).toList();
  }

  @override
  Future<Address> addAddress(
    AddressInput input, {
    bool makeDefault = false,
  }) async {
    final row = await _db
        .from('addresses')
        .insert(input.toJson())
        .select('id, label, address_text, area, details, lat, lng, is_default')
        .single();
    final a = Address.fromJson(row);
    if (makeDefault) await setDefaultAddress(a.id);
    return a;
  }

  @override
  Future<void> updateAddress(String id, AddressInput input) =>
      _db.from('addresses').update(input.toJson()).eq('id', id);

  @override
  Future<void> deleteAddress(String id) =>
      _db.from('addresses').delete().eq('id', id);

  @override
  Future<void> setDefaultAddress(String id) =>
      _db.rpc('set_default_address', params: {'p_address_id': id});
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseAccountRepository(Supabase.instance.client);
});

/// Re-fetched whenever the signed-in user changes.
final profileProvider = FutureProvider<Profile>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(accountRepositoryProvider).myProfile();
});

final addressesProvider = FutureProvider<List<Address>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(accountRepositoryProvider).addresses();
});
