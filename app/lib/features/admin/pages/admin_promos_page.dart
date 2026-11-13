import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../data/promo_repository.dart';
import '../widgets/admin_widgets.dart';

/// Promo codes: create (% or fixed DA, minimum, limits, expiry, one
/// restaurant or all, who pays), turn on / off, see uses.
class AdminPromosPage extends ConsumerWidget {
  const AdminPromosPage({super.key});

  Future<void> _edit(BuildContext context, [PromoCode? code]) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        builder: (_) => _PromoForm(code: code),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final codes = ref.watch(promoCodesProvider);
    return AdminScaffold(
      section: AdminSection.promos,
      title: l.navPromos,
      floatingAction: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.promoNew),
      ),
      body: codes.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(promoCodesProvider),
            child: Text(l.retry),
          ),
        ),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(l.noPromos, style: TextStyle(color: AppColors.body)),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(promoCodesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PromoCard(
                    code: list[i],
                    onEdit: () => _edit(context, list[i]),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A code drawn as a ticket: value on the left, rules on the right.
class _PromoCard extends ConsumerStatefulWidget {
  const _PromoCard({required this.code, required this.onEdit});
  final PromoCode code;
  final VoidCallback onEdit;

  @override
  ConsumerState<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends ConsumerState<_PromoCard> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      await ref.read(promoRepositoryProvider).setActive(widget.code.id, on);
      ref.invalidate(promoCodesProvider);
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).errGeneric,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final c = widget.code;
    final live = c.isActive && !c.expired && !c.usedUp;
    final accent = live ? AppColors.primary : AppColors.muted;
    Widget tag(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.body),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: AppColors.body)),
        ],
      ),
    );
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onEdit,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Value stub.
              Container(
                width: 92,
                color: accent.withValues(alpha: .12),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  child: Text(
                    c.isPercent
                        ? '−${c.value}%'
                        : '−${formatDzd(c.value, lang)}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.code,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l.copy,
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: c.code));
                              showAppSnack(context, l.copied);
                            },
                          ),
                          Switch.adaptive(
                            value: c.isActive,
                            activeTrackColor: AppColors.success,
                            onChanged: _busy ? null : _toggle,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          tag(
                            Icons.storefront_rounded,
                            c.restaurantName ?? l.promoAllRestaurants,
                          ),
                          if (c.minOrder > 0)
                            tag(
                              Icons.shopping_basket_outlined,
                              l.promoMin(formatDzd(c.minOrder, lang)),
                            ),
                          if (c.isPercent && c.maxDiscount != null)
                            tag(
                              Icons.vertical_align_top_rounded,
                              'max ${formatDzd(c.maxDiscount!, lang)}',
                            ),
                          tag(
                            Icons.people_alt_outlined,
                            c.maxUses == null
                                ? l.promoUses(c.uses)
                                : '${c.uses}/${c.maxUses}',
                          ),
                          if (c.perCustomer != null)
                            tag(Icons.person_outline, '${c.perCustomer}×'),
                          tag(
                            Icons.event_outlined,
                            c.endsAt == null
                                ? l.promoNoEnd
                                : DateFormat('dd/MM/yyyy').format(c.endsAt!),
                          ),
                          tag(
                            Icons.account_balance_outlined,
                            c.fundedBy == 'restaurant'
                                ? l.fundedRestaurant
                                : l.fundedPlatform,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          c.isActive ? l.promoActive : l.promoInactive,
                          l.promoGiven(formatDzd(c.discountGiven, lang)),
                          if (c.note.isNotEmpty) c.note,
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// New or edited code.
class _PromoForm extends ConsumerStatefulWidget {
  const _PromoForm({this.code});
  final PromoCode? code;

  @override
  ConsumerState<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends ConsumerState<_PromoForm> {
  late final c = widget.code;
  late final _code = TextEditingController(text: c?.code ?? '');
  late final _value = TextEditingController(
    text: c == null ? '' : '${c!.value}',
  );
  late final _max = TextEditingController(text: _s(c?.maxDiscount));
  late final _min = TextEditingController(
    text: c == null || c!.minOrder == 0 ? '' : '${c!.minOrder}',
  );
  late final _uses = TextEditingController(text: _s(c?.maxUses));
  late final _perCustomer = TextEditingController(text: _s(c?.perCustomer));
  late final _note = TextEditingController(text: c?.note ?? '');
  late String _kind = c?.kind ?? 'percent';
  late String _funded = c?.fundedBy ?? 'platform';
  late String? _restaurant = c?.restaurantId;
  late DateTime? _ends = c?.endsAt;
  bool _saving = false;
  String? _error;

  static String _s(int? v) => v == null ? '' : '$v';
  static int? _n(TextEditingController t) => int.tryParse(t.text.trim());

  @override
  void dispose() {
    for (final t in [_code, _value, _max, _min, _uses, _perCustomer, _note]) {
      t.dispose();
    }
    super.dispose();
  }

  /// "FOOD" + 4 letters/digits, easy to read (no 0/O, 1/I).
  void _generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    _code.text =
        'FOOD${List.generate(4, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _ends ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d != null) {
      setState(() => _ends = DateTime(d.year, d.month, d.day, 23, 59));
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final value = _n(_value);
    if (value == null) {
      setState(() => _error = l.errPromoValue);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(promoRepositoryProvider)
          .save(
            PromoInput(
              id: c?.id,
              code: _code.text.trim().toUpperCase(),
              kind: _kind,
              value: value,
              maxDiscount: _kind == 'percent' ? _n(_max) : null,
              minOrder: _n(_min) ?? 0,
              maxUses: _n(_uses),
              perCustomer: _n(_perCustomer),
              endsAt: _ends,
              restaurantId: _restaurant,
              fundedBy: _funded,
              note: _note.text.trim(),
            ),
          );
      ref.invalidate(promoCodesProvider);
      if (mounted) Navigator.of(context).pop();
    } on PromoError catch (e) {
      setState(
        () => _error = switch (e.failure) {
          PromoFailure.invalidCode => l.errPromoCode,
          PromoFailure.codeTaken => l.errPromoTaken,
          PromoFailure.invalidValue => l.errPromoValue,
          PromoFailure.network => l.errNetwork,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final restaurants = ref.watch(adminRestaurantsProvider).value ?? const [];
    InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    Widget num(TextEditingController t, String label, {String? hint}) =>
        TextField(
          controller: t,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: deco(label, hint: hint),
        );
    Widget pair(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                c == null ? l.promoNew : l.promoEdit,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      style: const TextStyle(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: deco(l.promoCode, hint: 'BIENVENUE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Auto',
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'percent',
                    icon: const Icon(Icons.percent_rounded),
                    label: Text(l.promoKindPercent),
                  ),
                  ButtonSegment(
                    value: 'amount',
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l.promoKindAmount),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
              pair(
                num(
                  _value,
                  _kind == 'percent' ? l.promoValuePercent : l.promoValueAmount,
                ),
                _kind == 'percent'
                    ? num(_max, l.promoMaxDiscount, hint: l.optional)
                    : num(_min, l.promoMinOrder, hint: l.optional),
              ),
              if (_kind == 'percent') ...[
                const SizedBox(height: 12),
                num(_min, l.promoMinOrder, hint: l.optional),
              ],
              const SizedBox(height: 12),
              pair(
                num(_uses, l.promoMaxUses, hint: l.optional),
                num(_perCustomer, l.promoPerCustomer, hint: l.optional),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _restaurant,
                isExpanded: true,
                decoration: deco(l.promoRestaurant),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.promoAllRestaurants),
                  ),
                  for (final r in restaurants)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _restaurant = v),
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l.promoEnds),
                  subtitle: Text(
                    _ends == null
                        ? l.promoNoEnd
                        : DateFormat('dd/MM/yyyy').format(_ends!),
                  ),
                  trailing: _ends == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _ends = null),
                        ),
                  onTap: _pickEnd,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.promoFundedBy,
                style: TextStyle(
                  color: AppColors.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'platform',
                    label: Text(l.fundedPlatform),
                  ),
                  ButtonSegment(
                    value: 'restaurant',
                    label: Text(l.fundedRestaurant),
                  ),
                ],
                selected: {_funded},
                onSelectionChanged: (s) => setState(() => _funded = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 200,
                decoration: deco(l.promoNote, hint: l.optional),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              AppButton(label: l.save, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
