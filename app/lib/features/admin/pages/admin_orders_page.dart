import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import '../data/periods.dart';
import '../widgets/admin_widgets.dart';
import '../data/admin_drivers.dart';
import '../../../core/widgets/app_image.dart';

/// All orders with period / restaurant / status filters. Tap an order to
/// see its items.
class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  static const _page = 50;
  late DateRange _range = statsRange(StatsPeriod.last7, DateTime.now());
  String? _restaurantId;
  String? _status;
  final _orders = <AdminOrder>[];
  bool _loading = false;
  bool _more = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _orders.clear();
    _more = true;
    await _load();
  }

  Future<void> _load() async {
    if (_loading || !_more) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await ref
          .read(adminRepositoryProvider)
          .orders(
            _range,
            restaurantId: _restaurantId,
            status: _status,
            limit: _page,
            offset: _orders.length,
          );
      if (!mounted) return;
      setState(() {
        _orders.addAll(batch);
        _more = batch.length == _page;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showItems(AdminOrder o) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: FutureBuilder<List<AdminOrderItem>>(
            future: ref.read(adminRepositoryProvider).orderItems(o.id),
            builder: (ctx, snap) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '#${o.code} · ${o.restaurantName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${o.customerName} · ${o.customerPhone} · ${o.area}',
                  style: const TextStyle(color: AppColors.body),
                ),
                const SizedBox(height: 12),
                Text(l.itemsTitle, style: Theme.of(ctx).textTheme.labelMedium),
                if (!snap.hasData)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  for (final i in snap.data!)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${i.quantity} × ${i.name}'),
                      trailing: Text(formatDzd(i.lineTotal, lang)),
                    ),
                const Divider(),
                _kv(l.subtotal, formatDzd(o.foodTotal, lang)),
                _kv(l.deliveryFee, formatDzd(o.deliveryFee, lang)),
                _kv(l.total, formatDzd(o.total, lang), strong: true),
                if (o.commissionAmount != null)
                  _kv(l.statCommission, formatDzd(o.commissionAmount!, lang)),
                if (o.statementNumber != null)
                  _kv(l.receipts, o.statementNumber!),
                _DeliveryInfo(
                  orderId: o.id,
                  delivered: o.status == 'delivered',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: const TextStyle(color: AppColors.body)),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final restaurants = ref.watch(adminRestaurantsProvider).value ?? const [];
    final fmt = DateFormat('dd/MM HH:mm');

    return AdminScaffold(
      section: AdminSection.orders,
      title: l.orders,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          PeriodPicker(
            range: _range,
            onChanged: (r) {
              setState(() => _range = r);
              _reload();
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DropdownButton<String?>(
                value: _restaurantId,
                hint: Text(l.allRestaurants),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.allRestaurants)),
                  for (final r in restaurants)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) {
                  setState(() => _restaurantId = v);
                  _reload();
                },
              ),
              DropdownButton<String?>(
                value: _status,
                hint: Text(l.allStatuses),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.allStatuses)),
                  for (final s in orderStatuses)
                    DropdownMenuItem(
                      value: s,
                      child: Text(orderStatusLabel(l, s)),
                    ),
                ],
                onChanged: (v) {
                  setState(() => _status = v);
                  _reload();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            AsyncBody<void>(
              value: AsyncError(_error!, StackTrace.empty),
              builder: (_) => const SizedBox.shrink(),
              onRetry: _reload,
            )
          else if (_orders.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l.noOrders,
                  style: const TextStyle(color: AppColors.body),
                ),
              ),
            )
          else
            AdminCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final o in _orders)
                    ListTile(
                      onTap: () => _showItems(o),
                      title: Text(
                        '#${o.code} · ${o.restaurantName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${fmt.format(o.placedAt.toLocal())} · ${o.customerName}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatDzd(o.total, lang)),
                          const SizedBox(height: 4),
                          Pill(
                            orderStatusLabel(l, o.status),
                            color: orderStatusColor(o.status),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_more && _orders.isNotEmpty)
            TextButton(onPressed: _load, child: Text(l.loadMore)),
        ],
      ),
    );
  }
}

/// Driver, cash handover and delivery photo of one order.
class _DeliveryInfo extends ConsumerWidget {
  const _DeliveryInfo({required this.orderId, required this.delivered});
  final String orderId;
  final bool delivered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<AdminOrderDelivery>(
      future: ref.read(adminDriversRepositoryProvider).orderDelivery(orderId),
      builder: (context, snap) {
        final d = snap.data;
        if (d == null || d.driverName == null) return const SizedBox.shrink();
        final cash = d.cashConfirmedAt != null
            ? (l.cashStatusConfirmed, AppColors.success)
            : d.cashHandedAt != null
            ? (l.cashStatusHanded, AppColors.primary)
            : (l.cashStatusPending, AppColors.danger);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            Text(
              l.driverLabel('${d.driverName} · ${d.driverPhone ?? ''}'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (delivered) ...[
              const SizedBox(height: 6),
              Text(cash.$1, style: TextStyle(color: cash.$2)),
            ],
            if (d.photoUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                l.proofOfDelivery,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              AppImage(url: d.photoUrl, width: double.infinity, height: 240),
            ],
          ],
        );
      },
    );
  }
}
