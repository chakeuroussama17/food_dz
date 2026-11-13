import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../data/periods.dart';

export '../../orders/order_status.dart';
export '../../../core/widgets/pill.dart';

enum AdminSection {
  dashboard,
  restaurants,
  drivers,
  customers,
  orders,
  receipts,
  ratings,
  promos,
  settings,
}

const _paths = {
  AdminSection.dashboard: '/admin',
  AdminSection.restaurants: '/admin/restaurants',
  AdminSection.drivers: '/admin/drivers',
  AdminSection.customers: '/admin/customers',
  AdminSection.orders: '/admin/orders',
  AdminSection.receipts: '/admin/receipts',
  AdminSection.ratings: '/admin/ratings',
  AdminSection.promos: '/admin/promos',
  AdminSection.settings: '/admin/settings',
};

/// Admin page frame: navigation rail on wide screens (PC / tablet),
/// bottom navigation bar on phones.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.section,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingAction,
  });

  final AdminSection section;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final items = [
      (Icons.space_dashboard_outlined, l.dashboard),
      (Icons.storefront_outlined, l.restaurantsTitle),
      (Icons.delivery_dining_outlined, l.driversTitle),
      (Icons.people_outline_rounded, l.customers),
      (Icons.receipt_long_outlined, l.orders),
      (Icons.request_quote_outlined, l.receipts),
      (Icons.star_outline_rounded, l.navRatings),
      (Icons.local_offer_outlined, l.navPromos),
      (Icons.settings_outlined, l.settings),
    ];
    void go(int i) => context.go(_paths[AdminSection.values[i]]!);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: floatingAction,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: section.index,
              onDestinationSelected: go,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primarySoft,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (final (icon, label) in items)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(icon, color: AppColors.primary),
                    label: label,
                  ),
              ],
            ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: section.index,
                    onDestinationSelected: go,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: AppColors.surface,
                    indicatorColor: AppColors.primarySoft,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l.admin,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    destinations: [
                      for (final (icon, label) in items)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(icon, color: AppColors.primary),
                          label: Text(label),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: content,
                      ),
                    ),
                  ),
                ],
              )
            : content,
      ),
    );
  }
}

/// White rounded panel used throughout the admin.
class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  // A Material (not a decorated Container) so list rows inside show their
  // tap ripple instead of having it hidden under the white background.
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding ?? const EdgeInsets.all(16),
      // The theme's default body text is the muted grey used for
      // descriptions; admin figures must read in the normal dark ink.
      child: DefaultTextStyle.merge(
        style: TextStyle(color: AppColors.ink, fontSize: 14),
        child: DataTableTheme(
          data: DataTableThemeData(
            dataTextStyle: TextStyle(color: AppColors.ink, fontSize: 14),
            headingTextStyle: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// A number with a label ("Commission earned · 12 400 DA").
class AdminStatTile extends StatelessWidget {
  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: highlight ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: 10),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: highlight ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: highlight ? Colors.white70 : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today / 7 days / this month / last month / custom.
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key, required this.range, required this.onChanged});

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final presets = {
      StatsPeriod.today: l.periodToday,
      StatsPeriod.last7: l.periodLast7,
      StatsPeriod.thisMonth: l.periodThisMonth,
      StatsPeriod.lastMonth: l.periodLastMonth,
    };
    final selected = presets.keys
        .where((p) => statsRange(p, now) == range)
        .firstOrNull;
    final fmt = DateFormat('dd/MM/yyyy');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final e in presets.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: selected == e.key,
            selectedColor: AppColors.accent,
            labelStyle: TextStyle(
              color: selected == e.key ? Colors.white : AppColors.ink,
            ),
            onSelected: (_) => onChanged(statsRange(e.key, now)),
          ),
        ActionChip(
          avatar: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(
            selected == null
                ? '${fmt.format(range.start)} – ${fmt.format(range.end)}'
                : l.periodCustom,
          ),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2025),
              lastDate: DateTime(now.year, now.month, now.day),
              initialDateRange: DateTimeRange(
                start: range.start,
                end: range.end,
              ),
            );
            if (picked != null) {
              onChanged(DateRange(picked.start, picked.end));
            }
          },
        ),
      ],
    );
  }
}

String percent(double rate) {
  // Round to 0.1 first: 0.1 * 100 is 10.000000000000002 in floating point.
  final p = (rate * 1000).round() / 10;
  return '${p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1)} %';
}
