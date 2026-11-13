import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/data/admin_models.dart' show StatementSummary;
import '../features/auth/data/auth_providers.dart';
import '../features/restaurant_owner/data/owner_orders_repository.dart';
import '../features/restaurant_owner/data/owner_repository.dart';
import '../features/ratings/ratings_repository.dart';

/// Outlets the portal works on: those where the user is a manager or an
/// owner (staff use the app).
final portalOutletsProvider = FutureProvider<List<OwnedRestaurant>>((
  ref,
) async {
  final all = await ref.watch(myRestaurantsProvider.future);
  return all.where((r) => r.canManage).toList();
});

/// The outlets ticked in the top-right selector; null = all of them.
class PortalSelection extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  void set(Set<String>? ids) => state = ids;
}

final portalSelectionProvider = NotifierProvider<PortalSelection, Set<String>?>(
  PortalSelection.new,
);

/// Ids of the selected outlets (all when none is ticked).
final portalOutletIdsProvider = FutureProvider<List<String>>((ref) async {
  final all = await ref.watch(portalOutletsProvider.future);
  final sel = ref.watch(portalSelectionProvider);
  final ids = [
    for (final r in all)
      if (sel == null || sel.contains(r.id)) r.id,
  ];
  return ids.isEmpty ? [for (final r in all) r.id] : ids;
});

/// Reviews of the selected outlets for a period.
final portalReviewsProvider =
    FutureProvider.family<List<OwnerReview>, ReportRange>((ref, r) {
      ref.watch(currentUserIdProvider);
      return ref
          .watch(ratingsRepositoryProvider)
          .ownerReviews(restaurantIds: r.outlets, from: r.from, to: r.to);
    });

/// The report of the selected outlets for [from, to).
Future<List<OwnerOrder>> portalReport(
  Ref ref,
  DateTime from,
  DateTime to,
) async {
  final ids = await ref.watch(portalOutletIdsProvider.future);
  return ref.watch(
    ownerReportProvider(ReportRange(from, to, outlets: ids)).future,
  );
}

/// Orders in progress of the selected outlets.
final portalActiveOrdersProvider = FutureProvider<List<OwnerOrder>>((
  ref,
) async {
  ref.watch(currentUserIdProvider);
  ref.watch(orderChangesProvider);
  final ids = (await ref.watch(portalOutletIdsProvider.future)).toSet();
  final all = await ref.watch(ownerOrdersRepositoryProvider).activeOrders();
  return all
      .where((o) => o.restaurantId == null || ids.contains(o.restaurantId))
      .toList();
});

/// Commission statements of the selected outlets.
final portalStatementsProvider = FutureProvider<List<StatementSummary>>((
  ref,
) async {
  ref.watch(currentUserIdProvider);
  final ids = (await ref.watch(portalOutletIdsProvider.future)).toSet();
  final all = await ref.watch(ownerOrdersRepositoryProvider).statements();
  return all
      .where((s) => s.restaurantId.isEmpty || ids.contains(s.restaurantId))
      .toList();
});

/// Last refresh time, shown on the dashboard.
class PortalRefreshed extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void touch() => state = DateTime.now();
}

final portalRefreshedProvider = NotifierProvider<PortalRefreshed, DateTime>(
  PortalRefreshed.new,
);

/// Reloads the order data of every outlet.
void refreshPortal(WidgetRef ref) {
  ref.invalidate(ownerReportProvider);
  ref.invalidate(portalActiveOrdersProvider);
  ref.invalidate(portalStatementsProvider);
  ref.invalidate(myRestaurantsProvider);
  ref.read(portalRefreshedProvider.notifier).touch();
}

/// Live updates while the portal is open: any order change on one of the
/// outlets (Realtime) reloads the data, plus a refresh every minute.
final portalLiveProvider = Provider<void>((ref) {
  final outlets = ref.watch(portalOutletsProvider).value ?? const [];
  final repo = ref.watch(ownerOrdersRepositoryProvider);
  Timer? debounce;
  void changed() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(ownerReportProvider);
      ref.invalidate(portalActiveOrdersProvider);
      ref.read(portalRefreshedProvider.notifier).touch();
    });
  }

  final subs = [
    for (final r in outlets)
      repo.restaurantChanges(r.id).listen((_) => changed(), onError: (_) {}),
  ];
  final timer = Timer.periodic(const Duration(minutes: 1), (_) => changed());
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
    timer.cancel();
    debounce?.cancel();
  });
});

/// The outlet edited on single-outlet pages (menu, hours, team); null =
/// the first one. Kept while moving between those pages.
class PortalCurrentOutlet extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String id) => state = id;
}

final portalCurrentOutletProvider =
    NotifierProvider<PortalCurrentOutlet, String?>(PortalCurrentOutlet.new);

/// The outlet those pages show.
final portalOutletProvider = FutureProvider<OwnedRestaurant?>((ref) async {
  final all = await ref.watch(portalOutletsProvider.future);
  if (all.isEmpty) return null;
  final id = ref.watch(portalCurrentOutletProvider);
  return all.where((r) => r.id == id).firstOrNull ?? all.first;
});
