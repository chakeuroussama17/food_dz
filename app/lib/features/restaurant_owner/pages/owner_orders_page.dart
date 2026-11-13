import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/checkout_widgets.dart' show MoneyRow;
import '../../orders/order_status.dart';
import '../data/owner_live.dart';
import '../data/owner_orders_repository.dart';
import '../../orders/pages/my_orders_page.dart' show cancelReasonLabel;
import '../owner_receipt.dart';
import '../widgets/owner_widgets.dart';
import '../../ratings/ratings_widgets.dart';

enum OwnerOrdersTab { fresh, running, history }

/// Restaurant orders ("Running Orders" design): new requests to accept or
/// reject, orders in progress to mark ready, and history. Live.
class OwnerOrdersPage extends ConsumerStatefulWidget {
  const OwnerOrdersPage({super.key, this.initialTab});
  final OwnerOrdersTab? initialTab;

  @override
  ConsumerState<OwnerOrdersPage> createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends ConsumerState<OwnerOrdersPage> {
  late OwnerOrdersTab _tab = widget.initialTab ?? OwnerOrdersTab.fresh;
  bool _autoPicked = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = ref.watch(ownerLiveProvider);
    final active = ref.watch(ownerActiveOrdersProvider);
    final list = active.value ?? const <OwnerOrder>[];
    final fresh = list.where((o) => o.isNew).toList();
    final running = list.where((o) => o.isRunning).toList();
    final audible = live.soundReady && !live.muted;

    // Opened from the bar with nothing new: show what's in progress.
    if (!_autoPicked && widget.initialTab == null && active.hasValue) {
      _autoPicked = true;
      if (fresh.isEmpty && running.isNotEmpty) _tab = OwnerOrdersTab.running;
    }

    String label(OwnerOrdersTab t) => switch (t) {
      OwnerOrdersTab.fresh => l.tabNewOrders(fresh.length),
      OwnerOrdersTab.running => l.tabInProgress(running.length),
      OwnerOrdersTab.history => l.orderHistory,
    };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.orders),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                PageHeader(
                  title: l.orders,
                  showBack: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.ordersTable,
                        onPressed: () =>
                            context.push('/restaurant/orders/table'),
                        icon: Icon(
                          Icons.table_chart_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                      IconButton(
                        tooltip: audible ? l.soundOn : l.soundOff,
                        onPressed: () => ref
                            .read(ownerLiveProvider.notifier)
                            .setMuted(audible),
                        icon: Icon(
                          audible
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: audible ? AppColors.primary : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!live.soundReady && !live.muted)
                  _SoundBanner(
                    text: l.enableSoundAlerts,
                    onTap: () =>
                        ref.read(ownerLiveProvider.notifier).enableSound(),
                  ),
                PillChips<OwnerOrdersTab>(
                  items: OwnerOrdersTab.values,
                  selected: _tab,
                  labelOf: label,
                  onSelected: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    child: switch (_tab) {
                      OwnerOrdersTab.fresh => _List(
                        value: active,
                        orders: fresh,
                        empty: l.noNewOrders,
                      ),
                      OwnerOrdersTab.running => _List(
                        value: active,
                        orders: running,
                        empty: l.noOrdersInProgress,
                      ),
                      OwnerOrdersTab.history => _List(
                        value: ref.watch(ownerHistoryProvider),
                        empty: l.noOrders,
                      ),
                    },
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

class _SoundBanner extends StatelessWidget {
  const _SoundBanner({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _List extends ConsumerWidget {
  const _List({required this.value, required this.empty, this.orders});
  final AsyncValue<List<OwnerOrder>> value;

  /// Already filtered list; null = use [value] as is.
  final List<OwnerOrder>? orders;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (value.hasError && !value.hasValue) {
      return Center(
        child: TextButton(
          onPressed: () {
            ref.invalidate(ownerActiveOrdersProvider);
            ref.invalidate(ownerHistoryProvider);
          },
          child: Text(
            '${l.loadError}\n${l.retry}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!value.hasValue) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final list = orders ?? value.value!;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(empty, style: TextStyle(color: AppColors.body)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(ownerActiveOrdersProvider);
        ref.invalidate(ownerHistoryProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: list.length,
        separatorBuilder: (_, _) => Divider(color: AppColors.border),
        itemBuilder: (_, i) => OwnerOrderTile(order: list[i]),
      ),
    );
  }
}

/// One order in the Running Orders style: time box, #code, dishes,
/// customer, total, action buttons.
class OwnerOrderTile extends ConsumerWidget {
  const OwnerOrderTile({super.key, required this.order});
  final OwnerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    return OrderCard(
      leading: _TimeBox(order: o),
      tag: '#${o.code}',
      title: o.summary,
      subtitle: [
        [o.customerName, if (o.area.isNotEmpty) o.area].join(' · '),
        if (o.driverName != null && o.isRunning) l.driverLabel(o.driverName!),
      ].join('\n'),
      amount: formatDzd(o.total, lang),
      onTap: () => showOwnerOrderSheet(context, o),
      extra: o.cancelRequestPending
          ? CancelRequestBanner(order: o)
          : o.isNew || o.isRunning
          ? (o.notes.isEmpty
                ? null
                : Text(
                    '“${o.notes}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                  ))
          : Pill(
              orderStatusLabel(l, o.status),
              color: orderStatusColor(o.status),
            ),
      actions: ownerActions(context, ref, o),
    );
  }
}

/// Buttons for an order, by status.
List<Widget> ownerActions(BuildContext context, WidgetRef ref, OwnerOrder o) {
  final l = AppLocalizations.of(context);
  if (o.cancelRequestPending) {
    return [
      AppButton(
        key: const Key('accept-cancel'),
        label: l.acceptCancel,
        variant: AppButtonVariant.dangerOutline,
        onPressed: () => answerCancelRequest(context, ref, o, accept: true),
      ),
      AppButton(
        key: const Key('refuse-cancel'),
        label: l.refuseCancel,
        variant: AppButtonVariant.small,
        onPressed: () => answerCancelRequest(context, ref, o, accept: false),
      ),
    ];
  }
  return switch (o.status) {
    'placed' => [
      AppButton(
        label: l.accept,
        variant: AppButtonVariant.small,
        onPressed: () => _set(context, ref, o, 'accepted'),
      ),
      AppButton(
        label: l.reject,
        variant: AppButtonVariant.dangerOutline,
        onPressed: () => _set(context, ref, o, 'rejected'),
      ),
    ],
    'accepted' => [
      AppButton(
        label: l.markReady,
        variant: AppButtonVariant.small,
        onPressed: () => _set(context, ref, o, 'ready'),
      ),
      AppButton(
        label: l.cancel,
        variant: AppButtonVariant.dangerOutline,
        onPressed: () => _set(context, ref, o, 'cancelled'),
      ),
    ],
    'ready' => [
      Pill(l.waitingDriver, color: AppColors.primary),
      AppButton(
        label: l.cancel,
        variant: AppButtonVariant.dangerOutline,
        onPressed: () => _set(context, ref, o, 'cancelled'),
      ),
    ],
    'picked_up' => [Pill(l.statusPickedUp, color: AppColors.primary)],
    _ => const [],
  };
}

Future<void> _set(
  BuildContext context,
  WidgetRef ref,
  OwnerOrder o,
  String status,
) async {
  final l = AppLocalizations.of(context);
  String? reason;
  if (status == 'rejected' || status == 'cancelled') {
    reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: status == 'rejected'
            ? l.rejectOrderTitle
            : l.cancelOrderTitleOwner,
        quick: status == 'rejected'
            ? [l.reasonBusy, l.reasonItemOut, l.reasonClosing]
            : [l.reasonUnreachable, l.reasonItemOut],
      ),
    );
    if (reason == null) return;
  }
  try {
    await ref
        .read(ownerOrdersRepositoryProvider)
        .setStatus(o.id, status, reason: reason);
    if (context.mounted) {
      showAppSnack(context, switch (status) {
        'accepted' => l.orderAcceptedMsg,
        'ready' => l.orderReadyMsg,
        'rejected' => l.orderRejectedMsg,
        _ => l.orderCancelledMsg,
      });
    }
  } on OwnerOrderError catch (e) {
    if (context.mounted) {
      showAppSnack(context, switch (e.failure) {
        OwnerOrderFailure.network => l.errNetwork,
        OwnerOrderFailure.reasonRequired => l.errReasonRequired,
        _ => l.errOrderChanged,
      }, error: true);
    }
  } finally {
    ref.invalidate(ownerActiveOrdersProvider);
    ref.invalidate(ownerHistoryProvider);
    ref.invalidate(ownerReportProvider);
    ref.read(orderChangesProvider.notifier).bump();
  }
}

/// Square box instead of a photo: order time and how long ago.
class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.order});
  final OwnerOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mins = DateTime.now().difference(order.placedAt).inMinutes;
    final urgent = order.isNew;
    return Container(
      width: 102,
      height: 102,
      decoration: BoxDecoration(
        color: urgent ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(order.placedAt),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: urgent ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mins < 1 ? l.justNow : l.minutesAgo(mins),
            style: TextStyle(
              fontSize: 12,
              color: urgent ? Colors.white : AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.quick});
  final String title;
  final List<String> quick;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l) {
    final r = _text.text.trim();
    if (r.isEmpty) {
      setState(() => _error = l.errReasonRequired);
      return;
    }
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in widget.quick)
                  ActionChip(
                    label: Text(q),
                    onPressed: () => setState(() {
                      _text.text = q;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.reasonLabel,
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        TextButton(
          onPressed: () => _submit(l),
          child: Text(
            widget.title,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

/// Full order: customer (phone copyable), address, notes, dishes, amounts.
Future<void> showOwnerOrderSheet(BuildContext context, OwnerOrder o) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _OrderSheet(order: o),
    );

class _OrderSheet extends ConsumerWidget {
  const _OrderSheet({required this.order});
  final OwnerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    // Follow live changes while the sheet is open.
    final o =
        [
          ...?ref.watch(ownerActiveOrdersProvider).value,
          ...?ref.watch(ownerHistoryProvider).value,
        ].where((x) => x.id == order.id).firstOrNull ??
        order;
    final label = Theme.of(context).textTheme.labelMedium;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 60,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFC1C7D0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.orderNumber(o.code),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Pill(
                orderStatusLabel(l, o.status),
                color: orderStatusColor(o.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.orderedAt(DateFormat('dd/MM/yyyy HH:mm').format(o.placedAt)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((o.rejectReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.rejectReasonLabel(rejectReasonText(l, o.rejectReason!)),
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          Divider(color: AppColors.border, height: 28),
          Text(l.customer.toUpperCase(), style: label),
          const SizedBox(height: 6),
          Text(
            o.customerName,
            style: TextStyle(fontSize: 16, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: o.customerPhone));
              showAppSnack(context, o.customerPhone);
            },
            child: Row(
              children: [
                const Icon(
                  Icons.call_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  o.customerPhone,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l.deliveryAddress.toUpperCase(), style: label),
          const SizedBox(height: 6),
          Text(
            [o.addressText, o.area].where((s) => s.isNotEmpty).join(', '),
            style: TextStyle(color: AppColors.ink),
          ),
          if (o.addressDetails.isNotEmpty)
            Text(o.addressDetails, style: TextStyle(color: AppColors.body)),
          if (o.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.notes.toUpperCase(), style: label),
            const SizedBox(height: 6),
            Text(o.notes, style: TextStyle(color: AppColors.ink)),
          ],
          Divider(color: AppColors.border, height: 28),
          Text(l.orderItems.toUpperCase(), style: label),
          const SizedBox(height: 6),
          for (final i in o.items)
            MoneyRow(
              label: '${i.quantity}× ${i.name}',
              value: formatDzd(i.lineTotal, lang),
            ),
          Divider(color: AppColors.border, height: 20),
          MoneyRow(label: l.subtotal, value: formatDzd(o.foodTotal, lang)),
          MoneyRow(label: l.deliveryFee, value: formatDzd(o.deliveryFee, lang)),
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
          MoneyRow(
            label: l.total,
            value: formatDzd(o.total, lang),
            strong: true,
          ),
          const SizedBox(height: 6),
          Text(l.cashOnDelivery, style: TextStyle(color: AppColors.body)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: ownerActions(context, ref, o),
          ),
          if (o.status == 'delivered') ...[
            const SizedBox(height: 12),
            OwnerReceiptButtons(order: o),
          ],
          const SizedBox(height: 4),
          Center(child: ReportCustomerLink(orderId: o.id)),
        ],
      ),
    );
  }
}

/// Red box on an order the customer asked to cancel: why, and their note.
class CancelRequestBanner extends StatelessWidget {
  const CancelRequestBanner({super.key, required this.order});
  final OwnerOrder order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      key: const Key('cancel-request'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.customerWantsCancel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    cancelReasonLabel(l, order.cancelRequestReason),
                    if (order.cancelRequestNote.isNotEmpty)
                      '“${order.cancelRequestNote}”',
                  ].join(' · '),
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 4),
                Text(
                  l.cancelRequestOwnerHint,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accepts (the order is cancelled) or refuses (it goes on).
Future<void> answerCancelRequest(
  BuildContext context,
  WidgetRef ref,
  OwnerOrder o, {
  required bool accept,
}) async {
  final l = AppLocalizations.of(context);
  try {
    await ref
        .read(ownerOrdersRepositoryProvider)
        .answerCancelRequest(o.id, accept: accept);
    if (context.mounted) {
      showAppSnack(context, accept ? l.cancelAcceptedMsg : l.cancelRefusedMsg);
    }
  } on OwnerOrderError catch (e) {
    if (context.mounted) {
      showAppSnack(
        context,
        e.failure == OwnerOrderFailure.network
            ? l.errNetwork
            : l.errOrderChanged,
        error: true,
      );
    }
  } finally {
    ref.invalidate(ownerActiveOrdersProvider);
    ref.invalidate(ownerHistoryProvider);
    ref.invalidate(ownerReportProvider);
    ref.read(orderChangesProvider.notifier).bump();
  }
}
