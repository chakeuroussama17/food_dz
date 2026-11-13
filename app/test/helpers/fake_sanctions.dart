import 'package:food_app/features/sanctions/sanctions_repository.dart';

/// In-memory sanctions with the same rules as the database.
class FakeSanctionsRepository implements SanctionsRepository {
  /// What the signed-in person sees (my_restriction).
  Sanction? current;
  final acknowledged = <int>[];
  final calls = <String>[];
  final byUser = <String, List<Sanction>>{};
  List<WatchlistEntry> watch = const [];
  var _n = 0;

  @override
  Future<Sanction?> mine() async => current;

  @override
  Future<void> acknowledge(int id) async {
    acknowledged.add(id);
    if (current?.id == id) current = null;
  }

  @override
  Future<int> sanction({
    required String userId,
    required String kind,
    required String reason,
    String message = '',
    int? days,
    String adminNote = '',
  }) async {
    calls.add('$kind:$userId:$reason:${days ?? ''}:$message');
    final s = Sanction(
      id: ++_n,
      kind: kind,
      reason: reason,
      message: message,
      adminNote: adminNote,
      endsAt: days == null ? null : DateTime.now().add(Duration(days: days)),
      createdAt: DateTime.now(),
      createdByName: 'Admin',
      active: kind != 'warning',
    );
    byUser.putIfAbsent(userId, () => []).insert(0, s);
    return s.id;
  }

  @override
  Future<void> lift(int id) async {
    calls.add('lift:$id');
    for (final list in byUser.values) {
      for (var i = 0; i < list.length; i++) {
        final s = list[i];
        if (s.id == id) {
          list[i] = Sanction(
            id: s.id,
            kind: s.kind,
            reason: s.reason,
            message: s.message,
            endsAt: s.endsAt,
            createdAt: s.createdAt,
            liftedAt: DateTime.now(),
            createdByName: s.createdByName,
          );
        }
      }
    }
  }

  @override
  Future<List<Sanction>> history(String userId) async => [...?byUser[userId]];

  @override
  Future<List<WatchlistEntry>> watchlist() async => watch;

  @override
  Future<Map<String, String>> restrictions() async => {
    for (final e in byUser.entries)
      for (final s in e.value.where((s) => s.active).take(1)) e.key: s.kind,
  };
}
