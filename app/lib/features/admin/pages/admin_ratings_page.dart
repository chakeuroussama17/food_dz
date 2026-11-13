import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../ratings/ratings_repository.dart';
import '../../ratings/ratings_widgets.dart';
import '../widgets/admin_widgets.dart';

final _driversProvider = FutureProvider<List<AdminDriverRating>>(
  (ref) => ref.watch(ratingsRepositoryProvider).adminDrivers(),
);
final _restaurantsProvider = FutureProvider<List<AdminRestaurantRating>>(
  (ref) => ref.watch(ratingsRepositoryProvider).adminRestaurants(),
);
final _flaggedProvider = FutureProvider<List<FlaggedReview>>(
  (ref) => ref.watch(ratingsRepositoryProvider).adminFlagged(),
);
final _reportsProvider = FutureProvider<List<CustomerReport>>(
  (ref) => ref.watch(ratingsRepositoryProvider).adminReports(),
);

enum _Tab { flagged, reports, drivers, restaurants }

/// Ratings and reports: flagged reviews (hide / keep), reports about
/// customers (warn / block / dismiss), and every driver's and restaurant's
/// average.
class AdminRatingsPage extends ConsumerStatefulWidget {
  const AdminRatingsPage({super.key});

  @override
  ConsumerState<AdminRatingsPage> createState() => _AdminRatingsPageState();
}

class _AdminRatingsPageState extends ConsumerState<AdminRatingsPage> {
  _Tab _tab = _Tab.flagged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pendingFlags =
        ref
            .watch(_flaggedProvider)
            .value
            ?.where((f) => f.flagDecision == null)
            .length ??
        0;
    final openReports =
        ref
            .watch(_reportsProvider)
            .value
            ?.where((r) => r.status == 'open')
            .length ??
        0;
    String label(_Tab t) => switch (t) {
      _Tab.flagged =>
        '${l.tabFlagged}${pendingFlags > 0 ? ' ($pendingFlags)' : ''}',
      _Tab.reports =>
        '${l.tabReports}${openReports > 0 ? ' ($openReports)' : ''}',
      _Tab.drivers => l.driversTitle,
      _Tab.restaurants => l.restaurantsTitle,
    };
    return AdminScaffold(
      section: AdminSection.ratings,
      title: l.adminRatingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final t in _Tab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label(t)),
                      selected: _tab == t,
                      selectedColor: AppColors.primarySoft,
                      onSelected: (_) => setState(() => _tab = t),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _Tab.flagged => const _Flagged(),
              _Tab.reports => const _Reports(),
              _Tab.drivers => const _Drivers(),
              _Tab.restaurants => const _Restaurants(),
            },
          ),
        ],
      ),
    );
  }
}

Widget _loading() =>
    const Center(child: CircularProgressIndicator(color: AppColors.primary));

Widget _empty(String text) => Center(
  child: Text(text, style: TextStyle(color: AppColors.muted)),
);

Widget _error(VoidCallback retry, AppLocalizations l) => Center(
  child: TextButton(
    onPressed: retry,
    child: Text('${l.loadError}\n${l.retry}', textAlign: TextAlign.center),
  ),
);

// ------------------------------------------------------------ flagged

class _Flagged extends ConsumerWidget {
  const _Flagged();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final data = ref.watch(_flaggedProvider);

    Future<void> decide(FlaggedReview f, bool hide) async {
      try {
        await ref
            .read(ratingsRepositoryProvider)
            .adminDecision(f.orderId, hide: hide);
      } catch (_) {
        if (context.mounted) showAppSnack(context, l.errGeneric, error: true);
      }
      ref.invalidate(_flaggedProvider);
      ref.invalidate(_restaurantsProvider);
    }

    return data.when(
      loading: _loading,
      error: (_, _) => _error(() => ref.invalidate(_flaggedProvider), l),
      data: (list) => list.isEmpty
          ? _empty(l.noFlagged)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final f in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${f.restaurantName} · #${f.code}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (f.flagDecision != null)
                                Pill(
                                  f.flagDecision == 'hidden'
                                      ? l.decisionHidden
                                      : l.decisionKept,
                                  color: f.flagDecision == 'hidden'
                                      ? AppColors.danger
                                      : AppColors.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Stars(f.stars.toDouble()),
                              const SizedBox(width: 8),
                              Text(
                                '${f.customerLabel} · ${date.format(f.ratedAt)}',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                          if (f.reasons.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                f.reasons
                                    .map((r) => reasonText(l, r))
                                    .join(' · '),
                                style: TextStyle(color: AppColors.body),
                              ),
                            ),
                          if (f.comment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                f.comment,
                                style: TextStyle(
                                  height: 1.4,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${l.flaggedReason}: ${f.flagReason}',
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: [
                              AppButton(
                                label: l.hideReview,
                                variant: f.hidden
                                    ? AppButtonVariant.outline
                                    : AppButtonVariant.dangerOutline,
                                onPressed: f.hidden
                                    ? null
                                    : () => decide(f, true),
                              ),
                              AppButton(
                                label: l.keepReview,
                                variant: AppButtonVariant.small,
                                onPressed: !f.hidden && f.flagDecision == 'kept'
                                    ? null
                                    : () => decide(f, false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------ reports

class _Reports extends ConsumerWidget {
  const _Reports();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final date = DateFormat('dd/MM/yyyy HH:mm');
    final data = ref.watch(_reportsProvider);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted) showAppSnack(context, l.errGeneric, error: true);
      }
      ref.invalidate(_reportsProvider);
    }

    String statusLabel(String s) => switch (s) {
      'warned' => l.reportWarned,
      'blocked' => l.reportBlocked,
      'dismissed' => l.reportDismissed,
      _ => l.reportOpen,
    };
    Color statusColor(String s) => switch (s) {
      'warned' => AppColors.primary,
      'blocked' => AppColors.danger,
      'dismissed' => AppColors.muted,
      _ => const Color(0xFFF59E0B),
    };

    return data.when(
      loading: _loading,
      error: (_, _) => _error(() => ref.invalidate(_reportsProvider), l),
      data: (list) => list.isEmpty
          ? _empty(l.noReports)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${r.customerName} · ${r.customerPhone}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Pill(
                                statusLabel(r.status),
                                color: statusColor(r.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r.reporterRole == 'driver' ? l.reportedByDriver : l.reportedByRestaurant}'
                            ' (${r.reporterName}) · #${r.orderCode} · ${r.restaurantName}'
                            ' · ${date.format(r.createdAt)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reasonText(l, r.reason),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (r.note.isNotEmpty)
                            Text(
                              r.note,
                              style: TextStyle(color: AppColors.body),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            l.customerReportsCount(r.customerReportsTotal),
                            style: TextStyle(
                              fontSize: 13,
                              color: r.customerReportsTotal >= 3
                                  ? AppColors.danger
                                  : AppColors.muted,
                            ),
                          ),
                          if (r.customerBlocked)
                            Text(
                              l.customerBlockedNote,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (r.adminNote.isNotEmpty)
                            Text(
                              r.adminNote,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.body,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppButton(
                                label: l.actionWarn,
                                variant: AppButtonVariant.outline,
                                onPressed: () => run(
                                  () => ref
                                      .read(ratingsRepositoryProvider)
                                      .adminHandleReport(r.id, 'warned'),
                                ),
                              ),
                              if (r.customerBlocked && r.customerId != null)
                                AppButton(
                                  label: l.actionUnblock,
                                  variant: AppButtonVariant.small,
                                  onPressed: () => run(
                                    () => ref
                                        .read(ratingsRepositoryProvider)
                                        .adminSetBlocked(r.customerId!, false),
                                  ),
                                )
                              else
                                AppButton(
                                  label: l.actionBlock,
                                  variant: AppButtonVariant.dangerOutline,
                                  onPressed: r.customerId == null
                                      ? null
                                      : () => run(
                                          () => ref
                                              .read(ratingsRepositoryProvider)
                                              .adminHandleReport(
                                                r.id,
                                                'blocked',
                                              ),
                                        ),
                                ),
                              AppButton(
                                label: l.actionDismiss,
                                variant: AppButtonVariant.outline,
                                onPressed: r.status == 'dismissed'
                                    ? null
                                    : () => run(
                                        () => ref
                                            .read(ratingsRepositoryProvider)
                                            .adminHandleReport(
                                              r.id,
                                              'dismissed',
                                            ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------ drivers / restaurants

String _avg(double? v) => v == null ? '—' : v.toStringAsFixed(1);

class _Drivers extends ConsumerWidget {
  const _Drivers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(_driversProvider);
    return data.when(
      loading: _loading,
      error: (_, _) => _error(() => ref.invalidate(_driversProvider), l),
      data: (list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final d in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name.isEmpty ? d.phone : d.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${l.ratingsCount(d.ratedCount)} · ${l.avg30d}: ${_avg(d.average30d)}'
                            ' · ${l.low30d}: ${d.low30d}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          if (d.reasons.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                (d.reasons.entries.toList()..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    ))
                                    .map(
                                      (e) =>
                                          '${reasonText(l, e.key)} ${e.value}',
                                    )
                                    .join(' · '),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.body,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (d.average != null) ...[
                      const Icon(Icons.star_rounded, color: starColor),
                      const SizedBox(width: 4),
                      Text(
                        _avg(d.average),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: (d.average ?? 5) < 3.5
                              ? AppColors.danger
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Restaurants extends ConsumerWidget {
  const _Restaurants();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(_restaurantsProvider);
    return data.when(
      loading: _loading,
      error: (_, _) => _error(() => ref.invalidate(_restaurantsProvider), l),
      data: (list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${l.ratingsCount(r.ratedCount)} · ${l.avg30d}: ${_avg(r.average30d)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.flaggedPending > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Pill(
                          '${l.tabFlagged}: ${r.flaggedPending}',
                          color: AppColors.primary,
                        ),
                      ),
                    if (r.average != null) ...[
                      const Icon(Icons.star_rounded, color: starColor),
                      const SizedBox(width: 4),
                      Text(
                        _avg(r.average),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
