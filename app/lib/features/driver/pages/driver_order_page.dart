import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/pick_image.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../../ratings/ratings_widgets.dart';
import '../data/driver_live.dart';
import '../data/driver_position.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';
import '../widgets/rider_ui.dart';

/// One delivery, step by step over a map: go to the restaurant, check the
/// items, go to the customer, deliver with the photo and the cash, then
/// "Well done!".
class DriverOrderPage extends ConsumerStatefulWidget {
  const DriverOrderPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DriverOrderPage> createState() => _DriverOrderPageState();
}

class _DriverOrderPageState extends ConsumerState<DriverOrderPage> {
  bool _busy = false;

  /// Set right after "Delivered": shows the "Well done" screen.
  DriverOrder? _done;

  @override
  void initState() {
    super.initState();
    // A message from the previous page would cover the action buttons.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  DriverOrder? _find() => [
    ...?ref.watch(driverActiveOrdersProvider).value,
    ...?ref.watch(driverHistoryProvider).value,
  ].where((o) => o.id == widget.orderId).firstOrNull;

  /// Runs [action]; errors are shown, success is visible on the page.
  /// Returns true when it worked.
  Future<bool> _run(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
      return false;
    } finally {
      ref.invalidate(driverActiveOrdersProvider);
      ref.invalidate(driverHistoryProvider);
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(driverCashPendingProvider);
      ref.invalidate(myDriverProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Photo sheet, then upload + delivered, then "Well done".
  Future<void> _deliver(DriverOrder o) async {
    final photo = await showModalBottomSheet<PickedImage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => ProofPhotoSheet(total: o.total),
    );
    if (photo == null || !mounted) return;
    final ok = await _run(
      () => ref.read(driverRepositoryProvider).completeDelivery(o.id, photo),
    );
    if (ok && mounted) setState(() => _done = o);
  }

  /// Item checklist, then "picked up".
  Future<void> _pickUp(DriverOrder o) async {
    final checked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) =>
          ItemsCheckSheet(items: o.items, restaurantPhone: o.restaurantPhone),
    );
    if (checked != true || !mounted) return;
    await _run(
      () => ref.read(driverRepositoryProvider).setStatus(o.id, 'picked_up'),
    );
  }

  Future<void> _release(DriverOrder o) async {
    final l = AppLocalizations.of(context);
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l.releaseConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.back, style: TextStyle(color: AppColors.body)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l.releaseOrder,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!yes) return;
    await _run(() => ref.read(driverRepositoryProvider).release(o.id));
    if (mounted) context.go('/driver');
  }

  void _details(DriverOrder o) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => OrderDetailsSheet(order: o),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.watch(driverLiveProvider); // live updates on this page too
    ref.watch(driverTrackerProvider); // position for the customer
    final o = _find();
    final loading =
        ref.watch(driverActiveOrdersProvider).isLoading &&
        !ref.watch(driverActiveOrdersProvider).hasValue;

    if (_done != null) {
      return _DoneView(order: _done!);
    }
    if (o == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l.currentDelivery),
              Expanded(
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary,
                        )
                      : Text(l.noOrders),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final me = ref.watch(driverPositionProvider).value;
    // Where the rider goes now: the restaurant until pickup, then the
    // customer.
    final toCustomer = !(o.status == 'accepted' || o.status == 'ready');
    final km = toCustomer
        ? kmTo(me, o.lat, o.lng)
        : kmTo(me, o.restaurantLat, o.restaurantLng);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, box) {
          final top = MediaQuery.paddingOf(context).top;
          return Stack(
            children: [
              Positioned.fill(
                child: RiderMap(
                  me: me,
                  route: o.isActive,
                  follow: o.isActive,
                  padding: EdgeInsets.fromLTRB(
                    48,
                    top + 190,
                    48,
                    box.maxHeight * .6,
                  ),
                  pins: [
                    if (o.restaurantLat != null && o.restaurantLng != null)
                      RiderPin(
                        RiderPinKind.restaurant,
                        o.restaurantLat!,
                        o.restaurantLng!,
                        onRoute: !toCustomer,
                      ),
                    if (o.lat != null && o.lng != null)
                      RiderPin(RiderPinKind.customer, o.lat!, o.lng!),
                  ],
                ),
              ),
              // Top: back + the address of the current stop.
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleIconButton.back(context),
                          const SizedBox(width: 10),
                          Expanded(
                            child: toCustomer
                                ? _StopCard(
                                    label: l.deliveryAddress,
                                    icon: Icons.location_on_rounded,
                                    name: o.customerName,
                                    lines: [
                                      o.addressText,
                                      o.area,
                                      o.addressDetails,
                                    ],
                                    notes: o.notes,
                                    phone: o.isActive ? o.customerPhone : '',
                                    onDirections: o.isActive
                                        ? () => openDirections(
                                            context,
                                            lat: o.lat,
                                            lng: o.lng,
                                            address:
                                                '${o.addressText} ${o.area}',
                                          )
                                        : null,
                                  )
                                : _StopCard(
                                    label: l.pickupAt,
                                    icon: Icons.storefront_rounded,
                                    name: o.restaurantName,
                                    lines: [
                                      o.restaurantAddress,
                                      o.restaurantArea,
                                    ],
                                    phone: o.restaurantPhone,
                                    onDirections: () => openDirections(
                                      context,
                                      lat: o.restaurantLat,
                                      lng: o.restaurantLng,
                                      address:
                                          '${o.restaurantAddress} ${o.restaurantArea}',
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom: stats over the map, then the step card.
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (km != null && o.isActive)
                                StatPill(
                                  icon: Icons.near_me_rounded,
                                  value: l.kmAway(formatKm(km)),
                                  label: l.statDistance,
                                ),
                              StatPill(
                                icon: Icons.shopping_bag_rounded,
                                value:
                                    '${o.items.fold(0, (s, i) => s + i.quantity)}',
                                label: l.statItems,
                              ),
                              StatPill(
                                icon: Icons.payments_rounded,
                                value: formatDzd(o.total, lang),
                                label: l.statCash,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _StepCard(
                            order: o,
                            km: km,
                            busy: _busy,
                            onPickUp: () => _pickUp(o),
                            onDeliver: () => _deliver(o),
                            onRelease: () => _release(o),
                            onDetails: () => _details(o),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The card at the bottom: what to do now and the one big button.
class _StepCard extends ConsumerWidget {
  const _StepCard({
    required this.order,
    required this.km,
    required this.busy,
    required this.onPickUp,
    required this.onDeliver,
    required this.onRelease,
    required this.onDetails,
  });
  final DriverOrder order;
  final double? km;
  final bool busy;
  final VoidCallback onPickUp;
  final VoidCallback onDeliver;
  final VoidCallback onRelease;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    final cancelled = o.status == 'cancelled' || o.status == 'rejected';
    // Before pickup: first go there and check in, then check the items.
    final atShop =
        ref.watch(checkedInProvider).contains(o.id) ||
        (km != null && km! < arrivedKm);
    final toShop = (o.status == 'accepted' || o.status == 'ready') && !atShop;

    final (String title, String sub) = switch (o.status) {
      _ when toShop => (
        l.stepToRestaurant,
        o.status == 'ready' ? l.stepReady : l.waitRestaurant,
      ),
      'accepted' => (l.atRestaurant, l.waitRestaurant),
      'ready' => (l.stepReady, l.stepReadySub),
      'picked_up' => (
        km != null && km! < arrivedKm ? l.stepArrived : l.stepToCustomer,
        l.collectCash(formatDzd(o.total, lang)),
      ),
      'delivered' => (
        l.statusDelivered,
        o.deliveredAt == null
            ? ''
            : l.deliveredOnTime(
                DateFormat('dd/MM HH:mm').format(o.deliveredAt!),
              ),
      ),
      _ => (
        l.cancelledByRestaurant,
        (o.rejectReason ?? '').isEmpty
            ? ''
            : l.rejectReasonLabel(rejectReasonText(l, o.rejectReason!)),
      ),
    };

    return RiderCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cancelled ? AppColors.danger : AppColors.ink,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: o.status == 'picked_up'
                    ? AppColors.primary
                    : AppColors.body,
                fontWeight: o.status == 'picked_up'
                    ? FontWeight.w700
                    : FontWeight.w400,
                fontSize: o.status == 'picked_up' ? 17 : 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (toShop) ...[
            RiderButton(
              label: l.checkIn,
              icon: Icons.storefront_rounded,
              onPressed: () => ref.read(checkedInProvider.notifier).add(o.id),
            ),
            const SizedBox(height: 10),
            RiderButton(
              label: l.directions,
              icon: Icons.navigation_rounded,
              secondary: true,
              onPressed: () => openDirections(
                context,
                lat: o.restaurantLat,
                lng: o.restaurantLng,
                address: '${o.restaurantAddress} ${o.restaurantArea}',
              ),
            ),
          ],
          if (!toShop && o.status == 'accepted')
            Center(
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySoft,
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          if (!toShop && o.status == 'ready')
            RiderButton(
              label: l.checkItems,
              icon: Icons.checklist_rounded,
              loading: busy,
              onPressed: onPickUp,
            ),
          if (o.status == 'picked_up') ...[
            RiderButton(
              label: l.markDelivered,
              icon: Icons.task_alt_rounded,
              loading: busy,
              onPressed: onDeliver,
            ),
            const SizedBox(height: 10),
            RiderButton(
              label: l.directions,
              icon: Icons.navigation_rounded,
              secondary: true,
              onPressed: () => openDirections(
                context,
                lat: o.lat,
                lng: o.lng,
                address: '${o.addressText} ${o.area}',
              ),
            ),
          ],
          if (cancelled)
            RiderButton(
              label: l.back,
              secondary: true,
              onPressed: () => context.go('/driver'),
            ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(l.orderDetailsTitle),
              ),
              if (o.canRelease)
                TextButton(
                  onPressed: busy ? null : onRelease,
                  child: Text(
                    l.releaseOrder,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
            ],
          ),
          if (o.status == 'picked_up' || !o.isActive)
            Center(child: ReportCustomerLink(orderId: o.id)),
        ],
      ),
    );
  }
}

/// Address card at the top ("Delivery address" + name, call, directions).
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.label,
    required this.icon,
    required this.name,
    required this.lines,
    required this.phone,
    this.notes = '',
    this.onDirections,
  });
  final String label;
  final IconData icon;
  final String name;
  final List<String> lines;
  final String phone;
  final String notes;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = lines.where((x) => x.trim().isNotEmpty).join(' · ');
    return RiderCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.body, fontSize: 13),
                  ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '“$notes”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(width: 8),
            RoundAction(
              icon: Icons.call_rounded,
              tooltip: l.callAction,
              size: 44,
              onTap: () => callNumber(context, phone),
            ),
          ],
          if (onDirections != null) ...[
            const SizedBox(width: 8),
            RoundAction(
              icon: Icons.directions_rounded,
              tooltip: l.directions,
              size: 44,
              onTap: onDirections!,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Well done Rachid!" after a delivery, with the next step.
class _DoneView extends ConsumerStatefulWidget {
  const _DoneView({required this.order});
  final DriverOrder order;

  @override
  ConsumerState<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends ConsumerState<_DoneView> {
  bool _stopping = false;

  Future<void> _stop() async {
    setState(() => _stopping = true);
    try {
      await ref.read(driverRepositoryProvider).setOnline(false);
    } on DriverError catch (_) {
      // Going offline can't really fail; the home page shows the state.
    } finally {
      ref.invalidate(myDriverProvider);
      if (mounted) context.go('/driver');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final me = ref.watch(myDriverProvider).value;
    final name = (me?.fullName ?? '').isEmpty
        ? l.driverSection
        : me!.fullName.split(' ').first;
    final o = widget.order;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                RiderCard(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                  child: Column(
                    children: [
                      Text(
                        l.wellDone(name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const DoneBadge(),
                      const SizedBox(height: 12),
                      Text(
                        l.deliveryNumber(o.code),
                        style: TextStyle(fontSize: 20, color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.youEarned(formatDzd(o.deliveryFee, lang)),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                RiderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.readyNextJob,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RiderButton(
                        label: l.nextJob,
                        icon: me == null
                            ? Icons.two_wheeler_rounded
                            : vehicleIcon(me.vehicle),
                        onPressed: _stopping
                            ? null
                            : () => context.go('/driver'),
                      ),
                      const SizedBox(height: 12),
                      RiderButton(
                        label: l.doneForToday,
                        secondary: true,
                        loading: _stopping,
                        onPressed: _stop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Check each item": tap every line once it is in the bag.
class ItemsCheckSheet extends StatefulWidget {
  const ItemsCheckSheet({
    super.key,
    required this.items,
    this.restaurantPhone = '',
  });
  final List<OrderLine> items;

  /// "Missing or wrong item?" calls this number.
  final String restaurantPhone;

  @override
  State<ItemsCheckSheet> createState() => _ItemsCheckSheetState();
}

class _ItemsCheckSheetState extends State<ItemsCheckSheet> {
  final _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = widget.items;
    final all = _checked.length == items.length;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
              child: Text(
                l.checkItemsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l.checkItemsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.body),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final on = _checked.contains(i);
                  final it = items[i];
                  return Material(
                    color: on
                        ? AppColors.success.withValues(alpha: .10)
                        : AppColors.field,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(
                        () => on ? _checked.remove(i) : _checked.add(i),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${it.quantity}×',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                it.name,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              on
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 30,
                              color: on ? AppColors.success : AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // The flow's "missing / wrong items → inform the merchant".
            if (widget.restaurantPhone.isNotEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () => callNumber(context, widget.restaurantPhone),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(l.missingItemCall),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: RiderButton(
                label: l.headToCustomer,
                icon: Icons.two_wheeler_rounded,
                onPressed: all ? () => Navigator.of(context).pop(true) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything about the order: items, money, phones, notes.
class OrderDetailsSheet extends StatelessWidget {
  const OrderDetailsSheet({super.key, required this.order});
  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    Widget contact(String title, String name, String phone) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: AppColors.body),
                  ),
              ],
            ),
          ),
          if (phone.isNotEmpty && o.isActive)
            RoundAction(
              icon: Icons.call_rounded,
              tooltip: l.callAction,
              size: 40,
              onTap: () => callNumber(context, phone),
            ),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l.orderDetailsTitle} · #${o.code}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            contact(l.pickupAt, o.restaurantName, o.restaurantPhone),
            contact(l.dropOffAt, o.customerName, o.customerPhone),
            if (o.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '“${o.notes}”',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Divider(color: AppColors.border, height: 20),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${i.quantity}× ${i.name}',
                  style: TextStyle(color: AppColors.ink),
                ),
              ),
            Divider(color: AppColors.border, height: 20),
            AmountLine(
              label: l.cashToCollect,
              value: formatDzd(o.total, lang),
              big: true,
            ),
            AmountLine(
              label: l.handToRestaurant,
              // Food after any discount, plus the tax.
              value: formatDzd(o.total - o.deliveryFee, lang),
            ),
            AmountLine(
              label: l.yourFee,
              value: formatDzd(o.deliveryFee, lang),
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Delivered & paid": take the proof photo, see it, confirm with the cash
/// amount. Pops the photo, or null when cancelled.
class ProofPhotoSheet extends ConsumerStatefulWidget {
  const ProofPhotoSheet({super.key, required this.total});
  final int total;

  @override
  ConsumerState<ProofPhotoSheet> createState() => _ProofPhotoSheetState();
}

class _ProofPhotoSheetState extends ConsumerState<ProofPhotoSheet> {
  PickedImage? _photo;
  bool _opening = false;

  Future<void> _take({bool camera = true}) async {
    final l = AppLocalizations.of(context);
    setState(() => _opening = true);
    try {
      final p = await ref.read(takeProofPhotoProvider)(camera: camera);
      if (p != null && mounted) setState(() => _photo = p);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (e) {
      // Most often: camera permission refused, or no camera (computer).
      if (mounted) showAppSnack(context, l.errCamera, error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final photo = _photo;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.proofTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.proofHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.body),
            ),
            const SizedBox(height: 16),
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.memory(
                  photo.bytes,
                  height: 220,
                  fit: BoxFit.cover,
                  // A photo the phone can't preview is still sent.
                  errorBuilder: (_, _, _) => Container(
                    height: 220,
                    color: AppColors.field,
                    child: const Icon(
                      Icons.image_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else
              Material(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: _opening ? null : _take,
                  child: SizedBox(
                    height: 160,
                    child: Center(
                      child: _opening
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.takePhoto,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (photo != null)
                  TextButton.icon(
                    onPressed: _opening ? null : _take,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.retakePhoto),
                  ),
                // Fallback when the camera can't open (permission refused,
                // computer without camera): pick a photo instead.
                TextButton.icon(
                  onPressed: _opening ? null : () => _take(camera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l.chooseFromGallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.confirmDelivered(formatDzd(widget.total, lang)),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            RiderButton(
              label: l.markDelivered,
              icon: Icons.task_alt_rounded,
              onPressed: photo == null
                  ? null
                  : () => Navigator.of(context).pop(photo),
            ),
          ],
        ),
      ),
    );
  }
}
