import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _reload() {
    ref.invalidate(myOrderProvider(widget.orderId));
    ref.invalidate(myOrdersProvider);
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
        if (o.status == 'rejected' && (o.rejectReason ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l.rejectReasonLabel(rejectReasonText(l, o.rejectReason!)),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
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
          ReceiptButtons(order: o),
        ],
        if (o.canCancel) ...[
          const SizedBox(height: 28),
          Center(
            child: AppButton(
              label: l.cancelOrder,
              variant: AppButtonVariant.dangerOutline,
              onPressed: () => cancelOrderWithConfirm(context, ref, o.id),
            ),
          ),
        ],
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
