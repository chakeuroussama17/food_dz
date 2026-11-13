import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';

/// A portal page: big title and subtitle on the start side, controls
/// (timeframe, outlets) on the end side, then the content.
class PortalPage extends StatelessWidget {
  const PortalPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1200,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, c) => c.maxWidth < 760
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            head,
                            if (actions.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: actions,
                              ),
                            ],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: head),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: actions,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// White card with a light border, optional title, hint and action.
class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  // A Material (not a coloured box) so list tiles inside show their ink.
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 18),
          ],
          child,
        ],
      ),
    ),
  );
}

/// Top-of-dashboard counter: round icon, big number, label.
class PStat extends StatelessWidget {
  const PStat({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.change,
    this.lowerIsBetter = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Percent against the previous period.
  final double? change;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppColors.isDark ? .22 : .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  if (change != null) ...[
                    const SizedBox(width: 8),
                    ChangeChip(change: change!, lowerIsBetter: lowerIsBetter),
                  ],
                ],
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ↑ 12% in green / ↓ 5% in red.
class ChangeChip extends StatelessWidget {
  const ChangeChip({
    super.key,
    required this.change,
    this.lowerIsBetter = false,
  });
  final double change;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final good = change == 0 ? null : (change > 0) != lowerIsBetter;
    final color = good == null
        ? AppColors.muted
        : good
        ? AppColors.success
        : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        if (change != 0)
          Icon(
            change > 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 15,
            color: color,
          ),
        Text(
          '${change.abs() >= 1000 ? '999+' : change.abs().round()}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Joined buttons: "This week | Last week".
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, color: AppColors.border),
            InkWell(
              onTap: () => onSelected(items[i]),
              child: Container(
                color: items[i] == selected
                    ? AppColors.primarySoft
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  labelOf(items[i]),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: items[i] == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: items[i] == selected
                        ? AppColors.primary
                        : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// "2/3 outlets" button; the menu ticks which outlets the page shows.
class OutletSelector extends ConsumerWidget {
  const OutletSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(portalOutletsProvider).value ?? const [];
    final sel = ref.watch(portalSelectionProvider);
    final count = sel == null
        ? all.length
        : all.where((r) => sel.contains(r.id)).length;
    void toggle(String id) {
      final next = {
        ...sel ?? {for (final r in all) r.id},
      };
      next.contains(id) ? next.remove(id) : next.add(id);
      ref
          .read(portalSelectionProvider.notifier)
          .set(next.isEmpty || next.length == all.length ? null : next);
    }

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        CheckboxMenuButton(
          value: sel == null,
          onChanged: (_) =>
              ref.read(portalSelectionProvider.notifier).set(null),
          closeOnActivate: false,
          child: Text(l.outletsAll),
        ),
        const Divider(height: 1),
        for (final r in all)
          CheckboxMenuButton(
            value: sel == null || sel.contains(r.id),
            onChanged: (_) => toggle(r.id),
            closeOnActivate: false,
            child: Text(r.name),
          ),
      ],
      builder: (context, menu, _) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    all.length == 1 ? all.first.name : '$count/${all.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    l.outlets,
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Icon(Icons.expand_more_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounds up to 1, 2 or 5 × 10^n for the axis.
double niceCeil(double v) {
  if (v <= 0) return 1;
  final p = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in [1, 2, 2.5, 5, 10]) {
    if (v <= m * p) return m * p;
  }
  return 10 * p;
}

/// Smooth line chart with a grid, optional dashed comparison line and a
/// hover / tap tooltip.
class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.tooltip,
    this.compare,
    this.color = AppColors.primary,
    this.height = 220,
    this.axis,
  });

  final List<double> values;

  /// Same length as [values]; drawn sparsely.
  final List<String> labels;

  /// Dashed grey line (previous period), same length.
  final List<double>? compare;
  final String Function(int i) tooltip;
  final Color color;
  final double height;

  /// Axis label for a value (default: rounded number).
  final String Function(double v)? axis;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          const left = 48.0, bottom = 26.0, top = 8.0;
          final w = c.maxWidth - left - 8;
          double xOf(int i) => left + (n <= 1 ? w / 2 : w * i / (n - 1));
          int indexAt(double dx) =>
              n <= 1 ? 0 : ((dx - left) / w * (n - 1)).round().clamp(0, n - 1);
          final i = _hover;
          return MouseRegion(
            onHover: (e) =>
                setState(() => _hover = indexAt(e.localPosition.dx)),
            onExit: (_) => setState(() => _hover = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  setState(() => _hover = indexAt(d.localPosition.dx)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(Object.hashAll(widget.values)),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, _) => CustomPaint(
                        painter: _LinePainter(
                          values: widget.values,
                          compare: widget.compare,
                          labels: widget.labels,
                          color: widget.color,
                          progress: t,
                          hover: i,
                          left: left,
                          bottom: bottom,
                          top: top,
                          axis: widget.axis,
                          textDirection: Directionality.of(context),
                          font: DefaultTextStyle.of(context).style,
                        ),
                      ),
                    ),
                  ),
                  if (i != null)
                    Positioned(
                      top: 0,
                      left: (xOf(i) - 90).clamp(0, c.maxWidth - 180),
                      width: 180,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.tooltip(i),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.compare,
    required this.labels,
    required this.color,
    required this.progress,
    required this.hover,
    required this.left,
    required this.bottom,
    required this.top,
    required this.axis,
    required this.textDirection,
    required this.font,
  });

  /// The app's font (a painter doesn't inherit it).
  final TextStyle font;

  final List<double> values;
  final List<double>? compare;
  final List<String> labels;
  final Color color;
  final double progress;
  final int? hover;
  final double left, bottom, top;
  final String Function(double v)? axis;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final maxV = niceCeil(
      [...values, ...?compare].fold<double>(0, (m, v) => v > m ? v : m),
    );
    final h = size.height - bottom - top;
    final w = size.width - left - 8;
    double x(int i) => left + (n <= 1 ? w / 2 : w * i / (n - 1));
    double y(double v) => top + h - (v / maxV) * h * progress;

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    void text(
      String s,
      Offset at, {
      bool alignEnd = false,
      bool center = false,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: font.copyWith(
            fontSize: 11,
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = alignEnd
          ? at.dx - tp.width
          : center
          ? at.dx - tp.width / 2
          : at.dx;
      tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
    }

    for (var k = 0; k <= 4; k++) {
      final v = maxV * k / 4;
      final yy = top + h - h * k / 4;
      canvas.drawLine(Offset(left, yy), Offset(size.width - 8, yy), grid);
      text(axis?.call(v) ?? _short(v), Offset(left - 8, yy), alignEnd: true);
    }
    final every = (n / 7).ceil().clamp(1, n);
    for (var i = 0; i < n; i += every) {
      text(labels[i], Offset(x(i), size.height - bottom / 2), center: true);
    }

    Path smooth(List<double> vs) {
      final p = Path()..moveTo(x(0), y(vs[0]));
      for (var i = 1; i < vs.length; i++) {
        final mx = (x(i - 1) + x(i)) / 2;
        p.cubicTo(mx, y(vs[i - 1]), mx, y(vs[i]), x(i), y(vs[i]));
      }
      return p;
    }

    final cmp = compare;
    if (cmp != null && cmp.length == n) {
      final path = smooth(cmp);
      final dashed = Path();
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9) {
          dashed.addPath(
            m.extractPath(d, math.min(d + 5, m.length)),
            Offset.zero,
          );
        }
      }
      canvas.drawPath(
        dashed,
        Paint()
          ..color = AppColors.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final line = smooth(values);
    final area = Path.from(line)
      ..lineTo(x(n - 1), top + h)
      ..lineTo(x(0), top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, top, size.width, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    final i = hover;
    if (i != null && i < n) {
      canvas.drawLine(
        Offset(x(i), top),
        Offset(x(i), top + h),
        Paint()
          ..color = AppColors.muted.withValues(alpha: .5)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(Offset(x(i), y(values[i])), 5, Paint()..color = color);
      canvas.drawCircle(
        Offset(x(i), y(values[i])),
        2.5,
        Paint()..color = AppColors.surface,
      );
    }
  }

  static String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) {
      final k = v / 1000;
      return '${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1)}k';
    }
    return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.compare != compare ||
      old.progress != progress ||
      old.hover != hover;
}

/// Ring split in [values] with [colors]; [center] in the middle.
class Donut extends StatelessWidget {
  const Donut({
    super.key,
    required this.values,
    required this.colors,
    this.size = 180,
    this.center,
  });

  final List<double> values;
  final List<Color> colors;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) =>
          CustomPaint(painter: _DonutPainter(values, colors, t), child: child),
      child: Center(child: center),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors, this.progress);
  final List<double> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    final stroke = size.width * .16;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p..color = AppColors.border);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2 * progress;
      canvas.drawArc(rect, start, sweep, false, p..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.values != values;
}

/// Grid of hours (rows) × days (columns), darker = more. Each cell has a
/// tooltip.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.values,
    required this.columns,
    required this.tooltip,
    this.rows = const [],
  });

  /// values[row][column].
  final List<List<double>> values;
  final List<String> columns;

  /// Row labels (hours); defaults to "00:00".. by index.
  final List<String> rows;
  final String Function(int row, int col) tooltip;

  static Color shade(double t) =>
      Color.lerp(AppColors.field, AppColors.primary, t.clamp(0, 1).toDouble())!;

  @override
  Widget build(BuildContext context) {
    final maxV = values
        .expand((r) => r)
        .fold<double>(0, (m, v) => v > m ? v : m);
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 52),
            for (final c in columns)
              Expanded(
                child: Text(
                  c,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < values.length; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    r < rows.length ? rows[r] : '${'$r'.padLeft(2, '0')}:00',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ),
                for (var c = 0; c < values[r].length; c++)
                  Expanded(
                    child: Tooltip(
                      message: tooltip(r, c),
                      waitDuration: const Duration(milliseconds: 150),
                      child: Container(
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: maxV == 0
                              ? AppColors.field
                              : shade(values[r][c] / maxV),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small coloured legend dot + text.
class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.dashed = false,
  });
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 3,
        decoration: BoxDecoration(
          color: dashed ? null : color,
          border: dashed
              ? Border(top: BorderSide(color: color, width: 2))
              : null,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.body)),
    ],
  );
}

/// Two or more widgets side by side on wide screens, stacked on narrow.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 760,
    this.gap = 16,
  });

  final List<Widget> children;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth < breakpoint
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          )
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
  );
}

/// Drop-down to pick the one outlet a page edits (menu, hours, team).
class SingleOutletPicker extends ConsumerWidget {
  const SingleOutletPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(portalOutletsProvider).value ?? const [];
    final current = ref.watch(portalOutletProvider).value;
    if (current == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current.id,
          items: [
            for (final r in all)
              DropdownMenuItem(value: r.id, child: Text(r.name)),
          ],
          onChanged: (id) {
            if (id != null) {
              ref.read(portalCurrentOutletProvider.notifier).set(id);
            }
          },
        ),
      ),
    );
  }
}

/// Tiles in rows of [perRow], every tile of a row as tall as the tallest
/// (labels of different lengths keep the cards aligned).
class EqualGrid extends StatelessWidget {
  const EqualGrid({
    super.key,
    required this.children,
    required this.perRow,
    this.gap = 16,
  });

  final List<Widget> children;
  final int Function(double width) perRow;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final per = perRow(c.maxWidth).clamp(1, 12);
      return Column(
        children: [
          for (var i = 0; i < children.length; i += per) ...[
            if (i > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + per; j++) ...[
                    if (j > i) SizedBox(width: gap),
                    Expanded(
                      child: j < children.length
                          ? children[j]
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
