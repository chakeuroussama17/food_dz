import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/data/catalog_models.dart';
import 'cart_controller.dart';

/// Starting choice: the first available choice of each required
/// single-choice group (e.g. the normal size).
Set<String> defaultChoices(MenuItem item) => {
  for (final g in item.optionGroups)
    if (g.single && g.required)
      ?g.choices.where((c) => c.isAvailable).firstOrNull?.id,
};

/// The chosen choices, in the menu's order.
List<OptionChoice> chosenFrom(MenuItem item, Set<String> ids) => [
  for (final g in item.optionGroups)
    for (final c in g.choices)
      if (ids.contains(c.id)) c,
];

/// Every option group of a dish: radio buttons for one choice, check
/// boxes for several, with the extra price and "Required" / "Up to 2".
class OptionsPicker extends StatelessWidget {
  const OptionsPicker({
    super.key,
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final MenuItem item;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in item.optionGroups) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  g.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _RuleChip(group: g, selected: selected),
            ],
          ),
          if (!g.single)
            Text(
              l.chooseUpTo(g.max),
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          const SizedBox(height: 4),
          for (final c in g.choices)
            _ChoiceTile(
              group: g,
              choice: c,
              checked: selected.contains(c.id),
              price: c.price == 0 ? '' : '+ ${formatDzd(c.price, lang)}',
              onTap: !c.isAvailable
                  ? null
                  : () {
                      final next = {...selected};
                      if (g.single) {
                        next.removeAll(g.choices.map((x) => x.id));
                        if (!selected.contains(c.id) || g.required) {
                          next.add(c.id);
                        }
                      } else if (next.contains(c.id)) {
                        next.remove(c.id);
                      } else {
                        final inGroup = g.choices
                            .where((x) => next.contains(x.id))
                            .length;
                        if (inGroup >= g.max) return;
                        next.add(c.id);
                      }
                      onChanged(next);
                    },
            ),
          Divider(color: AppColors.border, height: 20),
        ],
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.group, required this.selected});
  final OptionGroup group;
  final Set<String> selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final picked = group.choices.where((c) => selected.contains(c.id)).length;
    final ok = picked >= group.min;
    final text = group.required ? l.optionRequired : l.optional;
    final color = !group.required
        ? AppColors.muted
        : ok
        ? AppColors.success
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? .22 : .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (group.required && ok) ...[
            Icon(Icons.check_rounded, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.group,
    required this.choice,
    required this.checked,
    required this.price,
    required this.onTap,
  });

  final OptionGroup group;
  final OptionChoice choice;
  final bool checked;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final off = onTap == null;
    final color = off ? AppColors.muted : AppColors.ink;
    return Semantics(
      checked: checked,
      label: choice.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                group.single
                    ? (checked
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded)
                    : (checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded),
                color: checked ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice.name,
                  style: TextStyle(fontSize: 15, color: color),
                ),
              ),
              Text(
                off ? l.outOfStock : price,
                style: TextStyle(
                  fontSize: 14,
                  color: off ? AppColors.danger : AppColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to choose a dish's options before adding it (quick "+"
/// buttons). Returns the choices, or null when closed.
Future<List<OptionChoice>?> showOptionsSheet(
  BuildContext context,
  MenuItem item,
) => showModalBottomSheet<List<OptionChoice>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  builder: (_) => _OptionsSheet(item: item),
);

class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({required this.item});
  final MenuItem item;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  late Set<String> _sel = defaultChoices(widget.item);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final chosen = chosenFrom(widget.item, _sel);
    final valid = optionsValid(widget.item, chosen);
    final price =
        widget.item.price + chosen.fold<int>(0, (s, c) => s + c.price);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.item.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: OptionsPicker(
                  item: widget.item,
                  selected: _sel,
                  onChanged: (s) => setState(() => _sel = s),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(
                label: '${l.addToCart}  ·  ${formatDzd(price, lang)}',
                onPressed: valid ? () => Navigator.pop(context, chosen) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
