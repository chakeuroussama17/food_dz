import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/account_repository.dart';

IconData addressIcon(AddressLabel l) => switch (l) {
  AddressLabel.home => Icons.home_outlined,
  AddressLabel.work => Icons.work_outline_rounded,
  AddressLabel.other => Icons.location_on_outlined,
};

String addressLabelText(AppLocalizations l, AddressLabel a) => switch (a) {
  AddressLabel.home => l.labelHome,
  AddressLabel.work => l.labelWork,
  AddressLabel.other => l.labelOther,
};

/// My addresses: cards with label, address, edit / delete; tap a card to
/// make it the default delivery address. ADD NEW ADDRESS at the bottom.
class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Address a) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteAddressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppColors.body),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(accountRepositoryProvider).deleteAddress(a.id);
      ref.invalidate(addressesProvider);
    } catch (_) {
      if (context.mounted) showAppSnack(context, l.errGeneric, error: true);
    }
  }

  Future<void> _makeDefault(
    BuildContext context,
    WidgetRef ref,
    Address a,
  ) async {
    if (a.isDefault) return;
    try {
      await ref.read(accountRepositoryProvider).setDefaultAddress(a.id);
      ref.invalidate(addressesProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).errGeneric,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(title: l.addresses),
                Expanded(
                  child: AsyncBody(
                    value: addresses,
                    onRetry: () => ref.invalidate(addressesProvider),
                    builder: (list) => list.isEmpty
                        ? Center(
                            child: Text(
                              l.noAddresses,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.body,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: [
                              for (final a in list)
                                _AddressCard(
                                  address: a,
                                  onTap: () => _makeDefault(context, ref, a),
                                  onEdit: () => context.push(
                                    '/account/addresses/${a.id}',
                                    extra: a,
                                  ),
                                  onDelete: () => _delete(context, ref, a),
                                ),
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppButton(
                    label: l.addNewAddress,
                    onPressed: (addresses.value?.length ?? 0) >= 10
                        ? null
                        : () => context.push('/account/addresses/new'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = address;
    final line2 = [a.area, a.details].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: a.isDefault ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    addressIcon(a.label),
                    color: const Color(0xFF2790C3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            addressLabelText(l, a.label).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.defaultTag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.addressText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6E82),
                        ),
                      ),
                      if (line2.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          line2,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.edit,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: l.delete,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
