import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/owner_orders_repository.dart';

/// Report periods. Ranges are whole local days, [from, to).
enum Period {
  today,
  yesterday,
  d7,
  d30,
  d90,
  month,
  custom;

  ReportRange range(DateTime now, {DateTimeRange? custom}) {
    DateTime day(int add) => DateTime(now.year, now.month, now.day + add);
    return switch (this) {
      Period.today => ReportRange(day(0), day(1)),
      Period.yesterday => ReportRange(day(-1), day(0)),
      Period.d7 => ReportRange(day(-6), day(1)),
      Period.d30 => ReportRange(day(-29), day(1)),
      Period.d90 => ReportRange(day(-89), day(1)),
      Period.month => ReportRange(DateTime(now.year, now.month), day(1)),
      Period.custom when custom != null => ReportRange(
        DateTime(custom.start.year, custom.start.month, custom.start.day),
        DateTime(custom.end.year, custom.end.month, custom.end.day + 1),
      ),
      Period.custom => ReportRange(day(-6), day(1)),
    };
  }

  String label(AppLocalizations l) => switch (this) {
    Period.today => l.todayTitle,
    Period.yesterday => l.rangeYesterday,
    Period.d7 => l.range7,
    Period.d30 => l.range30,
    Period.d90 => l.range90,
    Period.month => l.rangeMonth,
    Period.custom => l.rangeCustom,
  };
}

/// Period selector; the custom chip shows the chosen dates.
class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.periods,
    required this.selected,
    required this.onSelected,
    this.custom,
  });

  final List<Period> periods;
  final Period selected;
  final DateTimeRange? custom;
  final ValueChanged<Period> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = DateFormat('dd/MM');
    return SmallChips<Period>(
      items: periods,
      selected: selected,
      onSelected: onSelected,
      labelOf: (p) => p == Period.custom && custom != null
          ? '${d.format(custom!.start)} – ${d.format(custom!.end)}'
          : p.label(l),
      iconOf: (p) => p == Period.custom ? Icons.date_range_rounded : null,
    );
  }
}

/// Compact scrolling choice chips: dark pill when selected.
class SmallChips<T> extends StatelessWidget {
  const SmallChips({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.iconOf,
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        final sel = item == selected;
        final icon = iconOf?.call(item);
        final fg = sel ? Colors.white : AppColors.inkSoft;
        return Material(
          color: sel ? AppColors.pill : AppColors.surface,
          shape: StadiumBorder(
            side: sel ? BorderSide.none : BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labelOf(item),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
