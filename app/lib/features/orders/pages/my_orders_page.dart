import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/customer_nav_bar.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/checkout_widgets.dart';
import '../data/orders_repository.dart';
import '../order_status.dart';
import '../../ratings/ratings_repository.dart';

/// My Orders: "Ongoing" and "History" tabs.
class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final orders = ref.watch(myOrdersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        bottomNavigationBar: const CustomerNavBar(current: CustomerTab.orders),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  PageHeader(title: l.myOrders, showBack: false),
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: AppColors.border,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(text: l.ongoingOrders),
                      Tab(text: l.orderHistory),
                    ],
                  ),
                  Expanded(
                    child: orders.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (_, _) => _Message(
                        text: l.loadError,
                        action: TextButton(
                          onPressed: () => ref.invalidate(myOrdersProvider),
                          child: Text(l.retry),
                        ),
                      ),
                      data: (all) => TabBarView(
                        children: [
                          _OrderList(
                            orders: all.where((o) => o.isActive).toList(),
                            empty: l.noOngoingOrders,
                          ),
                          _OrderList(
                            orders: all.where((o) => !o.isActive).toList(),
                            empty: l.noPastOrders,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.muted),
        const SizedBox(height: 12),
        Text(text, style: TextStyle(color: AppColors.body, fontSize: 15)),
        ?action,
      ],
    ),
  );
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders, required this.empty});
  final List<CustomerOrder> orders;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final when = DateFormat('dd/MM/yyyy HH:mm');
    if (orders.isEmpty) return _Message(text: empty);
    final ratings = {
      for (final r
          in ref.watch(myRatingsProvider).value ?? const <OrderRating>[])
        r.orderId: r,
    };
    final now = DateTime.now();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(myOrdersProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: orders.length,
        separatorBuilder: (_, _) => Divider(color: AppColors.border),
        itemBuilder: (context, i) {
          final o = orders[i];
          return OrderCard(
            imageUrl: o.restaurantLogo,
            tag: orderStatusLabel(l, o.status),
            title: o.restaurantName,
            subtitle:
                '#${o.code} · ${l.itemCount(o.itemCount)} · '
                '${when.format(o.placedAt)}',
            amount: formatDzd(o.total, lang),
            onTap: () => context.push('/orders/${o.id}'),
            actions: [
              // Delivered, still within the 7 days and something left to rate.
              if (o.status == 'delivered' &&
                  ratings[o.id] != null &&
                  (ratings[o.id]!.needsFood(now) ||
                      ratings[o.id]!.needsDriver(now)))
                AppButton(
                  label: l.rateAction,
                  icon: Icons.star_rounded,
                  variant: AppButtonVariant.small,
                  onPressed: () => context.push('/orders/${o.id}'),
                ),
              if (o.isActive)
                AppButton(
                  label: l.trackOrder,
                  variant: AppButtonVariant.small,
                  onPressed: () => context.push('/orders/${o.id}'),
                ),
              if (o.canCancel)
                AppButton(
                  label: l.cancel,
                  variant: AppButtonVariant.dangerOutline,
                  onPressed: () => cancelOrderWithConfirm(context, ref, o),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Asks why, then cancels (before the restaurant accepts) or sends a
/// cancellation request (accepted / ready: the restaurant decides).
/// Shared by the list and the order page.
Future<void> cancelOrderWithConfirm(
  BuildContext context,
  WidgetRef ref,
  CustomerOrder order,
) async {
  final l = AppLocalizations.of(context);
  final answer = await showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CancelSheet(request: order.cancelNeedsRequest),
  );
  if (answer == null || !context.mounted) return;
  try {
    final r = await ref
        .read(ordersRepositoryProvider)
        .cancelOrder(order.id, reason: answer.$1, note: answer.$2);
    if (context.mounted) {
      showAppSnack(
        context,
        r == 'requested' ? l.cancelRequestSent : l.orderCancelledMsg,
      );
    }
  } on CheckoutError catch (e) {
    if (context.mounted) {
      showAppSnack(context, checkoutErrorText(l, e.failure), error: true);
    }
  } finally {
    ref.invalidate(myOrdersProvider);
    ref.invalidate(myOrderProvider(order.id));
  }
}

const cancelReasons = [
  'changed_mind',
  'too_long',
  'wrong_address',
  'wrong_items',
  'duplicate',
  'other',
];

String cancelReasonLabel(AppLocalizations l, String? code) => switch (code) {
  'changed_mind' => l.cancelReasonChangedMind,
  'too_long' => l.cancelReasonTooLong,
  'wrong_address' => l.cancelReasonWrongAddress,
  'wrong_items' => l.cancelReasonWrongItems,
  'duplicate' => l.cancelReasonDuplicate,
  _ => l.cancelReasonOther,
};

/// Pops (reason, note).
class CancelSheet extends StatefulWidget {
  const CancelSheet({super.key, required this.request});

  /// The restaurant already accepted: this sends a request.
  final bool request;

  @override
  State<CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<CancelSheet> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(
            widget.request ? l.cancelRequestTitle : l.cancelOrderTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.request ? l.cancelRequestExplain : l.cancelFreeExplain,
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.body),
          ),
          const SizedBox(height: 18),
          Text(
            l.cancelWhy.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(
              children: [
                for (final r in cancelReasons)
                  RadioListTile<String>(
                    key: Key('reason:$r'),
                    value: r,
                    title: Text(cancelReasonLabel(l, r)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          if (widget.request) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(hintText: l.cancelNoteHint),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.keepOrder),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('confirm-cancel'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  onPressed: _reason == null
                      ? null
                      : () => Navigator.pop(context, (
                          _reason!,
                          _note.text.trim(),
                        )),
                  child: Text(
                    widget.request ? l.sendCancelRequest : l.cancelOrder,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
