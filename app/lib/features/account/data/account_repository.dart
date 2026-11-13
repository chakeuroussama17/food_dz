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
    this.birthDate,
    this.gender,
    this.wilaya,
    this.commune,
    this.referral,
    this.promptAnswered = true,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? birthDate;

  /// 'male' or 'female'.
  final String? gender;

  /// 1–58.
  final int? wilaya;
  final String? commune;

  /// friend, social, search, restaurant, ad, other.
  final String? referral;

  /// The "complete your profile" card was answered or skipped.
  final bool promptAnswered;

  Profile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    ProfileDetails? details,
    bool? promptAnswered,
  }) => Profile(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    birthDate: details?.birthDate ?? birthDate,
    gender: details?.gender ?? gender,
    wilaya: details?.wilaya ?? wilaya,
    commune: details?.commune ?? commune,
    referral: details?.referral ?? referral,
    promptAnswered: promptAnswered ?? this.promptAnswered,
  );
}

/// The extra details (null = unchanged).
class ProfileDetails {
  const ProfileDetails({
    this.birthDate,
    this.gender,
    this.wilaya,
    this.commune,
    this.referral,
  });
  final DateTime? birthDate;
  final String? gender;
  final int? wilaya;
  final String? commune;
  final String? referral;
}

enum DetailsFailure { invalidBirthDate, invalid, network }

class DetailsError implements Exception {
  const DetailsError(this.failure);
  final DetailsFailure failure;
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

  /// Birth date, gender, wilaya, commune, how they heard about us.
  /// [complete]: the "complete your profile" card was answered.
  /// Throws [DetailsError].
  Future<void> updateDetails(ProfileDetails d, {bool complete = false});

  /// "Later" on the "complete your profile" card.
  Future<void> skipProfilePrompt();

  /// Uploads a profile photo and stores its public URL. Returns the URL.
  Future<String> uploadAvatar(Uint8List bytes, String extension);

  Future<List<Address>> addresses();
  Future<Address> addAddress(AddressInput input, {bool makeDefault = false});
  Future<void> updateAddress(String id, AddressInput input);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);

  /// Deletes the customer's account (photos, addresses, push tokens).
  /// Throws [DeleteAccountError].
  Future<void> deleteMyAccount();
}

enum DeleteAccountFailure { activeOrders, notCustomer, network }

class DeleteAccountError implements Exception {
  const DeleteAccountError(this.failure);
  final DeleteAccountFailure failure;
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
    Map<String, dynamic> row;
    try {
      row = await _db
          .from('profiles')
          .select(
            'id, full_name, phone, avatar_url, birth_date, gender, wilaya, '
            'commune, referral_source, profile_prompt_at',
          )
          .eq('id', u.id)
          .single();
    } on PostgrestException {
      // Before the customer-data SQL is applied.
      row = await _db
          .from('profiles')
          .select('id, full_name, phone, avatar_url')
          .eq('id', u.id)
          .single();
      row['profile_prompt_at'] = 'n/a';
    }
    final birth = row['birth_date'] as String?;
    return Profile(
      id: u.id,
      email: u.email ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      phone: row['phone'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      birthDate: birth == null ? null : DateTime.tryParse(birth),
      gender: row['gender'] as String?,
      wilaya: (row['wilaya'] as num?)?.toInt(),
      commune: row['commune'] as String?,
      referral: row['referral_source'] as String?,
      promptAnswered: row['profile_prompt_at'] != null,
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
  Future<void> updateDetails(ProfileDetails d, {bool complete = false}) async {
    String? date(DateTime? t) => t == null
        ? null
        : '${t.year.toString().padLeft(4, '0')}-'
              '${t.month.toString().padLeft(2, '0')}-'
              '${t.day.toString().padLeft(2, '0')}';
    try {
      await _db.rpc(
        'update_my_details',
        params: {
          'p_birth_date': date(d.birthDate),
          'p_gender': d.gender,
          'p_wilaya': d.wilaya,
          'p_commune': d.commune,
          'p_referral': d.referral,
          'p_complete': complete,
        },
      );
    } on PostgrestException catch (e) {
      throw DetailsError(
        e.message.contains('invalid_birth_date')
            ? DetailsFailure.invalidBirthDate
            : DetailsFailure.invalid,
      );
    } catch (_) {
      throw const DetailsError(DetailsFailure.network);
    }
  }

  @override
  Future<void> skipProfilePrompt() async {
    try {
      await _db.rpc('skip_profile_prompt');
    } catch (_) {}
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
      fileOptions: FileOptions(contentType: contentType),
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

  @override
  Future<void> deleteMyAccount() async {
    final uid = _user.id;
    try {
      // Profile photos first (files can't be removed from SQL).
      try {
        final bucket = _db.storage.from('avatars');
        final files = await bucket.list(path: uid);
        if (files.isNotEmpty) {
          await bucket.remove([for (final f in files) '$uid/${f.name}']);
        }
      } catch (_) {}
      await _db.rpc('delete_my_account');
    } on PostgrestException catch (e) {
      throw DeleteAccountError(
        e.message.contains('active_orders')
            ? DeleteAccountFailure.activeOrders
            : DeleteAccountFailure.notCustomer,
      );
    } catch (_) {
      throw const DeleteAccountError(DeleteAccountFailure.network);
    }
  }
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
