import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../l10n/app_localizations.dart';
import '../../features/restaurant_owner/data/owner_orders_repository.dart';
import '../../features/restaurant_owner/insights/insights.dart';
import '../../features/restaurant_owner/pages/owner_orders_page.dart'
    show ownerActions, CancelRequestBanner;
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

DateTime _day(DateTime t, [int add = 0]) =>
    DateTime(t.year, t.month, t.day + add);

/// Saturday that starts the (Algerian) week of [t].
DateTime weekStart(DateTime t) => _day(t, -Insights.weekdayIndex(t));

enum _Week { current, last }

class PortalDashboardPage extends ConsumerStatefulWidget {
  const PortalDashboardPage({super.key});

  @override
  ConsumerState<PortalDashboardPage> createState() =>
      _PortalDashboardPageState();
}

class _PortalDashboardPageState extends ConsumerState<PortalDashboardPage> {
  _Week _week = _Week.current;
  bool _compare = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ids = ref.watch(portalOutletIdsProvider).value;
    final outlets = ref.watch(portalOutletsProvider).value ?? const [];
    final now = DateTime.now();
    final sat = weekStart(now);
    // Today + three weeks (this, last, and the one before to compare).
    final todayRange = ReportRange(_day(now), _day(now, 1), outlets: ids);
    final weeksRange = ReportRange(_day(sat, -14), _day(sat, 7), outlets: ids);
    final today = ids == null
        ? null
        : ref.watch(ownerReportProvider(todayRange)).value;
    final weeksAsync = ids == null
        ? null
        : ref.watch(ownerReportProvider(weeksRange));
    final weeks = weeksAsync?.value;
    final updated = ref.watch(portalRefreshedProvider);

    final todayI = today == null
        ? null
        : Insights.compute(today, _day(now), _day(now, 1));
    final from = _week == _Week.current ? sat : _day(sat, -7);
    // The current week stops today (no flat line for days to come).
    final end = _week == _Week.current ? _day(now, 1) : _day(from, 7);
    final week = weeks == null ? null : Insights.compute(weeks, from, end);
    final before = weeks == null
        ? null
        : Insights.compute(
            weeks,
            _day(from, -7),
            _day(from, -7 + end.difference(from).inDays),
          );
    final shown = ids?.toSet() ?? const <String>{};
    final closed = outlets
        .where((r) => shown.contains(r.id) && r.isActive && !r.isOpen)
        .length;

    return PortalPage(
      title: l.dashboard,
      subtitle: l.dashboardSubtitle,
      actions: const [OutletSelector()],
      children: [
        EqualGrid(
          perRow: (w) => w > 900 ? 4 : (w > 520 ? 2 : 1),
          children: [
            PStat(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF3B82F6),
              value: todayI == null ? '--' : '${todayI.orders}',
              label: l.ordersToday,
            ),
            PStat(
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
              value: todayI == null
                  ? '--'
                  : '${todayI.rejected + todayI.cancelled}',
              label: l.cancelledToday,
            ),
            PStat(
              icon: Icons.lock_clock_outlined,
              color: const Color(0xFFF59E0B),
              value: '$closed',
              label: l.closedOutletsNow,
            ),
            PStat(
              icon: Icons.payments_outlined,
              color: AppColors.success,
              value: todayI == null ? '--' : formatDzd(todayI.sales, lang),
              label: l.salesToday,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l.updatedAt(DateFormat('HH:mm:ss').format(updated)),
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            IconButton(
              tooltip: l.retry,
              onPressed: () => refreshPortal(ref),
              icon: Icon(Icons.refresh_rounded, color: AppColors.muted),
            ),
          ],
        ),
        const _WaitingOrders(),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l.businessSummary,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch.adaptive(
                  value: _compare,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _compare = v),
                ),
                Text(l.comparison, style: TextStyle(color: AppColors.body)),
              ],
            ),
            Segmented<_Week>(
              items: _Week.values,
              selected: _week,
              labelOf: (w) => w == _Week.current ? l.thisWeek : l.lastWeek,
              onSelected: (w) => setState(() => _week = w),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (week == null && (weeksAsync?.hasError ?? false))
          PCard(
            child: Center(
              child: TextButton.icon(
                onPressed: () => refreshPortal(ref),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.loadError),
              ),
            ),
          )
        else if (week == null)
          const SizedBox(
            height: 260,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          ResponsiveRow(
            children: [
              _SummaryCard(
                title: l.orders,
                numbers: [
                  (l.totalLabel, '${week.orders}'),
                  (l.cancelledLabel, '${week.rejected + week.cancelled}'),
                ],
                change: percentChange(week.orders, before!.orders),
                values: [for (final d in week.days) d.orders.toDouble()],
                compare: _compare
                    ? [for (final d in before.days) d.orders.toDouble()]
                    : null,
                days: [for (final d in week.days) d.day],
                tooltip: (i) =>
                    '${DateFormat('E dd/MM', lang).format(week.days[i].day)}\n'
                    '${l.ordersCount(week.days[i].orders)}'
                    '${_compare ? '  ·  ${before.days[i].orders}' : ''}',
                color: const Color(0xFF3B82F6),
              ),
              _SummaryCard(
                title: l.kpiSales,
                numbers: [(l.totalLabel, formatDzd(week.sales, lang))],
                change: percentChange(week.sales, before.sales),
                values: [for (final d in week.days) d.sales.toDouble()],
                compare: _compare
                    ? [for (final d in before.days) d.sales.toDouble()]
                    : null,
                days: [for (final d in week.days) d.day],
                tooltip: (i) =>
                    '${DateFormat('E dd/MM', lang).format(week.days[i].day)}\n'
                    '${formatDzd(week.days[i].sales, lang)}'
                    '${_compare ? '  ·  ${formatDzd(before.days[i].sales, lang)}' : ''}',
                color: AppColors.primary,
              ),
            ],
          ),
        if (week != null && week.topDishes.isNotEmpty) ...[
          const SizedBox(height: 16),
          PCard(
            title: l.topDishesTitle,
            action: TextButton(
              onPressed: () => context.go('/reports'),
              child: Text(l.seeAll),
            ),
            child: Column(
              children: [
                for (final d in week.topDishes.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          l.soldTimes(d.quantity),
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 110,
                          child: Text(
                            formatDzd(d.sales, lang),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.numbers,
    required this.values,
    required this.days,
    required this.tooltip,
    required this.color,
    this.compare,
    this.change,
  });

  final String title;
  final List<(String, String)> numbers;
  final List<double> values;
  final List<double>? compare;
  final List<DateTime> days;
  final String Function(int) tooltip;
  final Color color;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return PCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (label, value) in numbers)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          if (change != null &&
                              change != 0 &&
                              label == numbers.first.$1) ...[
                            const SizedBox(width: 10),
                            ChangeChip(change: change!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LineChart(
            values: values,
            compare: compare,
            labels: [for (final d in days) DateFormat('E', lang).format(d)],
            tooltip: tooltip,
            color: color,
          ),
          if (compare != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              children: [
                LegendDot(color: color, label: title),
                LegendDot(
                  color: AppColors.muted,
                  label: l.previousPeriod,
                  dashed: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// New orders of all selected outlets, answerable right here.
class _WaitingOrders extends ConsumerWidget {
  const _WaitingOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final active = ref.watch(portalActiveOrdersProvider).value;
    final waiting =
        active
            ?.where((o) => o.status == 'placed' || o.cancelRequestPending)
            .toList() ??
        [];
    final running = active?.where((o) => o.isRunning).length ?? 0;
    return PCard(
      title: l.waitingOrders,
      action: TextButton.icon(
        onPressed: () => context.go('/orders'),
        icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
        label: Text('${l.runningOrders}: $running'),
      ),
      child: waiting.isEmpty
          ? Text(l.noWaitingOrders, style: TextStyle(color: AppColors.muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in waiting)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${o.code}'
                                '${o.restaurantName.isEmpty ? '' : '  ·  ${o.restaurantName}'}'
                                '  ·  ${DateFormat('HH:mm').format(o.placedAt)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${o.summary}  ·  ${formatDzd(o.total, lang)}',
                                style: TextStyle(color: AppColors.body),
                              ),
                              if (o.cancelRequestPending) ...[
                                const SizedBox(height: 8),
                                CancelRequestBanner(order: o),
                              ],
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          children: ownerActions(context, ref, o),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
