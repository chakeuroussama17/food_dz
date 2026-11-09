import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

enum _Filter { all, pending, active, inactive }

/// All restaurants: approve / deactivate / reactivate, commission rate,
/// owner contact, commission still to bill.
class AdminRestaurantsPage extends ConsumerStatefulWidget {
  const AdminRestaurantsPage({super.key});

  @override
  ConsumerState<AdminRestaurantsPage> createState() =>
      _AdminRestaurantsPageState();
}

class _AdminRestaurantsPageState extends ConsumerState<AdminRestaurantsPage> {
  _Filter _filter = _Filter.all;
  String? _busyId;

  Future<void> _run(String id, Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busyId = id);
    try {
      await action();
      ref.invalidate(adminRestaurantsProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _editRate(AdminRestaurant r) async {
    // null = cancelled, -1 = use default, else the new rate.
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _RateDialog(restaurant: r),
    );
    if (result == null) return;
    await _run(
      r.id,
      () => ref
          .read(adminRepositoryProvider)
          .setCommission(r.id, result < 0 ? null : result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = ref.watch(adminRestaurantsProvider);
    final filters = {
      _Filter.all: l.all,
      _Filter.pending: l.filterPending,
      _Filter.active: l.filterActive,
      _Filter.inactive: l.filterInactive,
    };
    return AdminScaffold(
      section: AdminSection.restaurants,
      title: l.restaurantsTitle,
      actions: [
        IconButton(
          tooltip: l.retry,
          onPressed: () => ref.invalidate(adminRestaurantsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(adminRestaurantsProvider),
        builder: (all) {
          final shown = all
              .where(
                (r) => switch (_filter) {
                  _Filter.all => true,
                  _Filter.pending => r.isPending,
                  _Filter.active => r.isActive,
                  _Filter.inactive => !r.isActive && !r.isPending,
                },
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final e in filters.entries)
                    ChoiceChip(
                      label: Text(
                        e.key == _Filter.pending
                            ? '${e.value} (${all.where((r) => r.isPending).length})'
                            : e.value,
                      ),
                      selected: _filter == e.key,
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: _filter == e.key ? Colors.white : AppColors.ink,
                      ),
                      onSelected: (_) => setState(() => _filter = e.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      l.noRestaurants,
                      style: const TextStyle(color: AppColors.body),
                    ),
                  ),
                ),
              for (final r in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RestaurantTile(
                    restaurant: r,
                    busy: _busyId == r.id,
                    onApprove: () => _run(
                      r.id,
                      () => ref
                          .read(adminRepositoryProvider)
                          .setActive(r.id, true),
                    ),
                    onDeactivate: () => _run(
                      r.id,
                      () => ref
                          .read(adminRepositoryProvider)
                          .setActive(r.id, false),
                    ),
                    onRate: () => _editRate(r),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({
    required this.restaurant,
    required this.busy,
    required this.onApprove,
    required this.onDeactivate,
    required this.onRate,
  });

  final AdminRestaurant restaurant;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDeactivate;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = restaurant;
    final (statusText, statusColor) = r.isPending
        ? (l.filterPending, AppColors.primary)
        : r.isActive
        ? (r.isOpen ? l.open : l.closed, AppColors.success)
        : (l.filterInactive, AppColors.danger);
    final details = [
      if (r.ownerName.isNotEmpty || r.ownerEmail.isNotEmpty)
        '${l.owner}: ${[r.ownerName, r.ownerEmail].where((x) => x.isNotEmpty).join(' · ')}',
      [r.phone, r.address, r.area].where((x) => x.isNotEmpty).join(' · '),
    ].where((x) => x.isNotEmpty);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Pill(statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          for (final d in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                d,
                style: const TextStyle(fontSize: 13, color: AppColors.body),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: busy ? null : onRate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.percent_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.commissionRate == null
                          ? l.defaultRate(percent(r.effectiveRate))
                          : percent(r.effectiveRate),
                      style: const TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l.deliveredCount(r.deliveredCount),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (r.unbilledCommission > 0)
                Text(
                  l.toBill(formatDzd(r.unbilledCommission, lang)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              const SizedBox(width: 8),
              if (!r.isActive)
                AppButton(
                  label: r.isPending ? l.approve : l.reactivate,
                  variant: AppButtonVariant.small,
                  loading: busy,
                  onPressed: onApprove,
                )
              else
                AppButton(
                  label: l.deactivate,
                  variant: AppButtonVariant.dangerOutline,
                  loading: busy,
                  onPressed: onDeactivate,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Commission rate dialog. Owns its text controller so it is disposed only
/// when the dialog is gone (not while it is still animating out).
class _RateDialog extends StatefulWidget {
  const _RateDialog({required this.restaurant});
  final AdminRestaurant restaurant;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  final _form = GlobalKey<FormState>();
  late final _ctrl = TextEditingController(
    text: widget.restaurant.commissionRate == null
        ? ''
        : percent(widget.restaurant.commissionRate!).replaceAll(' %', ''),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l.commissionRate} · ${widget.restaurant.name}'),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(suffixText: '%'),
          validator: (v) {
            final n = double.tryParse((v ?? '').replaceAll(',', '.'));
            return n == null || n < 0 || n > 50 ? l.errRate : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, -1.0),
          child: Text(l.useDefault),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              double.parse(_ctrl.text.replaceAll(',', '.')) / 100,
            );
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
