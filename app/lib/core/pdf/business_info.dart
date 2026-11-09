import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/data/admin_models.dart' show AdminConfig;
import '../config/env.dart';

export '../../features/admin/data/admin_models.dart' show AdminConfig;

/// The business details printed on receipts (name, phone, address, tax id),
/// set by the admin in Settings.
abstract interface class BusinessInfoRepository {
  Future<AdminConfig> get();
}

class SupabaseBusinessInfoRepository implements BusinessInfoRepository {
  SupabaseBusinessInfoRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<AdminConfig> get() async => AdminConfig.fromJson(
    Map<String, dynamic>.from(await _db.rpc('business_info') as Map),
  );
}

final businessInfoRepositoryProvider = Provider<BusinessInfoRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseBusinessInfoRepository(Supabase.instance.client);
});
