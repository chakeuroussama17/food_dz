import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/catalog/widgets/opening_text.dart';
import '../../features/restaurant_owner/data/outlet_admin_repository.dart';
import '../../features/restaurant_owner/data/owner_repository.dart';
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

enum _Tab { weekly, special }

String _hm(TimeOfDay t) =>
    '${'${t.hour}'.padLeft(2, '0')}:${'${t.minute}'.padLeft(2, '0')}';

TimeOfDay _parse(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

/// 24-hour time picker.
Future<String?> pickTime(BuildContext context, String initial) async {
  final t = await showTimePicker(
    context: context,
    initialTime: _parse(initial),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return t == null ? null : _hm(t);
}

/// Weekday names, 0 = Saturday.
List<String> weekdayNames(String lang) => [
  for (var i = 0; i < 7; i++)
    DateFormat.EEEE(lang).format(DateTime(2026, 11, 14 + i)),
];

/// Opening times: weekly hours (several slots a day, past midnight allowed),
/// holidays and special hours, and the open / closed status right now.
class PortalHoursPage extends ConsumerStatefulWidget {
  const PortalHoursPage({super.key});

  @override
  ConsumerState<PortalHoursPage> createState() => _PortalHoursPageState();
}

class _PortalHoursPageState extends ConsumerState<PortalHoursPage> {
  _Tab _tab = _Tab.weekly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final outlet = ref.watch(portalOutletProvider).value;
    if (outlet == null) return const SizedBox.shrink();
    final hours = ref.watch(outletHoursProvider(outlet.id));
    return PortalPage(
      title: l.navHours,
      subtitle: l.hoursSubtitle,
      actions: const [SingleOutletPicker()],
      maxWidth: 980,
      children: [
        hours.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(outletHoursProvider(outlet.id)),
              child: Text(l.retry),
            ),
          ),
          data: (h) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(outlet: outlet, hours: h),
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Segmented<_Tab>(
                  items: _Tab.values,
                  selected: _tab,
                  labelOf: (t) =>
                      t == _Tab.weekly ? l.weeklyHours : l.specialDays,
                  onSelected: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: 16),
              if (_tab == _Tab.weekly)
                _WeeklyEditor(
                  key: ValueKey('${outlet.id}-${h.weekly.length}'),
                  restaurantId: outlet.id,
                  initial: h.weekly,
                )
              else
                _SpecialDays(restaurantId: outlet.id, days: h.special),
            ],
          ),
        ),
      ],
    );
  }
}

/// Open now / closed now, the next opening and the manual switch.
class _StatusCard extends ConsumerStatefulWidget {
  const _StatusCard({required this.outlet, required this.hours});
  final OwnedRestaurant outlet;
  final OutletHours hours;

  @override
  ConsumerState<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<_StatusCard> {
  bool _busy = false;

  Future<void> _toggle(bool v) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(ownerRepositoryProvider).setOpen(widget.outlet.id, v);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      ref.invalidate(outletHoursProvider(widget.outlet.id));
      ref.invalidate(myRestaurantsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final h = widget.hours;
    final color = h.openNow ? AppColors.success : AppColors.danger;
    return PCard(
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.openNow ? l.openNowLabel : l.closedNowLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    !h.switchOn
                        ? l.switchOffHint
                        : h.openNow
                        ? l.takingOrders
                        : closedText(l, lang, h.nextOpenAt),
                    style: TextStyle(color: AppColors.body),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.ordersSwitch, style: TextStyle(color: AppColors.ink)),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: h.switchOn,
                activeTrackColor: AppColors.primary,
                onChanged: !widget.outlet.isActive || _busy ? null : _toggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyEditor extends ConsumerStatefulWidget {
  const _WeeklyEditor({
    super.key,
    required this.restaurantId,
    required this.initial,
  });

  final String restaurantId;
  final List<HourSlot> initial;

  @override
  ConsumerState<_WeeklyEditor> createState() => _WeeklyEditorState();
}

class _WeeklyEditorState extends ConsumerState<_WeeklyEditor> {
  /// Slots per weekday: (opens, closes).
  late List<List<(String, String)>> _days = _from(widget.initial);
  bool _saving = false;

  static List<List<(String, String)>> _from(List<HourSlot> s) => [
    for (var d = 0; d < 7; d++)
      [
        for (final x in s)
          if (x.weekday == d) (x.opens, x.closes),
      ],
  ];

  List<HourSlot> get _slots => [
    for (var d = 0; d < 7; d++)
      for (final (o, c) in _days[d]) HourSlot(d, o, c),
  ];

  bool get _dirty {
    final a = _slots, b = widget.initial;
    if (a.length != b.length) return true;
    return a.toSet().difference(b.toSet()).isNotEmpty;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(outletAdminRepositoryProvider)
          .setHours(widget.restaurantId, _slots);
      if (mounted) showAppSnack(context, l.saved);
      ref.invalidate(outletHoursProvider(widget.restaurantId));
      ref.invalidate(myRestaurantsProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(int d, int i) async {
    final (o, c) = _days[d][i];
    final opens = await pickTime(context, o);
    if (opens == null || !mounted) return;
    final closes = await pickTime(context, c);
    if (closes == null || opens == closes) return;
    setState(() => _days[d][i] = (opens, closes));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final names = weekdayNames(lang);
    return PCard(
      title: l.weeklyHours,
      subtitle: l.weeklyHoursHint,
      action: AppButton(
        label: l.saveChanges,
        variant: AppButtonVariant.small,
        loading: _saving,
        onPressed: _dirty ? _save : null,
      ),
      child: Column(
        children: [
          for (var d = 0; d < 7; d++) ...[
            if (d > 0) Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 170,
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      value: _days[d].isNotEmpty,
                      title: Text(
                        names[d],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      onChanged: (v) => setState(
                        () => _days[d] = v == true ? [('11:00', '23:00')] : [],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _days[d].isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              l.closedAllDay,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (var i = 0; i < _days[d].length; i++)
                                InputChip(
                                  label: Text(
                                    '${_days[d][i].$1} – ${_days[d][i].$2}'
                                    '${_days[d][i].$2.compareTo(_days[d][i].$1) < 0 ? ' (+1)' : ''}',
                                    textDirection: TextDirection.ltr,
                                  ),
                                  onPressed: () => _edit(d, i),
                                  onDeleted: () =>
                                      setState(() => _days[d].removeAt(i)),
                                ),
                              if (_days[d].length < 3)
                                TextButton.icon(
                                  onPressed: () => setState(
                                    () => _days[d].add(('18:00', '23:00')),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(l.addHours),
                                ),
                            ],
                          ),
                  ),
                  if (_days[d].isNotEmpty)
                    IconButton(
                      tooltip: l.copyToAllDays,
                      onPressed: () => setState(() {
                        final src = [..._days[d]];
                        _days = [
                          for (var x = 0; x < 7; x++) [...src],
                        ];
                      }),
                      icon: Icon(
                        Icons.copy_all_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecialDays extends ConsumerWidget {
  const _SpecialDays({required this.restaurantId, required this.days});
  final String restaurantId;
  final List<SpecialDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat.yMMMMEEEEd(lang);
    return PCard(
      title: l.specialDays,
      subtitle: l.specialDaysHint,
      action: AppButton(
        label: l.addSpecialDay,
        icon: Icons.add_rounded,
        variant: AppButtonVariant.small,
        onPressed: () async {
          final d = await showDialog<SpecialDay>(
            context: context,
            builder: (_) => const _SpecialDayDialog(),
          );
          if (d == null) return;
          try {
            await ref
                .read(outletAdminRepositoryProvider)
                .setSpecialDay(restaurantId, d);
          } catch (_) {
            if (context.mounted) {
              showAppSnack(context, l.errGeneric, error: true);
            }
          }
          ref.invalidate(outletHoursProvider(restaurantId));
          ref.invalidate(myRestaurantsProvider);
        },
      ),
      child: days.isEmpty
          ? Text(l.noSpecialDays, style: TextStyle(color: AppColors.muted))
          : Column(
              children: [
                for (final d in days)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      d.closed ? Icons.event_busy_outlined : Icons.schedule,
                      color: d.closed ? AppColors.danger : AppColors.primary,
                    ),
                    title: Text(fmt.format(d.day)),
                    subtitle: Text(
                      [
                        d.closed ? l.closedAllDay : '${d.opens} – ${d.closes}',
                        if (d.note.isNotEmpty) d.note,
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: l.delete,
                      onPressed: () async {
                        await ref
                            .read(outletAdminRepositoryProvider)
                            .deleteSpecialDay(restaurantId, d.day);
                        ref.invalidate(outletHoursProvider(restaurantId));
                        ref.invalidate(myRestaurantsProvider);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SpecialDayDialog extends StatefulWidget {
  const _SpecialDayDialog();

  @override
  State<_SpecialDayDialog> createState() => _SpecialDayDialogState();
}

class _SpecialDayDialogState extends State<_SpecialDayDialog> {
  DateTime? _day;
  bool _closed = true;
  String _opens = '11:00';
  String _closes = '15:00';
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    return AlertDialog(
      title: Text(l.addSpecialDay),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 1, now.month, now.day),
                  initialDate: _day ?? now,
                );
                if (d != null) setState(() => _day = d);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _day == null
                    ? l.pickDate
                    : DateFormat.yMMMMEEEEd(lang).format(_day!),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _closed,
              activeTrackColor: AppColors.primary,
              title: Text(l.closedAllDay),
              onChanged: (v) => setState(() => _closed = v),
            ),
            if (!_closed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await pickTime(context, _opens);
                        if (t != null) setState(() => _opens = t);
                      },
                      child: Text('${l.opensLabel} $_opens'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await pickTime(context, _closes);
                        if (t != null) setState(() => _closes = t);
                      },
                      child: Text('${l.closesLabel} $_closes'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 80,
              decoration: InputDecoration(
                isDense: true,
                labelText: l.specialDayNote,
                hintText: l.specialDayNoteHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back),
        ),
        AppButton(
          label: l.saveChanges,
          variant: AppButtonVariant.small,
          onPressed: _day == null || (!_closed && _opens == _closes)
              ? null
              : () => Navigator.pop(
                  context,
                  SpecialDay(
                    day: _day!,
                    closed: _closed,
                    opens: _closed ? null : _opens,
                    closes: _closed ? null : _closes,
                    note: _note.text.trim(),
                  ),
                ),
        ),
      ],
    );
  }
}
