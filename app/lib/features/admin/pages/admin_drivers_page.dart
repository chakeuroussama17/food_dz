import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_drivers.dart';
import '../widgets/admin_widgets.dart';

/// Drivers: approve / deactivate, online now, current order, deliveries.
class AdminDriversPage extends ConsumerStatefulWidget {
  const AdminDriversPage({super.key});

  @override
  ConsumerState<AdminDriversPage> createState() => _AdminDriversPageState();
}

class _AdminDriversPageState extends ConsumerState<AdminDriversPage> {
  String? _busyId;

  Future<void> _set(AdminDriver d, bool approved) async {
    final l = AppLocalizations.of(context);
    setState(() => _busyId = d.id);
    try {
      await ref
          .read(adminDriversRepositoryProvider)
          .setApproved(d.id, approved);
      ref.invalidate(adminDriversProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _vehicle(AppLocalizations l, String v) => switch (v) {
    'moto' => l.vehicleMoto,
    'car' => l.vehicleCar,
    'bike' => l.vehicleBike,
    _ => v,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = ref.watch(adminDriversProvider);
    final lang = Localizations.localeOf(context).languageCode;
    return AdminScaffold(
      section: AdminSection.drivers,
      title: l.driversTitle,
      actions: [
        IconButton(
          tooltip: l.retry,
          onPressed: () => ref.invalidate(adminDriversProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(adminDriversProvider),
        builder: (drivers) => drivers.isEmpty
            ? Center(
                child: Text(
                  l.noDrivers,
                  style: const TextStyle(color: AppColors.body),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: drivers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final d = drivers[i];
                  final busy = _busyId == d.id;
                  return AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.fullName.isEmpty ? d.email : d.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (d.cashBlocked)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 6,
                                ),
                                child: Pill(
                                  l.cashBlockedPill,
                                  color: AppColors.danger,
                                ),
                              ),
                            if (!d.isApproved)
                              Pill(l.filterPending, color: AppColors.primary)
                            else
                              Pill(
                                d.isOnline ? l.onlineLabel : l.offlineLabel,
                                color: d.isOnline
                                    ? AppColors.success
                                    : AppColors.muted,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            _vehicle(l, d.vehicle),
                            d.phone,
                            if (d.email.isNotEmpty) d.email,
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.body),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            '${l.statDelivered}: ${d.deliveredCount}',
                            if (d.activeOrderCode != null)
                              l.currentOrderCode(d.activeOrderCode!),
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.body),
                        ),
                        if (d.cashOwed > 0)
                          Text(
                            l.cashOwedLine(
                              formatDzd(d.cashOwed, lang),
                              d.cashOwedCount,
                            ),
                            style: TextStyle(
                              color: d.cashBlocked
                                  ? AppColors.danger
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: d.isApproved
                              ? AppButton(
                                  label: l.deactivate,
                                  variant: AppButtonVariant.dangerOutline,
                                  loading: busy,
                                  onPressed: busy ? null : () => _set(d, false),
                                )
                              : AppButton(
                                  label: l.approve,
                                  variant: AppButtonVariant.small,
                                  loading: busy,
                                  onPressed: busy ? null : () => _set(d, true),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
