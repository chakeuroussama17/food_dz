import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/checkout_widgets.dart';
import '../data/orders_repository.dart';
import '../order_status.dart';

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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  PageHeader(title: l.myOrders),
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
        const Icon(
          Icons.receipt_long_outlined,
          size: 52,
          color: AppColors.muted,
        ),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: AppColors.body, fontSize: 15)),
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(myOrdersProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const Divider(color: AppColors.border),
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
                  onPressed: () => cancelOrderWithConfirm(context, ref, o.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Asks, then cancels. Shared by the list and the order page.
Future<void> cancelOrderWithConfirm(
  BuildContext context,
  WidgetRef ref,
  String orderId,
) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l.cancelOrderConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l.keepOrder,
            style: const TextStyle(color: AppColors.body),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l.cancelOrder,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(ordersRepositoryProvider).cancelOrder(orderId);
    if (context.mounted) showAppSnack(context, l.orderCancelledMsg);
  } on CheckoutError catch (e) {
    if (context.mounted) {
      showAppSnack(context, checkoutErrorText(l, e.failure), error: true);
    }
  } finally {
    ref.invalidate(myOrdersProvider);
    ref.invalidate(myOrderProvider(orderId));
  }
}
