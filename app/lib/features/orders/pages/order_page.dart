import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_service.dart';
import '../../driver/widgets/rider_ui.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/pdf/business_info.dart';
import '../../../core/pdf/pdf_output.dart';
import '../../../core/pdf/receipt_pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/snack.dart';
import '../../account/data/account_repository.dart';
import '../order_receipt.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/checkout_widgets.dart';
import '../data/orders_repository.dart';
import 'my_orders_page.dart';
import '../order_status.dart';
import '../../ratings/ratings_repository.dart';
import '../../ratings/ratings_widgets.dart';

/// One order: live status steps, what was ordered, amounts, where it goes.
/// Updates by itself when the restaurant (and later the driver) moves it on.
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  StreamSubscription<void>? _live;
  Timer? _poll;

  /// The delivery pop-up is shown once per order and session.
  bool _asking = false;

  void _reload() {
    ref.invalidate(myOrderProvider(widget.orderId));
    ref.invalidate(myOrdersProvider);
    ref.invalidate(orderRatingProvider(widget.orderId));
  }

  /// Delivered with a driver who isn't rated yet: ask for the rating (live,
  /// as the driver hands over the food, or when opening the page later).
  void _maybeAskDriver(CustomerOrder? o, OrderRating? rating) {
    if (_asking || o == null || rating == null) return;
    if (o.status != 'delivered' || o.driverName == null) return;
    if (!rating.needsDriver(DateTime.now())) return;
    if (ref.read(promptedOrdersProvider).contains(o.id)) return;
    _asking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(promptedOrdersProvider.notifier).add(o.id);
      await showRatingSheet(
        context,
        orderId: o.id,
        driver: true,
        subject: o.driverName!,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _live = ref
        .read(ordersRepositoryProvider)
        .orderChanges(widget.orderId)
        .listen((_) => _reload(), onError: (_) {});
    // Fallback if the live connection drops (mobile networks): refresh
    // every 30 s while the order is in progress.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      final o = ref.read(myOrderProvider(widget.orderId)).value;
      if (o != null && o.isActive) _reload();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(myOrderProvider(widget.orderId));
    _maybeAskDriver(
      order.value,
      ref.watch(orderRatingProvider(widget.orderId)).value,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(
                  title: order.value == null
                      ? l.trackOrder
                      : l.orderNumber(order.value!.code),
                ),
                Expanded(
                  child: order.when(
                    skipLoadingOnRefresh: true,
                    skipLoadingOnReload: true,
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: _reload,
                        child: Text(
                          '${l.loadError}\n${l.retry}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (o) => o == null
                        ? Center(child: Text(l.noOrders))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => ref.refresh(
                              myOrderProvider(widget.orderId).future,
                            ),
                            child: _OrderBody(order: o),
                          ),
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

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final time = DateFormat('HH:mm');
    final date = DateFormat('dd/MM/yyyy HH:mm');
    final o = order;

    // Steps in order; the index of the first unfinished step is current.
    final steps = [
      StatusStep(l.statusPlaced, time: time.format(o.placedAt)),
      StatusStep(
        l.statusAccepted,
        time: o.acceptedAt == null ? null : time.format(o.acceptedAt!),
      ),
      StatusStep(
        l.statusReady,
        time: o.readyAt == null ? null : time.format(o.readyAt!),
      ),
      StatusStep(
        l.statusPickedUp,
        time: o.pickedUpAt == null ? null : time.format(o.pickedUpAt!),
      ),
      StatusStep(
        l.statusDelivered,
        time: o.deliveredAt == null ? null : time.format(o.deliveredAt!),
      ),
    ];
    final current = switch (o.status) {
      'placed' => 1,
      'accepted' => 2,
      'ready' => 3,
      'picked_up' => 4,
      'delivered' => 5,
      // Failed: the last step reached is done, then the red row.
      _ =>
        o.readyAt != null
            ? 3
            : o.acceptedAt != null
            ? 2
            : 1,
    };

    final title = Theme.of(context).textTheme.titleSmall;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        // Restaurant + date.
        Row(
          children: [
            AppImage(url: o.restaurantLogo, width: 64, height: 64, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.restaurantName, style: title),
                  const SizedBox(height: 4),
                  Text(
                    l.orderedAt(date.format(o.placedAt)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StatusSteps(
          steps: o.isFailed ? steps.sublist(0, current) : steps,
          currentIndex: current,
          failedLabel: o.isFailed
              ? (o.status == 'rejected' ? l.statusRejected : l.statusCancelled)
              : null,
        ),
        if (o.deliveryPhotoPath != null) ...[
          Text(
            l.proofOfDelivery.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          AppImage(
            url: ref.watch(proofUrlProvider(o.deliveryPhotoPath!)).value,
            width: double.infinity,
            height: 220,
          ),
          const SizedBox(height: 16),
        ],
        _CancelNote(order: o),
        if (o.status == 'rejected' && (o.rejectReason ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l.rejectReasonLabel(rejectReasonText(l, o.rejectReason!)),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        if (o.driverName != null && o.isActive) _RiderTracker(order: o),
        if (o.driverName != null && o.isActive)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.yourDriver.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        o.driverName!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((o.driverPhone ?? '').isNotEmpty)
                  Text(
                    o.driverPhone!,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        Divider(color: AppColors.border, height: 24),

        // What was ordered.
        Text(
          l.orderItems.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        for (final i in o.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '${i.quantity}×',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    i.name,
                    style: TextStyle(color: AppColors.ink, fontSize: 15),
                  ),
                ),
                Text(
                  formatDzd(i.lineTotal, lang),
                  style: TextStyle(color: AppColors.body),
                ),
              ],
            ),
          ),
        Divider(color: AppColors.border, height: 24),
        MoneyRow(label: l.subtotal, value: formatDzd(o.foodTotal, lang)),
        MoneyRow(
          label: l.deliveryFee,
          value: o.deliveryFee == 0
              ? l.freeDelivery
              : formatDzd(o.deliveryFee, lang),
        ),
        if (o.discountAmount > 0)
          MoneyRow(
            label: o.promoCode == null
                ? l.discount
                : '${l.discount} (${o.promoCode})',
            value: '−${formatDzd(o.discountAmount, lang)}',
            color: AppColors.success,
          ),
        if (o.taxAmount > 0)
          MoneyRow(label: l.taxLabel, value: formatDzd(o.taxAmount, lang)),
        MoneyRow(label: l.total, value: formatDzd(o.total, lang), strong: true),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(l.cashOnDelivery, style: TextStyle(color: AppColors.body)),
          ],
        ),
        Divider(color: AppColors.border, height: 32),

        // Where it goes.
        Text(
          l.deliveryAddress.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(
          [o.addressText, o.area].where((s) => s.isNotEmpty).join(', '),
          style: TextStyle(color: AppColors.ink, fontSize: 15),
        ),
        if (o.addressDetails.isNotEmpty)
          Text(o.addressDetails, style: TextStyle(color: AppColors.body)),
        const SizedBox(height: 6),
        Text(
          o.customerPhone,
          textDirection: TextDirection.ltr,
          textAlign: Directionality.of(context) == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          style: TextStyle(color: AppColors.body),
        ),
        if (o.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.notes.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(o.notes, style: TextStyle(color: AppColors.body)),
        ],
        if (o.status == 'delivered') ...[
          const SizedBox(height: 24),
          _RatingCards(order: o),
          const SizedBox(height: 8),
          ReceiptButtons(order: o),
        ],
        if (o.canCancel) ...[
          const SizedBox(height: 28),
          Center(
            child: AppButton(
              key: const Key('cancel-order'),
              label: l.cancelOrder,
              variant: AppButtonVariant.dangerOutline,
              onPressed: () => cancelOrderWithConfirm(context, ref, o),
            ),
          ),
        ],
      ],
    );
  }
}

/// Which delivered orders already got the "rate your driver" pop-up.
class PromptedOrders extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) => state = {...state, id};
}

final promptedOrdersProvider = NotifierProvider<PromptedOrders, Set<String>>(
  PromptedOrders.new,
);

/// "Rate the delivery" and "Rate the food" on a delivered order: stars once
/// rated (changeable for 24 h), a button while the 7 days run.
class _RatingCards extends ConsumerWidget {
  const _RatingCards({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rating = ref.watch(orderRatingProvider(order.id)).value;
    if (rating == null) return const SizedBox.shrink();
    final now = DateTime.now();

    Widget card({
      required IconData icon,
      required String title,
      required int? stars,
      required bool canRate,
      required bool canEdit,
      required String idleHint,
      required VoidCallback onTap,
      String? reply,
    }) {
      if (stars == null && !canRate) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stars == null ? title : l.yourRating,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (stars != null)
                        Stars(stars.toDouble(), size: 20)
                      else
                        Text(
                          idleHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (stars == null)
                  AppButton(
                    label: l.rateAction,
                    variant: AppButtonVariant.small,
                    onPressed: onTap,
                  )
                else if (canEdit)
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      l.editRating,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            if (stars != null && canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.ratingEditHint,
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
            if ((reply ?? '').isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.ratingReplyFrom,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(reply!, style: TextStyle(color: AppColors.body)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final days = rating.daysLeft(now);
    final hint = days <= 1 ? l.ratingLastDay : l.ratingDaysLeft(days);
    return Column(
      children: [
        if (rating.hasDriver)
          card(
            icon: Icons.delivery_dining_rounded,
            title: l.rateDriverCard,
            stars: rating.driverStars,
            canRate: rating.windowOpen(now),
            canEdit: rating.driverOpen(now),
            idleHint: hint,
            onTap: () async {
              await showRatingSheet(
                context,
                orderId: order.id,
                driver: true,
                subject: order.driverName ?? '',
                initialStars: rating.driverStars ?? 0,
                initialReasons: rating.driverReasons,
                initialComment: rating.driverComment,
              );
            },
          ),
        card(
          icon: Icons.restaurant_rounded,
          title: l.rateFoodCard,
          stars: rating.foodStars,
          canRate: rating.windowOpen(now),
          canEdit: rating.foodOpen(now),
          idleHint: hint,
          reply: rating.reply,
          onTap: () async {
            await showRatingSheet(
              context,
              orderId: order.id,
              driver: false,
              subject: order.restaurantName,
              initialStars: rating.foodStars ?? 0,
              initialReasons: rating.foodReasons,
              initialComment: rating.foodComment,
            );
          },
        ),
      ],
    );
  }
}

/// "Download receipt" / "Print" for a delivered order.
class ReceiptButtons extends ConsumerStatefulWidget {
  const ReceiptButtons({super.key, required this.order});
  final CustomerOrder order;

  @override
  ConsumerState<ReceiptButtons> createState() => _ReceiptButtonsState();
}

class _ReceiptButtonsState extends ConsumerState<ReceiptButtons> {
  bool _busy = false;

  Future<void> _go({required bool print}) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final o = widget.order;
      final business = await ref.read(businessInfoRepositoryProvider).get();
      final profile = ref.read(profileProvider).value;
      final bytes = await buildOrderReceipt(
        order: o,
        customerName: profile?.fullName ?? '',
        business: business,
        l: l,
        lang: lang,
        fonts: await PdfFonts.fromAssets(),
      );
      final out = ref.read(pdfOutputProvider);
      final name = 'recu-${o.code}';
      if (print) {
        await out.print(bytes, name);
      } else {
        await out.download(bytes, '$name.pdf');
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        AppButton(
          label: l.downloadReceipt,
          icon: Icons.download_rounded,
          variant: AppButtonVariant.small,
          loading: _busy,
          onPressed: _busy ? null : () => _go(print: false),
        ),
        AppButton(
          label: l.printAction,
          icon: Icons.print_outlined,
          variant: AppButtonVariant.outline,
          onPressed: _busy ? null : () => _go(print: true),
        ),
      ],
    );
  }
}

/// "Follow your rider": live map while the rider has the order. Hidden
/// until the rider's phone has sent a position.
class _RiderTracker extends ConsumerWidget {
  const _RiderTracker({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(riderLocationProvider(order.id)).value;
    if (p == null) return const SizedBox.shrink();
    final pickedUp = order.status == 'picked_up';
    final km = p.toLat == null || p.toLng == null
        ? null
        : distanceKm(p.lat, p.lng, p.toLat!, p.toLng!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.followRider.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 220,
              child: RiderMap(
                me: GeoPoint(p.lat, p.lng),
                meIcon: Icons.delivery_dining_rounded,
                route: true,
                follow: true,
                padding: const EdgeInsets.fromLTRB(40, 70, 40, 30),
                pins: [
                  if (p.shopLat != null && p.shopLng != null)
                    RiderPin(
                      RiderPinKind.restaurant,
                      p.shopLat!,
                      p.shopLng!,
                      onRoute: !pickedUp,
                    ),
                  if (p.toLat != null && p.toLng != null)
                    RiderPin(RiderPinKind.customer, p.toLat!, p.toLng!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (km != null) l.riderKmAway(formatKm(km)),
              l.riderUpdatedAt(DateFormat('HH:mm').format(p.updatedAt)),
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Where a cancellation stands: request waiting / refused / too late, or
/// who cancelled and why.
class _CancelNote extends StatelessWidget {
  const _CancelNote({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final (String? text, Color color, IconData icon) = switch (o) {
      _ when o.status == 'cancelled' && o.cancelledBy == 'customer' => (
        l.cancelledByYou(cancelReasonLabel(l, o.cancelReason)),
        AppColors.danger,
        Icons.cancel_outlined,
      ),
      _ when o.cancelRequestStatus == 'pending' => (
        l.cancelRequestPending,
        const Color(0xFFE8A317),
        Icons.hourglass_top_rounded,
      ),
      _ when o.cancelRequestStatus == 'refused' && o.isActive => (
        l.cancelRequestRefused,
        AppColors.body,
        Icons.info_outline_rounded,
      ),
      _ when o.cancelRequestStatus == 'expired' && o.isActive => (
        l.cancelRequestExpired,
        AppColors.body,
        Icons.info_outline_rounded,
      ),
      _ => (null, AppColors.body, Icons.info_outline_rounded),
    };
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: const Key('cancel-note'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
