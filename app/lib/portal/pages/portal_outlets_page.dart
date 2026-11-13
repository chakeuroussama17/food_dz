import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/restaurant_owner/data/owner_repository.dart';
import '../../features/restaurant_owner/widgets/owner_widgets.dart'
    show roleLabel;
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';
import '../../features/qr/qr_page.dart';

/// Every outlet the user manages: approval, open / closed, role; owners
/// can add an outlet (it waits for the admin's approval).
class PortalOutletsPage extends ConsumerStatefulWidget {
  const PortalOutletsPage({super.key});

  @override
  ConsumerState<PortalOutletsPage> createState() => _PortalOutletsPageState();
}

class _PortalOutletsPageState extends ConsumerState<PortalOutletsPage> {
  String? _switching;

  Future<void> _setOpen(OwnedRestaurant r, bool open) async {
    final l = AppLocalizations.of(context);
    setState(() => _switching = r.id);
    try {
      await ref.read(ownerRepositoryProvider).setOpen(r.id, open);
      ref.invalidate(myRestaurantsProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _switching = null);
    }
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddOutletDialog(),
    );
    if (added == true && mounted) {
      ref.invalidate(myRestaurantsProvider);
      showAppSnack(context, l.outletAdded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = ref.watch(portalOutletsProvider);
    final owner = list.value?.any((r) => r.isOwner) ?? false;
    return PortalPage(
      title: l.outlets,
      subtitle: l.outletsSubtitle,
      actions: [
        if (owner)
          FilledButton.icon(
            onPressed: _add,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.addOutlet),
          ),
      ],
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final per = c.maxWidth > 1000 ? 3 : (c.maxWidth > 620 ? 2 : 1);
            final w = (c.maxWidth - 16 * (per - 1)) / per;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final r in list.value ?? const <OwnedRestaurant>[])
                  SizedBox(
                    width: w,
                    child: _OutletCard(
                      r: r,
                      switching: _switching == r.id,
                      onOpen: (v) => _setOpen(r, v),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OutletCard extends StatelessWidget {
  const _OutletCard({
    required this.r,
    required this.switching,
    required this.onOpen,
  });

  final OwnedRestaurant r;
  final bool switching;
  final ValueChanged<bool> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasCover = (r.coverUrl ?? '').isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: hasCover
                ? AppImage(url: r.coverUrl, height: 96)
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppImage(url: r.logoUrl, width: 48, height: 48, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            [
                              if (r.area.isNotEmpty) r.area,
                              l.yourRole(roleLabel(l, r.role)),
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Pill(
                      r.isActive ? l.accountApproved : l.accountPending,
                      color: r.isActive ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l.qrTitle,
                      onPressed: () => showRestaurantQrDialog(
                        context,
                        restaurantId: r.id,
                        slug: r.slug,
                        name: r.name,
                      ),
                      icon: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      r.isOpen ? l.openForOrders : l.closedForOrders,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: r.isOpen ? AppColors.success : AppColors.muted,
                      ),
                    ),
                    Switch.adaptive(
                      value: r.isOpen,
                      activeTrackColor: AppColors.primary,
                      onChanged: !r.isActive || switching ? null : onOpen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOutletDialog extends ConsumerStatefulWidget {
  const _AddOutletDialog();

  @override
  ConsumerState<_AddOutletDialog> createState() => _AddOutletDialogState();
}

class _AddOutletDialogState extends ConsumerState<_AddOutletDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerRepositoryProvider)
          .register(
            RestaurantRegistration(
              name: _name.text.trim(),
              phone: normalizeRestaurantPhone(_phone.text)!,
              address: _address.text.trim(),
              area: _area.text.trim(),
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.addOutlet),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledField(
                  label: l.restaurantName,
                  controller: _name,
                  maxLength: 80,
                  validator: (v) =>
                      isValidName(v ?? '') ? null : l.errNameRequired,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: l.restaurantPhone,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (v) => normalizeRestaurantPhone(v ?? '') == null
                      ? l.errRestaurantPhone
                      : null,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: l.address,
                  controller: _address,
                  maxLength: 200,
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? l.errAddressRequired : null,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: l.area,
                  controller: _area,
                  hint: l.areaHint,
                  maxLength: 80,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        AppButton(
          label: l.addOutlet,
          variant: AppButtonVariant.small,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
