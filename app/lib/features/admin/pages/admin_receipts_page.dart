import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

/// All commission receipts (newest first) + "New receipt".
class AdminReceiptsPage extends ConsumerWidget {
  const AdminReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(adminStatementsProvider);
    final fmt = DateFormat('dd/MM/yyyy');
    return AdminScaffold(
      section: AdminSection.receipts,
      title: l.receipts,
      floatingAction: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/admin/receipts/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newReceipt),
      ),
      body: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(adminStatementsProvider),
        builder: (all) => all.isEmpty
            ? Center(
                child: Text(
                  l.noReceipts,
                  style: TextStyle(color: AppColors.body),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                children: [
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final s in all)
                          ListTile(
                            onTap: () =>
                                context.push('/admin/receipts/${s.id}'),
                            title: Text(
                              '${s.number} · ${s.restaurantName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${fmt.format(s.periodStart)} – ${fmt.format(s.periodEnd)} · ${l.ordersCount(s.ordersCount)}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatDzd(s.commissionTotal, lang),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Pill(
                                  s.isPaid ? l.statusPaid : l.statusUnpaid,
                                  color: s.isPaid
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
