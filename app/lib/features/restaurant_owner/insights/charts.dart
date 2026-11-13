import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Vertical bars that grow in. Tap a bar to see its value. [labels] is
/// shown under the bars (null = no label for that bar).
class BarChart extends StatefulWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.valueText,
    this.height = 150,
    this.highlight,
    this.color = AppColors.primary,
  });

  final List<int> values;
  final List<String?> labels;
  final String Function(int index) valueText;
  final double height;

  /// Index drawn in full colour (e.g. today, the busiest hour).
  final int? highlight;
  final Color color;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    if (n == 0) return SizedBox(height: widget.height);
    final max = widget.values.fold<int>(0, (m, v) => v > m ? v : m);
    final sel = _selected;
    return LayoutBuilder(
      builder: (context, c) {
        final slot = c.maxWidth / n;
        int indexAt(double dx) {
          final x = Directionality.of(context) == TextDirection.rtl
              ? c.maxWidth - dx
              : dx;
          return (x / slot).floor().clamp(0, n - 1);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 22,
              child: sel == null
                  ? null
                  : Align(
                      alignment: AlignmentDirectional(
                        (sel + .5) / n * 2 - 1,
                        0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.valueText(sel),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  setState(() => _selected = indexAt(d.localPosition.dx)),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _selected = indexAt(d.localPosition.dx)),
              child: SizedBox(
                height: widget.height,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(Object.hashAll(widget.values)),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: slot > 14 ? slot * .18 : 1,
                            ),
                            child: Container(
                              height: max == 0
                                  ? 3
                                  : (widget.values[i] / max * widget.height * t)
                                        .clamp(3, widget.height),
                              decoration: BoxDecoration(
                                color: widget.values[i] == 0
                                    ? AppColors.border
                                    : i == sel || i == widget.highlight
                                    ? widget.color
                                    : widget.color.withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(
                                  slot > 14 ? 6 : 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: widget.labels[i] == null
                        ? const SizedBox(height: 14)
                        : SizedBox(
                            height: 14,
                            child: OverflowBox(
                              maxWidth: 60,
                              maxHeight: 14,
                              child: Text(
                                widget.labels[i]!,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// One horizontal bar split by outcome, with a legend under it.
class OutcomeBar extends StatelessWidget {
  const OutcomeBar({super.key, required this.segments});

  /// (label, count, colour).
  final List<(String, int, Color)> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (s, e) => s + e.$2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: total == 0
                ? ColoredBox(color: AppColors.border)
                : Row(
                    children: [
                      for (final (_, v, color) in segments)
                        if (v > 0)
                          Expanded(
                            flex: v,
                            child: ColoredBox(color: color),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final (label, v, color) in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    total == 0
                        ? '$label 0'
                        : '$label $v (${(v * 100 / total).round()}%)',
                    style: TextStyle(fontSize: 13, color: AppColors.body),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// KPI tile: icon, big value, label and the change against the previous
/// period (green up / red down; [lowerIsBetter] flips the colours).
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.change,
    this.lowerIsBetter = false,
    this.tint = AppColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Percent; null = nothing to compare with.
  final double? change;
  final bool lowerIsBetter;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = change;
    final good = c == null || c == 0 ? null : (c > 0) != lowerIsBetter;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tint.withValues(
                        alpha: AppColors.isDark ? .22 : .12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: tint),
                  ),
                  const Spacer(),
                  if (c != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (good ?? true
                                    ? AppColors.success
                                    : AppColors.danger)
                                .withValues(alpha: good == null ? 0 : .14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Builder(
                        builder: (_) {
                          final color = good == null
                              ? AppColors.muted
                              : good
                              ? AppColors.success
                              : AppColors.danger;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            children: [
                              if (c != 0)
                                Icon(
                                  c > 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 12,
                                  color: color,
                                ),
                              Text(
                                '${c.abs() >= 1000 ? '999+' : c.abs().round()}%',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded section with a title and an optional action.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
