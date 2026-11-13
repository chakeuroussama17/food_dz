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
import '../../account/data/account_repository.dart';
import '../../orders/order_status.dart';
import '../data/driver_live.dart';
import '../data/driver_position.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';
import '../widgets/rider_ui.dart';

/// Rider home. Offline: "Ready to ride?" with the big start button.
/// Online: a map of the jobs around, then the list to take one. With a
/// delivery running: the card to continue it.
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
    final me = ref.watch(myDriverProvider);
    final live = ref.watch(driverLiveProvider);
    final active = ref.watch(driverActiveOrdersProvider).value ?? const [];
    final history = ref.watch(driverHistoryProvider).value ?? const [];
    final cash = ref.watch(driverCashPendingProvider).value ?? const [];
    final blocked = cash.any((c) => c.overdue);

    final now = DateTime.now();
    final today = history
        .where(
          (o) =>
              o.status == 'delivered' &&
              o.deliveredAt != null &&
              DateUtils.isSameDay(o.deliveredAt, now),
        )
        .toList();

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
          final firstName = d.fullName.isEmpty
              ? l.driverSection
              : d.fullName.split(' ').first;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(myDriverProvider);
              ref.invalidate(availableOrdersProvider);
              ref.invalidate(driverActiveOrdersProvider);
              ref.invalidate(driverHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Header(
                  name: firstName,
                  icon: vehicleIcon(d.vehicle),
                  online: d.isOnline,
                ),
                const SizedBox(height: 20),
                if (!d.isApproved) ...[
                  _Notice(
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.primary,
                    title: l.driverPendingTitle,
                    body: l.driverPendingBody,
                  ),
                  const SizedBox(height: 16),
                ],
                if (blocked) ...[
                  _Notice(
                    icon: Icons.block_rounded,
                    color: AppColors.danger,
                    title: l.cashBlockedTitle,
                    body: l.errCashOverdue,
                  ),
                  const SizedBox(height: 16),
                ],
                if (cash.isNotEmpty) ...[
                  _Title(l.moneyToHand),
                  _CashList(items: cash),
                  const SizedBox(height: 24),
                ],
                if (active.isNotEmpty) ...[
                  _Title(l.currentDelivery),
                  for (final o in active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CurrentCard(order: o),
                    ),
                ] else if (!d.isOnline) ...[
                  Text(
                    l.riderReadyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.riderReadySub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RiderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.riderModeTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.riderModeBody,
                          style: TextStyle(
                            color: AppColors.body,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 240),
                            child: RiderButton(
                              label: l.startRiding,
                              icon: vehicleIcon(d.vehicle),
                              loading: _switching,
                              onPressed: d.isApproved
                                  ? () => _setOnline(true)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (!live.soundReady) ...[
                    SoundBanner(
                      text: l.enableSoundAlerts,
                      onTap: () =>
                          ref.read(driverLiveProvider.notifier).enableSound(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Title(l.jobsNearYou),
                  const _JobsMap(),
                  const SizedBox(height: 20),
                  _Title(l.availableOrders),
                  _AvailableList(claiming: _claiming, onClaim: _claim),
                ],
                const SizedBox(height: 4),
                _TodayCard(
                  count: today.length,
                  fees: today.fold(0, (s, o) => s + o.deliveryFee),
                ),
                if (d.isOnline && active.isEmpty) ...[
                  const SizedBox(height: 24),
                  RiderButton(
                    label: l.doneForToday,
                    secondary: true,
                    loading: _switching,
                    onPressed: () => _setOnline(false),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Avatar, "Hello, Rachid" and the online / offline tag.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.icon, required this.online});
  final String name;
  final IconData icon;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = online ? AppColors.success : AppColors.muted;
    return Row(
      children: [
        // The rider's photo once set, else the vehicle.
        Consumer(
          builder: (context, ref, _) {
            final photo = ref.watch(profileProvider).value?.avatarUrl;
            return (photo ?? '').isEmpty
                ? CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(icon, color: AppColors.primary),
                  )
                : Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: AppImage(
                      url: photo,
                      width: 40,
                      height: 40,
                      radius: 20,
                    ),
                  );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l.hello(name),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(
                online ? l.onlineLabel : l.offlineLabel,
                style: TextStyle(
                  color: online ? AppColors.success : AppColors.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => RiderCard(
    padding: const EdgeInsets.all(16),
    color: color == AppColors.danger
        ? AppColors.dangerSoft
        : AppColors.primarySoft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: AppColors.ink)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
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

/// Today: deliveries and earnings side by side.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.count, required this.fees});
  final int count;
  final int fees;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Widget cell(IconData icon, String value, String label) => Expanded(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.body, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: l.todaySummary(count, formatDzd(fees, lang)),
      child: RiderCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            cell(Icons.check_circle_rounded, '$count', l.statDeliveries),
            const SizedBox(width: 12),
            cell(Icons.payments_rounded, formatDzd(fees, lang), l.statEarnings),
          ],
        ),
      ),
    );
  }
}

/// Map of the jobs waiting (restaurants, with the fee) and the rider.
class _JobsMap extends ConsumerWidget {
  const _JobsMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final jobs = ref.watch(availableOrdersProvider).value ?? const [];
    final me = ref.watch(driverPositionProvider).value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: RiderMap(
          me: me,
          pins: [
            for (final o in jobs)
              if (o.restaurantLat != null && o.restaurantLng != null)
                RiderPin(
                  RiderPinKind.restaurant,
                  o.restaurantLat!,
                  o.restaurantLng!,
                  label: formatDzd(o.deliveryFee, lang),
                ),
          ],
        ),
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
    return RiderCard(
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

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.order});
  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    return RiderCard(
      onTap: () => context.push('/driver/orders/${o.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 12),
          RouteStops(
            from: o.restaurantName,
            fromSub: o.restaurantArea.isEmpty
                ? o.restaurantAddress
                : o.restaurantArea,
            to: o.customerName,
            toSub: o.area.isEmpty ? o.addressText : o.area,
          ),
          const SizedBox(height: 12),
          AmountLine(label: l.cashToCollect, value: formatDzd(o.total, lang)),
          const SizedBox(height: 16),
          RiderButton(
            label: l.continueDelivery,
            icon: Icons.navigation_rounded,
            onPressed: () => context.push('/driver/orders/${o.id}'),
          ),
        ],
      ),
    );
  }
}

/// Restaurant → customer, joined by a dotted line.
class RouteStops extends StatelessWidget {
  const RouteStops({
    super.key,
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
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: c.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: c),
        ),
        const SizedBox(width: 12),
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
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 14),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 2,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    color: AppColors.border,
                  ),
              ],
            ),
          ),
        ),
        stop(Icons.location_on_rounded, AppColors.night, to, toSub),
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
    final me = ref.watch(driverPositionProvider).value;
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
          return RiderCard(
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
                padding: const EdgeInsets.only(bottom: 16),
                child: RiderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 12),
                      RouteStops(
                        from: o.restaurantName,
                        fromSub: o.restaurantArea.isEmpty
                            ? o.restaurantAddress
                            : o.restaurantArea,
                        to: o.area.isEmpty ? '—' : o.area,
                        toSub: _distance(l, o),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (kmTo(me, o.restaurantLat, o.restaurantLng)
                              case final km?)
                            StatPill(
                              icon: Icons.near_me_rounded,
                              value: l.kmAway(formatKm(km)),
                              label: l.statDistance,
                            ),
                          StatPill(
                            icon: Icons.shopping_bag_rounded,
                            value: '${o.itemCount}',
                            label: l.itemCount(o.itemCount),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 14),
                      RiderButton(
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
    final km = o.lat == null || o.lng == null
        ? null
        : kmTo(
            o.restaurantLat == null || o.restaurantLng == null
                ? null
                : GeoPoint(o.restaurantLat!, o.restaurantLng!),
            o.lat,
            o.lng,
          );
    return km == null ? '' : l.kmAway(formatKm(km));
  }
}
