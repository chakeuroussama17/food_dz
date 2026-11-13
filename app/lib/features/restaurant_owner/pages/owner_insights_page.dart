import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../data/owner_orders_repository.dart';
import '../data/owner_repository.dart';
import '../insights/charts.dart';
import '../insights/insights.dart';
import '../widgets/owner_widgets.dart';
import '../widgets/period_chips.dart';

/// Trends: KPIs against the previous period, sales per day, busiest hours
/// and days, best sellers, order outcomes and business tips.
class OwnerInsightsPage extends ConsumerStatefulWidget {
  const OwnerInsightsPage({super.key});

  @override
  ConsumerState<OwnerInsightsPage> createState() => _OwnerInsightsPageState();
}

class _OwnerInsightsPageState extends ConsumerState<OwnerInsightsPage> {
  Period _period = Period.d7;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cur = _period.range(DateTime.now());
    final days = cur.to.difference(cur.from).inDays;
    // One call for this period and the one before (for the % changes).
    final fetch = ReportRange(
      DateTime(cur.from.year, cur.from.month, cur.from.day - days),
      cur.to,
    );
    final data = ref.watch(ownerReportProvider(fetch));
    final prep = ref.watch(myRestaurantProvider).value?.prepMinutes ?? 20;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.insights),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l.insights,
                  showBack: false,
                  trailing: IconButton(
                    tooltip: l.ordersTable,
                    onPressed: () => context.push('/restaurant/orders/table'),
                    icon: Icon(
                      Icons.table_chart_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                SmallChips<Period>(
                  items: const [Period.d7, Period.d30, Period.d90],
                  selected: _period,
                  labelOf: (p) => p.label(l),
                  onSelected: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: data.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.invalidate(ownerReportProvider(fetch)),
                        child: Text(l.retry),
                      ),
                    ),
                    data: (rows) {
                      final now = Insights.compute(rows, cur.from, cur.to);
                      final before = Insights.compute(
                        rows,
                        fetch.from,
                        cur.from,
                      );
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.refresh(ownerReportProvider(fetch).future),
                        child: _Body(
                          now: now,
                          before: before,
                          days: days,
                          tips: tipsFor(now, before, announcedPrep: prep),
                        ),
                      );
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

class _Body extends StatelessWidget {
  const _Body({
    required this.now,
    required this.before,
    required this.days,
    required this.tips,
  });

  final Insights now;
  final Insights before;
  final int days;
  final List<Tip> tips;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final rate = now.acceptanceRate;
    final rateBefore = before.acceptanceRate;
    final dayLabel = DateFormat(days <= 7 ? 'E' : 'd/M', lang);
    final every = days <= 7 ? 1 : (days <= 31 ? 5 : 15);
    final weekdayNames = [
      // 2026-11-14 is a Saturday: index 0 = Saturday.
      for (var i = 0; i < 7; i++)
        DateFormat.E(lang).format(DateTime(2026, 11, 14 + i)),
    ];
    String hour(int h) => '${h.toString().padLeft(2, '0')}:00';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          l.comparedPrevious(days),
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        _Grid(
          children: [
            KpiTile(
              icon: Icons.payments_outlined,
              label: l.kpiSales,
              value: formatDzd(now.sales, lang),
              change: percentChange(now.sales, before.sales),
            ),
            KpiTile(
              icon: Icons.receipt_long_outlined,
              label: l.kpiOrders,
              value: '${now.orders}',
              change: percentChange(now.orders, before.orders),
              tint: const Color(0xFF3B82F6),
            ),
            KpiTile(
              icon: Icons.shopping_basket_outlined,
              label: l.kpiAvgBasket,
              value: now.delivered == 0 ? '--' : formatDzd(now.avgBasket, lang),
              change: percentChange(now.avgBasket, before.avgBasket),
              tint: AppColors.success,
            ),
            KpiTile(
              icon: Icons.account_balance_wallet_outlined,
              label: l.kpiNet,
              value: formatDzd(now.net, lang),
              change: percentChange(now.net, before.net),
              tint: const Color(0xFF0EA5E9),
            ),
            KpiTile(
              icon: Icons.task_alt_rounded,
              label: l.kpiAcceptance,
              value: rate == null ? '--' : '${(rate * 100).round()}%',
              change: rate == null || rateBefore == null
                  ? null
                  : percentChange(rate, rateBefore),
              tint: const Color(0xFF14B8A6),
            ),
            KpiTile(
              icon: Icons.timer_outlined,
              label: l.kpiPrep,
              value: now.avgPrepMinutes == null
                  ? '--'
                  : l.minutesShort(now.avgPrepMinutes!),
              change:
                  now.avgPrepMinutes == null || before.avgPrepMinutes == null
                  ? null
                  : percentChange(now.avgPrepMinutes!, before.avgPrepMinutes!),
              lowerIsBetter: true,
              tint: const Color(0xFF8B5CF6),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (tips.isNotEmpty) ...[
          _Tips(tips: tips, weekdayNames: weekdayNames, hour: hour),
          const SizedBox(height: 16),
        ],
        InsightCard(
          title: l.salesChartTitle,
          subtitle: l.tapBarHint,
          child: BarChart(
            values: [for (final d in now.days) d.sales],
            labels: [
              for (var i = 0; i < now.days.length; i++)
                i % every == 0 ? dayLabel.format(now.days[i].day) : null,
            ],
            highlight: now.days.length - 1,
            valueText: (i) =>
                '${DateFormat('dd/MM').format(now.days[i].day)} · '
                '${formatDzd(now.days[i].sales, lang)} · '
                '${l.ordersCount(now.days[i].orders)}',
          ),
        ),
        const SizedBox(height: 16),
        InsightCard(
          title: l.hoursChartTitle,
          subtitle: now.peakHour == null
              ? null
              : '${hour(now.peakHour!)} – ${hour((now.peakHour! + 1) % 24)}',
          child: BarChart(
            height: 110,
            color: const Color(0xFF8B5CF6),
            values: now.byHour,
            labels: [for (var h = 0; h < 24; h++) h % 3 == 0 ? '$h' : null],
            highlight: now.peakHour,
            valueText: (h) => '${hour(h)} · ${l.ordersCount(now.byHour[h])}',
          ),
        ),
        const SizedBox(height: 16),
        InsightCard(
          title: l.weekdayChartTitle,
          child: BarChart(
            height: 100,
            color: const Color(0xFF3B82F6),
            values: now.byWeekday,
            labels: weekdayNames,
            valueText: (d) =>
                '${weekdayNames[d]} · ${l.ordersCount(now.byWeekday[d])}',
          ),
        ),
        const SizedBox(height: 16),
        InsightCard(
          title: l.topDishesTitle,
          child: now.topDishes.isEmpty
              ? Text(l.noOrdersPeriod, style: TextStyle(color: AppColors.muted))
              : _TopDishes(dishes: now.topDishes.take(5).toList()),
        ),
        const SizedBox(height: 16),
        InsightCard(
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
      ],
    );
  }
}

/// Two columns on phones, three on wide screens.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final per = c.maxWidth > 600 ? 3 : 2;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += per) {
        if (i > 0) rows.add(const SizedBox(height: 12));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + per; j++) ...[
                  if (j > i) const SizedBox(width: 12),
                  Expanded(
                    child: j < children.length ? children[j] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return Column(children: rows);
    },
  );
}

class _TopDishes extends StatelessWidget {
  const _TopDishes({required this.dishes});
  final List<DishStat> dishes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final max = dishes.first.quantity;
    const medals = ['🥇', '🥈', '🥉'];
    return Column(
      children: [
        for (var i = 0; i < dishes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    i < 3 ? medals[i] : '${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: i < 3 ? 20 : 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dishes[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            formatDzd(dishes[i].sales, lang),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: dishes[i].quantity / max,
                                ),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 8,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.field,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l.soldTimes(dishes[i].quantity),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
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

class _Tips extends StatelessWidget {
  const _Tips({
    required this.tips,
    required this.weekdayNames,
    required this.hour,
  });

  final List<Tip> tips;
  final List<String> weekdayNames;
  final String Function(int) hour;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    (IconData, Color, String) view(Tip t) => switch (t.kind) {
      TipKind.salesUp => (
        Icons.trending_up_rounded,
        AppColors.success,
        l.tipSalesUp(t.number.toInt()),
      ),
      TipKind.salesDown => (
        Icons.trending_down_rounded,
        AppColors.danger,
        l.tipSalesDown(t.number.toInt()),
      ),
      TipKind.refusals => (
        Icons.block_rounded,
        AppColors.danger,
        l.tipRefusals(t.number.toInt(), formatDzd(t.amount, lang)),
      ),
      TipKind.slowResponse => (
        Icons.notifications_active_outlined,
        AppColors.primary,
        l.tipSlowResponse(t.number.toInt()),
      ),
      TipKind.slowPrep => (
        Icons.timer_outlined,
        const Color(0xFF8B5CF6),
        l.tipSlowPrep(t.number.toInt(), t.amount),
      ),
      TipKind.peakHour => (
        Icons.local_fire_department_outlined,
        AppColors.primary,
        l.tipPeakHour(hour(t.number.toInt()), t.amount),
      ),
      TipKind.topDish => (
        Icons.star_outline_rounded,
        const Color(0xFFF59E0B),
        l.tipTopDish(t.text, t.number.toInt()),
      ),
      TipKind.quietDay => (
        Icons.event_available_outlined,
        const Color(0xFF3B82F6),
        l.tipQuietDay(weekdayNames[t.number.toInt()]),
      ),
      TipKind.noOrders => (
        Icons.lightbulb_outline_rounded,
        AppColors.primary,
        l.tipNoOrders,
      ),
    };
    return InsightCard(
      title: l.tipsTitle,
      child: Column(
        children: [
          for (final t in tips)
            Builder(
              builder: (_) {
                final (icon, color, text) = view(t);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: AppColors.isDark ? .16 : .08,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
