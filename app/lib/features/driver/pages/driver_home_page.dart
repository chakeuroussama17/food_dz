import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../data/driver_live.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';

/// Driver home: online switch, current delivery, available orders.
class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  bool _switching = false;
  String? _claiming;

  Future<void> _setOnline(bool online) async {
    final l = AppLocalizations.of(context);
    setState(() => _switching = true);
    try {
      await ref.read(driverRepositoryProvider).setOnline(online);
      // A tap is the moment browsers allow sound.
      if (online) await ref.read(driverLiveProvider.notifier).enableSound();
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    } finally {
      ref.invalidate(myDriverProvider);
      ref.invalidate(availableOrdersProvider);
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _claim(AvailableOrder o) async {
    final l = AppLocalizations.of(context);
    setState(() => _claiming = o.id);
    try {
      await ref.read(driverRepositoryProvider).claim(o.id);
      ref.invalidate(driverActiveOrdersProvider);
      if (!mounted) return;
      showAppSnack(context, l.orderTaken);
      context.push('/driver/orders/${o.id}');
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    } finally {
      ref.invalidate(availableOrdersProvider);
      if (mounted) setState(() => _claiming = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final me = ref.watch(myDriverProvider);
    final live = ref.watch(driverLiveProvider);
    final active = ref.watch(driverActiveOrdersProvider).value ?? const [];
    final history = ref.watch(driverHistoryProvider).value ?? const [];
    final cash = ref.watch(driverCashPendingProvider).value ?? const [];
    final blocked = cash.any((c) => c.overdue);

    final now = DateTime.now();
    final today = history.where(
      (o) =>
          o.status == 'delivered' &&
          o.deliveredAt != null &&
          DateUtils.isSameDay(o.deliveredAt, now),
    );
    final todayFees = today.fold(0, (s, o) => s + o.deliveryFee);

    return DriverScaffold(
      tab: DriverTab.home,
      body: me.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(myDriverProvider),
            child: Text(l.retry),
          ),
        ),
        data: (d) {
          if (d == null) return const SizedBox.shrink();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(myDriverProvider);
              ref.invalidate(availableOrdersProvider);
              ref.invalidate(driverActiveOrdersProvider);
              ref.invalidate(driverHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        vehicleIcon(d.vehicle),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.hello(
                              d.fullName.isEmpty
                                  ? l.driverSection
                                  : d.fullName.split(' ').first,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            l.todaySummary(
                              today.length,
                              formatDzd(todayFees, lang),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!d.isApproved)
                  DriverCard(
                    color: AppColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.driverPendingTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.driverPendingBody,
                                style: TextStyle(color: AppColors.body),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!d.isApproved) const SizedBox(height: 12),
                DriverCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 14,
                        color: d.isOnline ? AppColors.success : AppColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.isOnline ? l.onlineLabel : l.offlineLabel,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              d.isOnline ? l.youAreOnline : l.youAreOffline,
                              style: TextStyle(color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: d.isOnline,
                        activeTrackColor: AppColors.success,
                        onChanged: !d.isApproved || _switching
                            ? null
                            : _setOnline,
                      ),
                    ],
                  ),
                ),
                if (blocked) ...[
                  const SizedBox(height: 12),
                  DriverCard(
                    color: AppColors.dangerSoft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.block_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.cashBlockedTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.errCashOverdue,
                                style: TextStyle(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (cash.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(l.moneyToHand),
                  _CashList(items: cash),
                ],
                if (d.isOnline && !live.soundReady) ...[
                  const SizedBox(height: 12),
                  SoundBanner(
                    text: l.enableSoundAlerts,
                    onTap: () =>
                        ref.read(driverLiveProvider.notifier).enableSound(),
                  ),
                ],
                if (active.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(l.currentDelivery),
                  for (final o in active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CurrentCard(order: o),
                    ),
                ] else if (d.isOnline) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(l.availableOrders),
                  _AvailableList(claiming: _claiming, onClaim: _claim),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Food money to give to restaurants, one row per order.
class _CashList extends ConsumerStatefulWidget {
  const _CashList({required this.items});
  final List<CashDue> items;

  @override
  ConsumerState<_CashList> createState() => _CashListState();
}

class _CashListState extends ConsumerState<_CashList> {
  String? _busy;

  Future<void> _handed(CashDue c) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = c.orderId);
    try {
      await ref.read(driverRepositoryProvider).markCashHanded(c.orderId);
      if (mounted) showAppSnack(context, l.cashHandedMsg);
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    } finally {
      ref.invalidate(driverCashPendingProvider);
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final total = widget.items.fold(0, (s, c) => s + c.amount);
    final when = DateFormat('dd/MM HH:mm');
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.moneyToHandTotal(formatDzd(total, lang)),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          for (final c in widget.items) ...[
            Divider(color: AppColors.border, height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.restaurantName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '#${c.code} · ${l.deliveredOnTime(when.format(c.deliveredAt))}',
                        style: TextStyle(
                          color: c.overdue ? AppColors.danger : AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDzd(c.amount, lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: c.handedAt == null
                  ? AppButton(
                      label: l.iGaveMoney,
                      variant: AppButtonVariant.small,
                      loading: _busy == c.orderId,
                      onPressed: _busy == null ? () => _handed(c) : null,
                    )
                  : Pill(l.waitingRestaurantConfirm, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
  );
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.order});
  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    return DriverCard(
      onTap: () => context.push('/driver/orders/${o.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${o.code}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Pill(
                orderStatusLabel(l, o.status),
                color: orderStatusColor(o.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Route(
            from: o.restaurantName,
            fromSub: o.restaurantArea.isEmpty
                ? o.restaurantAddress
                : o.restaurantArea,
            to: o.customerName,
            toSub: o.area.isEmpty ? o.addressText : o.area,
          ),
          const SizedBox(height: 10),
          AmountLine(label: l.cashToCollect, value: formatDzd(o.total, lang)),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: l.trackOrder,
              variant: AppButtonVariant.small,
              onPressed: () => context.push('/driver/orders/${o.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Restaurant → customer, two lines each.
class _Route extends StatelessWidget {
  const _Route({
    required this.from,
    required this.fromSub,
    required this.to,
    required this.toSub,
  });
  final String from;
  final String fromSub;
  final String to;
  final String toSub;

  @override
  Widget build(BuildContext context) {
    Widget stop(IconData icon, Color c, String a, String b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (b.isNotEmpty)
                Text(b, style: TextStyle(color: AppColors.body)),
            ],
          ),
        ),
      ],
    );
    return Column(
      children: [
        stop(Icons.storefront_rounded, AppColors.primary, from, fromSub),
        const SizedBox(height: 8),
        stop(Icons.location_on_rounded, AppColors.danger, to, toSub),
      ],
    );
  }
}

class _AvailableList extends ConsumerWidget {
  const _AvailableList({required this.claiming, required this.onClaim});
  final String? claiming;
  final ValueChanged<AvailableOrder> onClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(availableOrdersProvider);
    return list.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Text(l.loadError),
      data: (orders) {
        if (orders.isEmpty) {
          return DriverCard(
            child: Row(
              children: [
                Icon(Icons.hourglass_empty_rounded, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.noAvailableOrders,
                    style: TextStyle(color: AppColors.body),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final o in orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DriverCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${o.code}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(o.placedAt),
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const Spacer(),
                          Pill(
                            o.isReady ? l.statusReady : l.statusAccepted,
                            color: o.isReady
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Route(
                        from: o.restaurantName,
                        fromSub: o.restaurantArea.isEmpty
                            ? o.restaurantAddress
                            : o.restaurantArea,
                        to: o.area.isEmpty ? '—' : o.area,
                        toSub: _distance(l, o),
                      ),
                      const SizedBox(height: 10),
                      AmountLine(
                        label: l.yourFee,
                        value: formatDzd(o.deliveryFee, lang),
                        color: AppColors.success,
                        big: true,
                      ),
                      AmountLine(
                        label: l.cashToCollect,
                        value: formatDzd(o.total, lang),
                      ),
                      Text(
                        l.itemCount(o.itemCount),
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l.takeOrder,
                        loading: claiming == o.id,
                        onPressed: claiming == null ? () => onClaim(o) : null,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Restaurant → customer distance when both points are known.
  String _distance(AppLocalizations l, AvailableOrder o) {
    if (o.restaurantLat == null ||
        o.restaurantLng == null ||
        o.lat == null ||
        o.lng == null) {
      return '';
    }
    final km = distanceKm(o.restaurantLat!, o.restaurantLng!, o.lat!, o.lng!);
    return l.kmAway(formatKm(km));
  }
}
