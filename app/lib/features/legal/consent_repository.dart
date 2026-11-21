import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/session/session_tracker.dart' show appPlatform;
import '../auth/data/auth_providers.dart';
import 'legal_texts.dart';

abstract interface class ConsentRepository {
  /// Documents accepted in [version]; null when it can't be read (the app
  /// then doesn't block anyone).
  Future<Set<String>?> accepted(String version);
  Future<void> accept(List<String> documents, String version);
}

class SupabaseConsentRepository implements ConsentRepository {
  SupabaseConsentRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<Set<String>?> accepted(String version) async {
    try {
      final rows = await _db.rpc('my_consents') as List;
      return {
        for (final r in rows.cast<Map<String, dynamic>>())
          if (r['version'] == version) r['document'] as String,
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> accept(List<String> documents, String version) => _db.rpc(
    'accept_documents',
    params: {
      'p_documents': documents,
      'p_version': version,
      'p_platform': appPlatform(),
    },
  );
}

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseConsentRepository(Supabase.instance.client);
});

/// What the signed-in person accepted in the current version.
final myConsentsProvider = FutureProvider<Set<String>?>((ref) async {
  final uid = ref.watch(currentUserIdProvider).value;
  if (uid == null) return null;
  return ref.watch(consentRepositoryProvider).accepted(kLegalVersion);
});
