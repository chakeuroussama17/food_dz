import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/files/file_output.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/snack.dart';
import '../../features/orders/order_status.dart';
import '../../features/restaurant_owner/data/owner_orders_repository.dart';
import '../../features/restaurant_owner/insights/charts.dart' show OutcomeBar;
import '../../features/restaurant_owner/insights/insights.dart';
import '../../features/restaurant_owner/insights/orders_csv.dart' show csvBytes;
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../report_math.dart';
import '../widgets/portal_widgets.dart';

enum _Tf { d7, d30, prevMonth, custom }

enum _Tab { sales, operations, customers }

DateTime _day(DateTime t, [int add = 0]) =>
    DateTime(t.year, t.month, t.day + add);

class PortalReportsPage extends ConsumerStatefulWidget {
  const PortalReportsPage({super.key});

  @override
  ConsumerState<PortalReportsPage> createState() => _PortalReportsPageState();
}

class _PortalReportsPageState extends ConsumerState<PortalReportsPage> {
  _Tf _tf = _Tf.d7;
  DateTimeRange? _custom;
  _Tab _tab = _Tab.sales;

  (DateTime, DateTime) get _period {
    final now = DateTime.now();
    return switch (_tf) {
      _Tf.d7 => (_day(now, -6), _day(now, 1)),
      _Tf.d30 => (_day(now, -29), _day(now, 1)),
      _Tf.prevMonth => previousMonth(now),
      _Tf.custom => (_day(_custom!.start), _day(_custom!.end, 1)),
    };
  }

  Future<void> _pick(_Tf t) async {
    if (t != _Tf.custom) return setState(() => _tf = t);
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (r == null) return;
    setState(() {
      _custom = r;
      _tf = _Tf.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ids = ref.watch(portalOutletIdsProvider).value;
    final (from, to) = _period;
    final days = to.difference(from).inDays;
    // This period and the one before (for the % changes).
    final range = ReportRange(_day(from, -days), to, outlets: ids);
    final data = ids == null
        ? const AsyncLoading<List<OwnerOrder>>()
        : ref.watch(ownerReportProvider(range));
    // Customers: 6 months back to tell new from returning.
    final history = ids == null || _tab != _Tab.customers
        ? null
        : ref.watch(
            ownerReportProvider(
              ReportRange(_day(from, -180), to, outlets: ids),
            ),
          );

    return PortalPage(
      title: l.navReports,
      subtitle: l.reportsSubtitle,
      actions: [
        Segmented<_Tf>(
          items: _Tf.values,
          selected: _tf,
          labelOf: (t) => switch (t) {
            _Tf.d7 => l.range7,
            _Tf.d30 => l.range30,
            _Tf.prevMonth => l.previousMonth,
            _Tf.custom =>
              _custom == null
                  ? l.rangeCustom
                  : '${DateFormat('dd/MM').format(_custom!.start)} – '
                        '${DateFormat('dd/MM').format(_custom!.end)}',
          },
          onSelected: _pick,
        ),
        const OutletSelector(),
      ],
      children: [
        _Tabs(selected: _tab, onSelected: (t) => setState(() => _tab = t)),
        const SizedBox(height: 20),
        data.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(64),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(ownerReportProvider(range)),
              child: Text(l.retry),
            ),
          ),
          data: (rows) {
            final now = Insights.compute(rows, from, to);
            final before = Insights.compute(rows, range.from, from);
            return switch (_tab) {
              _Tab.sales => _SalesTab(rows: rows, now: now, before: before),
              _Tab.operations => _OperationsTab(
                rows: rows,
                now: now,
                before: before,
              ),
              _Tab.customers => _CustomersTab(
                rows: history?.value,
                from: from,
                to: to,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});
  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final t in _Tab.values)
            InkWell(
              onTap: () => onSelected(t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: t == selected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  switch (t) {
                    _Tab.sales => l.tabSales,
                    _Tab.operations => l.tabOperations,
                    _Tab.customers => l.tabCustomers,
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t == selected ? AppColors.primary : AppColors.body,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid of [PStat]-like tiles, 2 to 4 per row.
class _Kpis extends StatelessWidget {
  const _Kpis({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => EqualGrid(
    perRow: (w) => w > 900 ? children.length.clamp(1, 5) : (w > 520 ? 2 : 1),
    children: children,
  );
}

Future<void> _download(
  BuildContext context,
  WidgetRef ref,
  String csv,
  String name,
) async {
  final l = AppLocalizations.of(context);
  try {
    await ref.read(fileOutputProvider).save(csvBytes(csv), name, 'text/csv');
    if (context.mounted) showAppSnack(context, l.csvReady);
  } catch (_) {
    if (context.mounted) showAppSnack(context, l.errGeneric, error: true);
  }
}

String _stamp(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

// ---------------------------------------------------------------- Sales

class _SalesTab extends ConsumerStatefulWidget {
  const _SalesTab({
    required this.rows,
    required this.now,
    required this.before,
  });

  final List<OwnerOrder> rows;
  final Insights now;
  final Insights before;

  @override
  ConsumerState<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends ConsumerState<_SalesTab> {
  bool _orders = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = widget.now;
    final before = widget.before;
    final dayLabel = DateFormat(now.days.length <= 7 ? 'E' : 'd/M', lang);
    final grid = salesByHourAndDay(widget.rows, now.from, now.to);
    // Show the hours that matter: from the first to the last busy hour.
    var first = grid.indexWhere((r) => r.any((v) => v > 0));
    var last = grid.lastIndexWhere((r) => r.any((v) => v > 0));
    if (first < 0) (first, last) = (10, 23);
    final hours = [for (var h = first; h <= last; h++) h];
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(lang).format(DateTime(2026, 11, 14 + i)),
    ];
    final share = now.sales == 0
        ? <double>[]
        : [for (final d in now.topDishes) d.sales * 100 / now.sales];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kpis(
          children: [
            PStat(
              icon: Icons.payments_outlined,
              color: AppColors.primary,
              value: formatDzd(now.sales, lang),
              label: l.kpiSales,
              change: percentChange(now.sales, before.sales),
            ),
            PStat(
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF3B82F6),
              value: '${now.orders}',
              label: l.kpiOrders,
              change: percentChange(now.orders, before.orders),
            ),
            PStat(
              icon: Icons.shopping_basket_outlined,
              color: AppColors.success,
              value: now.delivered == 0 ? '--' : formatDzd(now.avgBasket, lang),
              label: l.kpiAvgBasket,
              change: percentChange(now.avgBasket, before.avgBasket),
            ),
            PStat(
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF0EA5E9),
              value: formatDzd(now.net, lang),
              label: l.kpiNet,
              change: percentChange(now.net, before.net),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PCard(
          title: l.salesChartTitle,
          subtitle: l.salesByDayHint,
          action: TextButton.icon(
            onPressed: () => _download(
              context,
              ref,
              dailyCsv(now, widget.rows, [
                l.csvDate,
                l.kpiOrders,
                l.statusDelivered,
                l.csvFood,
                l.csvCommission,
                l.csvNet,
              ]),
              'sales_${_stamp(now.from)}_${_stamp(now.to.subtract(const Duration(days: 1)))}.csv',
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l.downloadReport),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Segmented<bool>(
                    items: const [false, true],
                    selected: _orders,
                    labelOf: (o) => o ? l.kpiOrders : l.kpiSales,
                    onSelected: (o) => setState(() => _orders = o),
                  ),
                  const Spacer(),
                  LegendDot(
                    color: AppColors.primary,
                    label:
                        '${dayLabel.format(now.from)} – '
                        '${dayLabel.format(now.to.subtract(const Duration(days: 1)))}',
                  ),
                  const SizedBox(width: 16),
                  LegendDot(
                    color: AppColors.muted,
                    label: l.previousPeriod,
                    dashed: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LineChart(
                height: 260,
                values: [
                  for (final d in now.days)
                    (_orders ? d.orders : d.sales).toDouble(),
                ],
                compare: before.days.length == now.days.length
                    ? [
                        for (final d in before.days)
                          (_orders ? d.orders : d.sales).toDouble(),
                      ]
                    : null,
                labels: [for (final d in now.days) dayLabel.format(d.day)],
                tooltip: (i) {
                  final d = now.days[i];
                  return '${DateFormat('E dd/MM', lang).format(d.day)}\n'
                      '${formatDzd(d.sales, lang)} · ${l.ordersCount(d.orders)}';
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PCard(
          title: l.salesByHour,
          subtitle: l.salesByHourHint,
          action: TextButton.icon(
            onPressed: () {
              final b = StringBuffer(
                [l.weekdayChartTitle, l.csvTime, l.csvFood].join(';'),
              );
              for (var c = 0; c < 7; c++) {
                for (final h in hours) {
                  b.write('\r\n${weekdays[c]};$h:00;${grid[h][c].round()}');
                }
              }
              _download(
                context,
                ref,
                b.toString(),
                'sales_by_hour_${_stamp(now.from)}.csv',
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l.downloadReport),
          ),
          child: Heatmap(
            values: [for (final h in hours) grid[h]],
            rows: [for (final h in hours) '${'$h'.padLeft(2, '0')}:00'],
            columns: weekdays,
            tooltip: (r, c) =>
                '${weekdays[c]} ${'${hours[r]}'.padLeft(2, '0')}:00 · '
                '${formatDzd(grid[hours[r]][c].round(), lang)}',
          ),
        ),
        const SizedBox(height: 16),
        PCard(
          title: l.topDishesTitle,
          child: now.topDishes.isEmpty
              ? Text(l.noOrdersPeriod, style: TextStyle(color: AppColors.muted))
              : DataTable(
                  headingRowHeight: 40,
                  horizontalMargin: 0,
                  columns: [
                    const DataColumn(label: Text('#')),
                    DataColumn(label: Text(l.csvItems)),
                    DataColumn(
                      label: Text(l.soldTimes(0).replaceAll('0', '').trim()),
                      numeric: true,
                    ),
                    DataColumn(label: Text(l.kpiSales), numeric: true),
                    const DataColumn(label: Text('%'), numeric: true),
                  ],
                  rows: [
                    for (var i = 0; i < now.topDishes.length && i < 10; i++)
                      DataRow(
                        cells: [
                          DataCell(Text('${i + 1}')),
                          DataCell(Text(now.topDishes[i].name)),
                          DataCell(Text('${now.topDishes[i].quantity}')),
                          DataCell(
                            Text(formatDzd(now.topDishes[i].sales, lang)),
                          ),
                          DataCell(
                            Text(
                              share.isEmpty
                                  ? '--'
                                  : '${share[i].toStringAsFixed(0)}%',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Operations

class _OperationsTab extends StatelessWidget {
  const _OperationsTab({
    required this.rows,
    required this.now,
    required this.before,
  });

  final List<OwnerOrder> rows;
  final Insights now;
  final Insights before;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    double? rate(Insights i) =>
        i.orders == 0 ? null : (i.rejected + i.cancelled) / i.orders;
    String pct(double? v) => v == null ? '--' : '${(v * 100).round()}%';
    String response(double? m) => m == null
        ? '--'
        : m < 2
        ? l.secondsShort((m * 60).round())
        : l.minutesShort(m.round());
    final why = reasons(
      rows,
      now.from,
      now.to,
      (r) => r.isEmpty ? '—' : rejectReasonText(l, r),
    );
    final maxWhy = why.isEmpty ? 1 : why.first.$2;
    final prep = prepByDay(rows, now.from, now.to);
    final dayLabel = DateFormat(now.days.length <= 7 ? 'E' : 'd/M', lang);
    final cancelNow = rate(now);
    final cancelBefore = rate(before);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kpis(
          children: [
            PStat(
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF14B8A6),
              value: pct(now.acceptanceRate),
              label: l.kpiAcceptance,
              change:
                  now.acceptanceRate == null || before.acceptanceRate == null
                  ? null
                  : percentChange(now.acceptanceRate!, before.acceptanceRate!),
            ),
            PStat(
              icon: Icons.notifications_active_outlined,
              color: AppColors.primary,
              value: response(now.avgResponseMinutes),
              label: l.avgResponse,
              change:
                  now.avgResponseMinutes == null ||
                      before.avgResponseMinutes == null
                  ? null
                  : percentChange(
                      now.avgResponseMinutes!,
                      before.avgResponseMinutes!,
                    ),
              lowerIsBetter: true,
            ),
            PStat(
              icon: Icons.timer_outlined,
              color: const Color(0xFF8B5CF6),
              value: now.avgPrepMinutes == null
                  ? '--'
                  : l.minutesShort(now.avgPrepMinutes!),
              label: l.kpiPrep,
              change:
                  now.avgPrepMinutes == null || before.avgPrepMinutes == null
                  ? null
                  : percentChange(now.avgPrepMinutes!, before.avgPrepMinutes!),
              lowerIsBetter: true,
            ),
            PStat(
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
              value: pct(cancelNow),
              label: l.cancellationRate,
              change:
                  cancelNow == null || cancelBefore == null || cancelBefore == 0
                  ? null
                  : percentChange(cancelNow, cancelBefore),
              lowerIsBetter: true,
            ),
            PStat(
              icon: Icons.money_off_rounded,
              color: const Color(0xFFF59E0B),
              value: formatDzd(now.lostSales, lang),
              label: l.lostSales,
            ),
          ],
        ),
        const SizedBox(height: 16),
        PCard(
          title: l.outcomesTitle,
          subtitle: l.ordersCount(now.orders),
          child: OutcomeBar(
            segments: [
              (
                orderStatusLabel(l, 'delivered'),
                now.delivered,
                AppColors.success,
              ),
              (l.filterInProgress, now.inProgress, AppColors.primary),
              (orderStatusLabel(l, 'rejected'), now.rejected, AppColors.danger),
              (
                orderStatusLabel(l, 'cancelled'),
                now.cancelled,
                const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveRow(
          children: [
            PCard(
              title: l.refusalReasons,
              child: why.isEmpty
                  ? Text('—', style: TextStyle(color: AppColors.muted))
                  : Column(
                      children: [
                        for (final (reason, n) in why)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: TextStyle(color: AppColors.ink),
                                      ),
                                    ),
                                    Text(
                                      '$n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: n / maxWhy,
                                    minHeight: 8,
                                    color: AppColors.danger,
                                    backgroundColor: AppColors.field,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            PCard(
              title: l.prepByDay,
              child: LineChart(
                color: const Color(0xFF8B5CF6),
                values: [for (final p in prep) p ?? 0],
                labels: [for (final d in now.days) dayLabel.format(d.day)],
                tooltip: (i) =>
                    '${DateFormat('E dd/MM', lang).format(now.days[i].day)}\n'
                    '${prep[i] == null ? '--' : l.minutesShort(prep[i]!.round())}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Customers

class _CustomersTab extends StatelessWidget {
  const _CustomersTab({
    required this.rows,
    required this.from,
    required this.to,
  });

  /// Six months back to the end of the period (null while loading).
  final List<OwnerOrder>? rows;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = rows;
    if (all == null) {
      return const Padding(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final split = customerSplit(all, from, to);
    final total = split.newOrders + split.returningOrders;
    final areas = topAreas(all, from, to);
    final maxArea = areas.isEmpty ? 1 : areas.first.$2;
    const newColor = AppColors.primary;
    const backColor = Color(0xFF3B82F6);
    String pct(int n) => total == 0 ? '0%' : '${(n * 100 / total).round()}%';

    Widget big(int n, String label, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$n',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          LegendDot(color: color, label: label),
        ],
      ),
    );

    Widget advice(String title, String body) => PCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.diamond_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(height: 1.5, color: AppColors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PCard(
          title: l.newVsReturning,
          subtitle: l.newVsReturningHint,
          child: Wrap(
            spacing: 48,
            runSpacing: 24,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Donut(
                values: [
                  split.newOrders.toDouble(),
                  split.returningOrders.toDouble(),
                ],
                colors: const [newColor, backColor],
                size: 200,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${split.customers}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      l.uniqueCustomers,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  big(
                    split.returningOrders,
                    '${l.ordersFromReturning} (${pct(split.returningOrders)})',
                    backColor,
                  ),
                  big(
                    split.newOrders,
                    '${l.ordersFromNew} (${pct(split.newOrders)})',
                    newColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveRow(
          children: [
            advice(l.moreReturningTitle, l.moreReturningBody),
            advice(l.moreNewTitle, l.moreNewBody),
          ],
        ),
        const SizedBox(height: 16),
        PCard(
          title: l.topAreas,
          child: areas.isEmpty
              ? Text('—', style: TextStyle(color: AppColors.muted))
              : Column(
                  children: [
                    for (final (area, n) in areas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: Text(
                                area,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.ink),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: n / maxArea,
                                  minHeight: 10,
                                  color: backColor,
                                  backgroundColor: AppColors.field,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Text(
                                l.ordersCount(n),
                                textAlign: TextAlign.end,
                                style: TextStyle(color: AppColors.body),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
