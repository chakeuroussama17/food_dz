import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_repository.dart';
import '../data/periods.dart';
import '../widgets/admin_widgets.dart';

/// Totals for a period + per-restaurant table + things to do.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  late DateRange _range = statsRange(StatsPeriod.thisMonth, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String money(int v) => formatDzd(v, lang);
    final stats = ref.watch(adminStatsProvider(_range));
    final byRestaurant = ref.watch(adminStatsByRestaurantProvider(_range));

    return AdminScaffold(
      section: AdminSection.dashboard,
      title: l.dashboard,
      actions: [
        IconButton(
          tooltip: l.retry,
          onPressed: () {
            ref.invalidate(adminStatsProvider(_range));
            ref.invalidate(adminStatsByRestaurantProvider(_range));
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          PeriodPicker(
            range: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 16),
          AsyncBody(
            value: stats,
            onRetry: () => ref.invalidate(adminStatsProvider(_range)),
            builder: (s) => LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 800 ? 4 : 2;
                final w = (c.maxWidth - (cols - 1) * 12) / cols;
                Widget tile(Widget t) => SizedBox(width: w, child: t);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    tile(
                      AdminStatTile(
                        label: l.statCommission,
                        value: money(s.commission),
                        icon: Icons.payments_outlined,
                        highlight: true,
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statSales,
                        value: money(s.foodTotal),
                        icon: Icons.restaurant_outlined,
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statDelivered,
                        value: '${s.deliveredOrders}',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statDeliveryFees,
                        value: money(s.deliveryFees),
                        icon: Icons.delivery_dining_outlined,
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statCancelled,
                        value: '${s.cancelledOrders}',
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statActive,
                        value: '${s.activeOrders}',
                        icon: Icons.timelapse_rounded,
                        onTap: () => context.go('/admin/orders'),
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statPending,
                        value: '${s.pendingRestaurants}',
                        icon: Icons.hourglass_top_rounded,
                        onTap: () => context.go('/admin/restaurants'),
                      ),
                    ),
                    tile(
                      AdminStatTile(
                        label: l.statUnbilled,
                        value: money(s.unbilledCommission),
                        icon: Icons.request_quote_outlined,
                        onTap: () => context.go('/admin/receipts'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.byRestaurant,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          AsyncBody(
            value: byRestaurant,
            onRetry: () =>
                ref.invalidate(adminStatsByRestaurantProvider(_range)),
            builder: (rows) => AdminCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l.restaurant)),
                    DataColumn(label: Text(l.statDelivered), numeric: true),
                    DataColumn(label: Text(l.statSales), numeric: true),
                    DataColumn(label: Text(l.statCommission), numeric: true),
                  ],
                  rows: [
                    for (final r in rows)
                      DataRow(
                        cells: [
                          DataCell(Text(r.name)),
                          DataCell(Text('${r.deliveredOrders}')),
                          DataCell(Text(money(r.foodTotal))),
                          DataCell(
                            Text(
                              money(r.commission),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
