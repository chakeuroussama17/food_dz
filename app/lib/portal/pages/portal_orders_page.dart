import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/files/file_output.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/orders/order_status.dart';
import '../../features/restaurant_owner/data/owner_orders_repository.dart';
import '../../features/restaurant_owner/insights/orders_csv.dart';
import '../../features/restaurant_owner/owner_receipt.dart';
import '../../features/restaurant_owner/pages/owner_orders_page.dart'
    show ownerActions, CancelRequestBanner;
import '../../features/restaurant_owner/pages/owner_orders_table_page.dart'
    show StatusDot, StatusFilter;
import '../../features/restaurant_owner/widgets/period_chips.dart';
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';
import '../../features/ratings/ratings_widgets.dart';

bool _matches(StatusFilter f, String status) => switch (f) {
  StatusFilter.all => true,
  StatusFilter.inProgress => activeOrderStatuses.contains(status),
  StatusFilter.delivered => status == 'delivered',
  StatusFilter.rejected => status == 'rejected',
  StatusFilter.cancelled => status == 'cancelled',
};

/// Real-time orders of the selected outlets in a big sortable table; a
/// row opens the side panel (timeline, customer, items, money, actions).
class PortalOrdersPage extends ConsumerStatefulWidget {
  const PortalOrdersPage({super.key});

  @override
  ConsumerState<PortalOrdersPage> createState() => _PortalOrdersPageState();
}

class _PortalOrdersPageState extends ConsumerState<PortalOrdersPage> {
  Period _period = Period.today;
  DateTimeRange? _custom;
  StatusFilter _status = StatusFilter.all;
  String _query = '';
  int _sort = 6; // placed at
  bool _asc = false;
  int _shown = 50;
  String? _open; // order id in the side panel
  bool _exporting = false;

  Future<void> _pick(Period p) async {
    if (p != Period.custom) {
      setState(() {
        _period = p;
        _shown = 50;
      });
      return;
    }
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
      _period = p;
      _shown = 50;
    });
  }

  List<OwnerOrder> _filter(List<OwnerOrder> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((o) {
      if (!_matches(_status, o.status)) return false;
      if (q.isEmpty) return true;
      return o.code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.restaurantName.toLowerCase().contains(q) ||
          o.customerPhone.contains(q) ||
          o.items.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
    Comparable key(OwnerOrder o) => switch (_sort) {
      0 => o.code,
      1 => o.restaurantName,
      2 => o.status,
      3 => o.customerName.toLowerCase(),
      4 => o.items.fold<int>(0, (s, i) => s + i.quantity),
      5 => o.total,
      _ => o.placedAt,
    };
    return list..sort((a, b) {
      final c = key(a).compareTo(key(b));
      return _asc ? c : -c;
    });
  }

  Future<void> _export(List<OwnerOrder> rows, ReportRange r) async {
    final l = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      final d = DateFormat('yyyy-MM-dd');
      final last = r.to.subtract(const Duration(days: 1));
      final name = d.format(r.from) == d.format(last)
          ? 'orders_${d.format(r.from)}.csv'
          : 'orders_${d.format(r.from)}_${d.format(last)}.csv';
      await ref
          .read(fileOutputProvider)
          .save(csvBytes(ordersCsv(rows, l)), name, 'text/csv');
      if (mounted) showAppSnack(context, l.csvReady);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ids = ref.watch(portalOutletIdsProvider).value;
    final r = _period.range(DateTime.now(), custom: _custom);
    final range = ReportRange(r.from, r.to, outlets: ids);
    final data = ids == null
        ? const AsyncLoading<List<OwnerOrder>>()
        : ref.watch(ownerReportProvider(range));
    final rows = data.whenData(_filter);
    final list = rows.value ?? const <OwnerOrder>[];
    final open = _open == null
        ? null
        : data.value?.where((o) => o.id == _open).firstOrNull;

    final page = PortalPage(
      title: l.orders,
      subtitle: l.ordersSubtitle,
      actions: [
        Segmented<Period>(
          items: const [
            Period.today,
            Period.yesterday,
            Period.d7,
            Period.d30,
            Period.custom,
          ],
          selected: _period,
          labelOf: (p) => p == Period.custom && _custom != null
              ? '${DateFormat('dd/MM').format(_custom!.start)} – '
                    '${DateFormat('dd/MM').format(_custom!.end)}'
              : p.label(l),
          onSelected: _pick,
        ),
        const OutletSelector(),
      ],
      children: [
        Row(
          children: [
            Expanded(
              child: SmallChips<StatusFilter>(
                items: StatusFilter.values,
                selected: _status,
                labelOf: (f) => switch (f) {
                  StatusFilter.all => l.filterAll,
                  StatusFilter.inProgress => l.filterInProgress,
                  StatusFilter.delivered => l.statusDelivered,
                  StatusFilter.rejected => orderStatusLabel(l, 'rejected'),
                  StatusFilter.cancelled => orderStatusLabel(l, 'cancelled'),
                },
                onSelected: (f) => setState(() {
                  _status = f;
                  _shown = 50;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() {
                  _query = v;
                  _shown = 50;
                }),
                decoration: InputDecoration(
                  hintText: l.searchOrdersHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: l.exportCsv,
              child: FilledButton.icon(
                onPressed: list.isEmpty || _exporting
                    ? null
                    : () => _export(list, range),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l.exportCsv),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        rows.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
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
          data: (list) => list.isEmpty
              ? PCard(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l.noOrdersPeriod,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Table(
                      rows: list.take(_shown).toList(),
                      lang: lang,
                      sort: _sort,
                      asc: _asc,
                      selected: _open,
                      onSort: (c, a) => setState(() {
                        _sort = c;
                        _asc = a;
                      }),
                      onTap: (o) => setState(() => _open = o.id),
                    ),
                    if (list.length > _shown)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: AppButton(
                            label: '${l.seeAll} (${list.length - _shown})',
                            variant: AppButtonVariant.outline,
                            onPressed: () => setState(() => _shown += 100),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );

    return Stack(
      children: [
        page,
        if (open != null) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _open = null),
              child: ColoredBox(color: Colors.black.withValues(alpha: .25)),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: MediaQuery.sizeOf(context).width < 560
                ? MediaQuery.sizeOf(context).width
                : 460,
            child: OrderPanel(
              order: open,
              onClose: () => setState(() => _open = null),
            ),
          ),
        ],
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.rows,
    required this.lang,
    required this.sort,
    required this.asc,
    required this.onSort,
    required this.onTap,
    this.selected,
  });

  final List<OwnerOrder> rows;
  final String lang;
  final int sort;
  final bool asc;
  final String? selected;
  final void Function(int, bool) onSort;
  final ValueChanged<OwnerOrder> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final when = DateFormat('dd/MM/yyyy HH:mm');
    final head = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    );
    final cell = TextStyle(fontSize: 14, color: AppColors.ink);
    DataColumn col(String s, {bool numeric = false}) => DataColumn(
      label: Text(s, style: head),
      numeric: numeric,
      onSort: onSort,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              sortColumnIndex: sort,
              sortAscending: asc,
              showCheckboxColumn: false,
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 60,
              horizontalMargin: 20,
              columnSpacing: 28,
              dividerThickness: .6,
              columns: [
                col(l.csvCode),
                col(l.csvOutlet),
                col(l.csvStatus),
                col(l.csvCustomer),
                col(l.csvItemCount, numeric: true),
                col(l.csvTotal, numeric: true),
                col(l.placedAtCol),
              ],
              rows: [
                for (final o in rows)
                  DataRow(
                    selected: o.id == selected,
                    color: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? AppColors.primarySoft
                          : null,
                    ),
                    onSelectChanged: (_) => onTap(o),
                    cells: [
                      DataCell(
                        Text(
                          o.code,
                          style: cell.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(Text(o.restaurantName, style: cell)),
                      DataCell(StatusDot(status: o.status)),
                      DataCell(Text(o.customerName, style: cell)),
                      DataCell(
                        Text(
                          '${o.items.fold<int>(0, (s, i) => s + i.quantity)}',
                          style: cell,
                        ),
                      ),
                      DataCell(Text(formatDzd(o.total, lang), style: cell)),
                      DataCell(
                        Text(
                          when.format(o.placedAt),
                          textDirection: TextDirection.ltr,
                          style: cell.copyWith(color: AppColors.body),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Side panel: timeline, customer, items, money, actions and receipt.
class OrderPanel extends ConsumerWidget {
  const OrderPanel({super.key, required this.order, required this.onClose});
  final OwnerOrder order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final o = order;
    final time = DateFormat('HH:mm');
    final label = TextStyle(fontSize: 12.5, color: AppColors.muted);
    String took(Duration d) => d.inSeconds < 120
        ? l.secondsShort(d.inSeconds)
        : l.minutesShort(d.inMinutes);
    Widget money(String a, String b, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  a,
                  style: TextStyle(
                    color: bold ? AppColors.ink : AppColors.body,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                b,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.ink,
                ),
              ),
            ],
          ),
        );
    Widget section(List<Widget> children) => Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    final steps = [
      (l.statusPlaced, o.placedAt, null),
      (
        orderStatusLabel(l, 'accepted'),
        o.acceptedAt,
        o.acceptedAt == null
            ? null
            : l.acceptedIn(took(o.acceptedAt!.difference(o.placedAt))),
      ),
      (orderStatusLabel(l, 'ready'), o.readyAt, null),
      (orderStatusLabel(l, 'picked_up'), o.pickedUpAt, null),
      (orderStatusLabel(l, 'delivered'), o.deliveredAt, null),
      (orderStatusLabel(l, o.status), o.cancelledAt, null),
    ].where((s) => s.$2 != null).toList();
    final delivered = o.status == 'delivered';
    final actions = ownerActions(context, ref, o);

    return Material(
      color: AppColors.canvas,
      elevation: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.pill,
            padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const BackButtonIcon(),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      o.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusDot(status: o.status),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (o.cancelRequestPending)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: CancelRequestBanner(order: o),
                  ),
                section([
                  Wrap(
                    spacing: 28,
                    runSpacing: 14,
                    children: [
                      for (final (name, at, note) in steps)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              time.format(at!),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(name, style: TextStyle(color: AppColors.ink)),
                            if (note != null) Text(note, style: label),
                          ],
                        ),
                    ],
                  ),
                ]),
                section([
                  Text(l.customer.toUpperCase(), style: label),
                  const SizedBox(height: 6),
                  Text(
                    o.customerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (o.customerPhone.isNotEmpty)
                    SelectableText(
                      o.customerPhone,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (o.addressText.isNotEmpty || o.area.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              o.addressText,
                              o.area,
                              o.addressDetails,
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: TextStyle(color: AppColors.body),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (o.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l.notes}: ${o.notes}',
                      style: TextStyle(color: AppColors.body),
                    ),
                  ],
                  if ((o.driverName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l.csvDriver}: ${o.driverName}',
                      style: TextStyle(color: AppColors.body),
                    ),
                  ],
                ]),
                section([
                  Text(
                    l.orderDetailsTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final i in o.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${i.quantity}×',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              i.name,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          Text(
                            formatDzd(i.lineTotal, lang),
                            style: TextStyle(color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 24, color: AppColors.border),
                  money(l.subtotal, formatDzd(o.foodTotal, lang), bold: true),
                  money(l.deliveryFee, formatDzd(o.deliveryFee, lang)),
                  if (o.discountAmount > 0)
                    money(
                      l.discount,
                      '−${formatDzd(o.discountAmount, lang)}',
                      color: AppColors.success,
                    ),
                  if (o.taxAmount > 0)
                    money(l.taxLabel, formatDzd(o.taxAmount, lang)),
                  money(l.total, formatDzd(o.total, lang)),
                  if (delivered) ...[
                    money(
                      l.csvCommission,
                      '- ${formatDzd(o.commissionAmount ?? 0, lang)}',
                      color: AppColors.danger,
                    ),
                    money(
                      l.kpiNet,
                      formatDzd(o.net, lang),
                      bold: true,
                      color: AppColors.success,
                    ),
                  ],
                  if ((o.rejectReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.rejectReasonLabel(rejectReasonText(l, o.rejectReason!)),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                ]),
                if (actions.isNotEmpty || delivered)
                  section([
                    if (actions.isNotEmpty)
                      Wrap(spacing: 12, runSpacing: 8, children: actions),
                    if (delivered) OwnerReceiptButtons(order: o),
                  ]),
                section([ReportCustomerLink(orderId: o.id)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
