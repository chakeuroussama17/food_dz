import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/owner_live.dart';
import '../data/owner_orders_repository.dart';
import '../data/owner_repository.dart';
import '../insights/charts.dart';
import '../insights/insights.dart';
import '../widgets/owner_widgets.dart';

/// Restaurant home: orange header with the open / closed switch, live
/// orders, today's numbers against yesterday, the last 7 days, money to
/// receive, shortcuts and menu health.
class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myRestaurantProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.dashboard),
      body: AsyncBody(
        value: mine,
        onRetry: () => ref.invalidate(myRestaurantsProvider),
        builder: (r) => r == null
            ? const SizedBox.shrink()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(myRestaurantsProvider);
                  ref.invalidate(myItemsProvider(r.id));
                  ref.invalidate(ownerActiveOrdersProvider);
                  ref.invalidate(ownerReportProvider);
                  ref.invalidate(ownerCashPendingProvider);
                },
                child: _Body(restaurant: r),
              ),
      ),
    );
  }
}

/// Start of the local day of [t], [days] later.
DateTime dayStart(DateTime t, [int days = 0]) =>
    DateTime(t.year, t.month, t.day + days);

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.restaurant});
  final OwnedRestaurant restaurant;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _switching = false;

  Future<void> _toggle(bool open) async {
    final l = AppLocalizations.of(context);
    setState(() => _switching = true);
    try {
      await ref
          .read(ownerRepositoryProvider)
          .setOpen(widget.restaurant.id, open);
      ref.invalidate(myRestaurantsProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = widget.restaurant;
    final items = ref.watch(myItemsProvider(r.id)).value;
    final active = ref.watch(ownerActiveOrdersProvider).value;
    String two(int? n) => n == null ? '--' : n.toString().padLeft(2, '0');
    final running = active?.where((o) => o.isRunning).length;
    final requests = active?.where((o) => o.isNew).length;

    // Last 8 days in one call: today, yesterday and the week chart.
    final now = DateTime.now();
    final range = ReportRange(dayStart(now, -7), dayStart(now, 1));
    final reportAsync = ref.watch(ownerReportProvider(range));
    final report = reportAsync.value;
    final today = report == null
        ? null
        : Insights.compute(report, dayStart(now), dayStart(now, 1));
    final yesterday = report == null
        ? null
        : Insights.compute(
            report,
            dayStart(now, -1),
            now.subtract(const Duration(days: 1)),
          );
    final week = report == null
        ? null
        : Insights.compute(report, dayStart(now, -6), dayStart(now, 1));

    final noPhoto = items?.where((i) => (i.photoUrl ?? '').isEmpty).length;
    final unavailable = items?.where((i) => !i.isAvailable).length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(restaurant: r, switching: _switching, onToggle: _toggle),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!r.isActive) ...[
                    const _PendingBanner(),
                    const SizedBox(height: 16),
                  ],
                  // Live orders.
                  Row(
                    children: [
                      Expanded(
                        child: _LiveTile(
                          value: two(requests),
                          label: l.orderRequests,
                          icon: Icons.notifications_active_outlined,
                          hot: (requests ?? 0) > 0,
                          onTap: () => context.go('/restaurant/orders?tab=new'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LiveTile(
                          value: two(running),
                          label: l.runningOrders,
                          icon: Icons.soup_kitchen_outlined,
                          onTap: () =>
                              context.go('/restaurant/orders?tab=running'),
                        ),
                      ),
                    ],
                  ),
                  // Numbers and shortcuts: managers and owners only.
                  if (r.canManage) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: l.todayTitle,
                      subtitle: l.compareYesterday,
                    ),
                    const SizedBox(height: 12),
                    _KpiGrid(
                      tiles: [
                        KpiTile(
                          icon: Icons.payments_outlined,
                          label: l.kpiSales,
                          value: today == null
                              ? '--'
                              : formatDzd(today.sales, lang),
                          change: today == null
                              ? null
                              : percentChange(today.sales, yesterday!.sales),
                          tint: AppColors.primary,
                        ),
                        KpiTile(
                          icon: Icons.receipt_long_outlined,
                          label: l.kpiOrders,
                          value: today == null ? '--' : '${today.orders}',
                          change: today == null
                              ? null
                              : percentChange(today.orders, yesterday!.orders),
                          tint: const Color(0xFF3B82F6),
                        ),
                        KpiTile(
                          icon: Icons.shopping_basket_outlined,
                          label: l.kpiAvgBasket,
                          value: today == null || today.delivered == 0
                              ? '--'
                              : formatDzd(today.avgBasket, lang),
                          change: today == null
                              ? null
                              : percentChange(
                                  today.avgBasket,
                                  yesterday!.avgBasket,
                                ),
                          tint: AppColors.success,
                        ),
                        KpiTile(
                          icon: Icons.timer_outlined,
                          label: l.kpiPrep,
                          value: today?.avgPrepMinutes == null
                              ? '--'
                              : l.minutesShort(today!.avgPrepMinutes!),
                          change:
                              today?.avgPrepMinutes == null ||
                                  yesterday?.avgPrepMinutes == null
                              ? null
                              : percentChange(
                                  today!.avgPrepMinutes!,
                                  yesterday!.avgPrepMinutes!,
                                ),
                          lowerIsBetter: true,
                          tint: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InsightCard(
                      title: l.last7Days,
                      subtitle: week == null
                          ? null
                          : '${formatDzd(week.sales, lang)} · '
                                '${l.ordersCount(week.orders)}',
                      action: TextButton(
                        onPressed: () => context.go('/restaurant/insights'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(l.seeInsights),
                      ),
                      child: week == null && reportAsync.hasError
                          ? SizedBox(
                              height: 120,
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () => ref.invalidate(
                                    ownerReportProvider(range),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(l.retry),
                                ),
                              ),
                            )
                          : week == null
                          ? const SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : BarChart(
                              height: 110,
                              values: [for (final d in week.days) d.sales],
                              labels: [
                                for (final d in week.days)
                                  DateFormat.E(lang).format(d.day),
                              ],
                              highlight: week.days.length - 1,
                              valueText: (i) =>
                                  '${formatDzd(week.days[i].sales, lang)} · '
                                  '${week.days[i].orders}',
                            ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const CashToReceiveCard(),
                  if (r.canManage) ...[
                    _SectionTitle(title: l.shortcuts),
                    const SizedBox(height: 12),
                    _Shortcuts(
                      items: [
                        (
                          Icons.table_chart_outlined,
                          l.ordersTable,
                          const Color(0xFF3B82F6),
                          () => context.push('/restaurant/orders/table'),
                        ),
                        (
                          Icons.insights_rounded,
                          l.insights,
                          const Color(0xFF8B5CF6),
                          () => context.go('/restaurant/insights'),
                        ),
                        (
                          Icons.request_quote_outlined,
                          l.myStatements,
                          AppColors.success,
                          () => context.push('/restaurant/statements'),
                        ),
                        (
                          Icons.add_circle_outline_rounded,
                          l.addItem,
                          AppColors.primary,
                          () => context.push('/restaurant/menu/new'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuHealth(
                      total: items?.length,
                      available: items == null
                          ? null
                          : items.length - unavailable!,
                      unavailable: unavailable ?? 0,
                      noPhoto: noPhoto ?? 0,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Orange gradient header: logo, area, name and the big open switch.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.restaurant,
    required this.switching,
    required this.onToggle,
  });

  final OwnedRestaurant restaurant;
  final bool switching;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = restaurant;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (r.area.isEmpty ? l.restaurant : r.area)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: .6,
                                fontWeight: FontWeight.w700,
                                color: Color(0xDDFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutletSwitcher(
                              name: r.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SoundButton(),
                      const SizedBox(width: 8),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.go('/restaurant/account'),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: AppImage(
                            url: r.logoUrl,
                            width: 46,
                            height: 46,
                            radius: 23,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      10,
                      8,
                      10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      children: [
                        _Pulse(on: r.isOpen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.isOpen ? l.openForOrders : l.closedForOrders,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.isActive
                                    ? l.openSwitchHint
                                    : l.cantOpenPending,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xE6FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: r.isOpen,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: .3,
                          ),
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          onChanged: !r.isActive || switching ? null : onToggle,
                        ),
                      ],
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

/// Mute / unmute the new-order chime.
class _SoundButton extends ConsumerWidget {
  const _SoundButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final off = ref.watch(
      ownerLiveProvider.select((s) => s.muted || !s.soundReady),
    );
    return IconButton(
      onPressed: () => ref.read(ownerLiveProvider.notifier).setMuted(!off),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .2),
      ),
      icon: Icon(
        off ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        color: Colors.white,
      ),
    );
  }
}

/// Glowing green dot when open; grey when closed.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final color = on ? const Color(0xFF34D399) : const Color(0xFFE5E7EB);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          if (on)
            BoxShadow(
              color: color.withValues(alpha: .7),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.pendingApprovalTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.pendingApprovalBody,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Counter of live orders (new requests turn orange).
class _LiveTile extends StatelessWidget {
  const _LiveTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
    this.hot = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final fg = hot ? Colors.white : AppColors.ink;
    return Material(
      color: hot ? AppColors.pill : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: hot ? AppColors.primary : fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hot
                            ? Colors.white.withValues(alpha: .85)
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: hot ? AppColors.primary : AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      if (subtitle != null)
        Text(subtitle!, style: TextStyle(fontSize: 13, color: AppColors.muted)),
    ],
  );
}

/// Two tiles per row on phones, four on wide screens.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final perRow = c.maxWidth > 560 ? 4 : 2;
      final rows = <Widget>[];
      for (var i = 0; i < tiles.length; i += perRow) {
        if (i > 0) rows.add(const SizedBox(height: 12));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + perRow; j++) ...[
                  if (j > i) const SizedBox(width: 12),
                  Expanded(
                    child: j < tiles.length ? tiles[j] : const SizedBox(),
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

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.items});
  final List<(IconData, String, Color, VoidCallback)> items;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (icon, label, color, onTap) in items)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: AppColors.isDark ? .22 : .12,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// Dishes count, plus what to fix (unavailable dishes, missing photos).
class _MenuHealth extends StatelessWidget {
  const _MenuHealth({
    required this.total,
    required this.available,
    required this.unavailable,
    required this.noPhoto,
  });

  final int? total;
  final int? available;
  final int unavailable;
  final int noPhoto;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget line(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.body),
            ),
          ),
        ],
      ),
    );
    return InsightCard(
      title: l.myMenu,
      subtitle: total == null ? null : l.totalItems(total!),
      action: TextButton(
        onPressed: () => context.go('/restaurant/menu'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        child: Text(l.seeMenu),
      ),
      child: total == null
          ? const SizedBox.shrink()
          : total == 0
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: l.addItem,
                variant: AppButtonVariant.small,
                icon: Icons.add_rounded,
                onPressed: () => context.push('/restaurant/menu/new'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: available! / total!,
                    minHeight: 8,
                    color: AppColors.success,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.dishesAvailable(available!, total!),
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                if (unavailable > 0)
                  line(
                    Icons.visibility_off_outlined,
                    AppColors.danger,
                    l.dishesUnavailable(unavailable),
                  ),
                if (noPhoto > 0)
                  line(
                    Icons.photo_camera_outlined,
                    AppColors.primary,
                    l.dishesNoPhoto(noPhoto),
                  ),
                if (unavailable == 0 && noPhoto == 0)
                  line(
                    Icons.verified_outlined,
                    AppColors.success,
                    l.menuHealthGood,
                  ),
              ],
            ),
    );
  }
}

/// "Money to receive from drivers": delivered orders whose food money the
/// restaurant hasn't confirmed. Hidden when there is none.
class CashToReceiveCard extends ConsumerStatefulWidget {
  const CashToReceiveCard({super.key});

  @override
  ConsumerState<CashToReceiveCard> createState() => _CashToReceiveCardState();
}

class _CashToReceiveCardState extends ConsumerState<CashToReceiveCard> {
  String? _busy;

  Future<void> _confirm(CashToReceive c) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          l.confirmReceivedQ(
            formatDzd(c.amount, lang),
            c.driverName.isEmpty ? l.driverSection : c.driverName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back, style: TextStyle(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.confirmReceived,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = c.orderId);
    try {
      await ref.read(ownerOrdersRepositoryProvider).confirmCash(c.orderId);
      if (mounted) showAppSnack(context, l.cashConfirmedMsg);
    } on OwnerOrderError catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          e.failure == OwnerOrderFailure.network
              ? l.errNetwork
              : l.errOrderChanged,
          error: true,
        );
      }
    } finally {
      ref.invalidate(ownerCashPendingProvider);
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final items = ref.watch(ownerCashPendingProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold(0, (s, c) => s + c.amount);
    final when = DateFormat('dd/MM HH:mm');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.cashToReceive,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  formatDzd(total, lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            for (final c in items) ...[
              Divider(color: AppColors.border, height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (c.driverName.isNotEmpty) c.driverName,
                            if (c.driverPhone.isNotEmpty) c.driverPhone,
                          ].join(' · '),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '#${c.code} · ${l.deliveredOnTime(when.format(c.deliveredAt))}',
                          style: TextStyle(color: AppColors.body),
                        ),
                        if (c.handedAt != null)
                          Text(
                            l.driverSaysHanded,
                            style: const TextStyle(color: AppColors.success),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatDzd(c.amount, lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(
                  label: l.confirmReceived,
                  variant: AppButtonVariant.small,
                  loading: _busy == c.orderId,
                  onPressed: _busy == null ? () => _confirm(c) : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
