import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/data/wilayas.dart';
import '../../../core/files/file_output.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../restaurant_owner/insights/orders_csv.dart' show csvBytes;
import '../../sanctions/sanction_widgets.dart';
import '../../sanctions/sanctions_repository.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

final customerInsightsProvider = FutureProvider<CustomerInsights>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(adminRepositoryProvider).customerInsights();
});

final adminCustomersProvider =
    FutureProvider.family<List<AdminCustomer>, String>((ref, search) {
      ref.watch(currentUserIdProvider);
      return ref
          .watch(adminRepositoryProvider)
          .customers(search: search, limit: 200);
    });

/// Customers: who they are (summary for analysis), who to watch (3+
/// cancellations in 30 days), the list with a detail sheet to warn,
/// suspend or ban, and a CSV export of everything.
class AdminCustomersPage extends ConsumerStatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  ConsumerState<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends ConsumerState<AdminCustomersPage> {
  String _search = '';
  bool _watch = false;
  bool _exporting = false;

  void _refresh() {
    ref.invalidate(adminCustomersProvider);
    ref.invalidate(customerInsightsProvider);
    ref.invalidate(watchlistProvider);
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      final all = await ref
          .read(adminRepositoryProvider)
          .customers(limit: 5000);
      await ref
          .read(fileOutputProvider)
          .save(
            csvBytes(customersCsv(all)),
            'foodfennec-customers-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
            'text/csv',
          );
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final watch = ref.watch(watchlistProvider).value ?? const [];
    final list = ref.watch(adminCustomersProvider(_search));
    return AdminScaffold(
      section: AdminSection.customers,
      title: l.customers,
      actions: [
        TextButton.icon(
          key: const Key('export-customers'),
          onPressed: _exporting ? null : _export,
          icon: const Icon(Icons.download_rounded),
          label: Text(l.exportCsv),
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const _InsightsPanel(),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.allCustomers)),
                ButtonSegment(
                  value: true,
                  label: Text(l.watchlistTab(watch.length)),
                  icon: watch.isEmpty
                      ? null
                      : const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE8A317),
                        ),
                ),
              ],
              selected: {_watch},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _watch = v.first),
            ),
            const SizedBox(height: 14),
            if (_watch) ...[
              Text(
                l.watchlistHelp,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              if (watch.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l.watchlistEmpty,
                      style: TextStyle(color: AppColors.body),
                    ),
                  ),
                ),
              for (final w in watch)
                _WatchTile(
                  entry: w,
                  onTap: () => showCustomerSheet(
                    context,
                    userId: w.userId,
                    name: w.fullName.isEmpty ? w.email : w.fullName,
                    customer: null,
                    onChanged: _refresh,
                  ),
                ),
            ] else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: l.searchCustomers,
                  prefixIcon: const Icon(Icons.search_rounded),
                  fillColor: AppColors.surface,
                ),
                onSubmitted: (v) => setState(() => _search = v.trim()),
              ),
              const SizedBox(height: 12),
              switch (list) {
                AsyncData(:final value) => AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final c in value)
                        _CustomerTile(
                          customer: c,
                          onTap: () => showCustomerSheet(
                            context,
                            userId: c.id,
                            name: c.fullName.isEmpty ? c.email : c.fullName,
                            customer: c,
                            onChanged: _refresh,
                          ),
                        ),
                    ],
                  ),
                ),
                AsyncError() => Center(
                  child: TextButton(
                    onPressed: _refresh,
                    child: Text('${l.loadError}\n${l.retry}'),
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              },
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightsPanel extends ConsumerWidget {
  const _InsightsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = ref.watch(customerInsightsProvider).value;
    if (s == null) return const SizedBox(height: 4);
    String pct(int n) =>
        s.customers == 0 ? '0 %' : '${(n * 100 / s.customers).round()} %';
    Widget stat(String value, String label, IconData icon, Color color) =>
        Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        );
    String key(String group, String k) => switch ((group, k)) {
      (_, 'unknown') => l.unknownValue,
      ('gender', 'male') => l.genderMale,
      ('gender', 'female') => l.genderFemale,
      ('wilaya', _) => wilayaLabel(int.tryParse(k) ?? 0, lang),
      ('referral', 'friend') => l.refFriend,
      ('referral', 'social') => l.refSocial,
      ('referral', 'search') => l.refSearch,
      ('referral', 'restaurant') => l.refRestaurant,
      ('referral', 'ad') => l.refAd,
      ('referral', 'other') => l.refOther,
      ('platform', 'android') => 'Android',
      ('platform', 'ios') => 'iPhone',
      ('platform', 'web') => 'Web',
      _ => k,
    };
    Widget breakdown(String title, String group, Map<String, int> m) {
      final entries = m.entries.toList()
        ..sort((a, b) {
          if (a.key == 'unknown') return 1;
          if (b.key == 'unknown') return -1;
          return b.value.compareTo(a.value);
        });
      final total = m.values.fold(0, (a, b) => a + b);
      return Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final e in entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key(group, e.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.body,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : e.value / total,
                        minHeight: 5,
                        color: e.key == 'unknown'
                            ? AppColors.border
                            : AppColors.primary,
                        backgroundColor: AppColors.field,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            stat(
              '${s.customers}',
              l.statCustomers,
              Icons.people_outline_rounded,
              AppColors.primary,
            ),
            stat(
              '+${s.new7d}',
              l.statNew7d,
              Icons.person_add_alt_rounded,
              AppColors.success,
            ),
            stat(
              '${s.active7d}',
              l.statActive7d(s.active1d),
              Icons.bolt_rounded,
              const Color(0xFF413DFB),
            ),
            stat(
              pct(s.ordered),
              l.statOrdered,
              Icons.shopping_bag_outlined,
              AppColors.primary,
            ),
            stat(
              pct(s.profileDone),
              l.statProfileDone,
              Icons.badge_outlined,
              const Color(0xFF7C6FD6),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            breakdown(l.wilaya, 'wilaya', s.wilaya),
            breakdown(l.ageGroups, 'age', s.age),
            breakdown(l.gender, 'gender', s.gender),
            breakdown(l.heardFrom, 'referral', s.referral),
            breakdown(l.platformLabel, 'platform', s.platform),
          ],
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});
  final AdminCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final c = customer;
    return ListTile(
      key: Key('customer:${c.id}'),
      onTap: onTap,
      title: Row(
        children: [
          Flexible(
            child: Text(
              c.fullName.isEmpty ? c.email : c.fullName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (c.restriction != null) ...[
            const SizedBox(width: 8),
            RestrictionPill(kind: c.restriction!),
          ] else if (c.cancels30d >= 3) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Color(0xFFE8A317),
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          c.email,
          c.phone ?? '',
          if (c.wilaya != null) wilayaLabel(c.wilaya!, lang),
        ].where((x) => x.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(l.ordersCount(c.ordersCount)),
          Text(
            formatDzd(c.spent, lang),
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _WatchTile extends StatelessWidget {
  const _WatchTile({required this.entry, required this.onTap});
  final WatchlistEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = entry;
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8A317)),
      ),
      child: ListTile(
        key: Key('watch:${w.userId}'),
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0x22E8A317),
          child: Icon(Icons.warning_amber_rounded, color: Color(0xFFE8A317)),
        ),
        title: Text(w.fullName.isEmpty ? w.email : w.fullName),
        subtitle: Text(
          [
            l.cancels30d(w.cancels30d),
            if (w.openReports > 0) l.openReports(w.openReports),
            w.phone ?? '',
          ].where((x) => x.isNotEmpty).join(' · '),
        ),
        trailing: w.restricted
            ? Icon(Icons.lock_rounded, color: AppColors.danger)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// Everything about a customer, and their sanctions with the buttons.
/// [customer] null: only the sanctions part (e.g. from the watchlist).
Future<void> showCustomerSheet(
  BuildContext context, {
  required String userId,
  required String name,
  required AdminCustomer? customer,
  VoidCallback? onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.canvas,
  constraints: const BoxConstraints(maxWidth: 720),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (ctx) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .85,
    maxChildSize: .95,
    builder: (ctx, scroll) => _CustomerSheet(
      scroll: scroll,
      userId: userId,
      name: name,
      customer: customer,
      onChanged: onChanged,
    ),
  ),
);

class _CustomerSheet extends StatelessWidget {
  const _CustomerSheet({
    required this.scroll,
    required this.userId,
    required this.name,
    required this.customer,
    this.onChanged,
  });

  final ScrollController scroll;
  final String userId;
  final String name;
  final AdminCustomer? customer;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final date = DateFormat('d MMM yyyy', lang);
    final dateTime = DateFormat('d MMM yyyy · HH:mm', lang);
    final c = customer;
    Widget fact(String label, String? value) => SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              (value == null || value.isEmpty) ? '—' : value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
    String? referral(String? r) => switch (r) {
      'friend' => l.refFriend,
      'social' => l.refSocial,
      'search' => l.refSearch,
      'restaurant' => l.refRestaurant,
      'ad' => l.refAd,
      'other' => l.refOther,
      _ => null,
    };
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (c?.restriction != null) RestrictionPill(kind: c!.restriction!),
          ],
        ),
        if (c != null) ...[
          Text(
            [c.email, c.phone ?? ''].where((x) => x.isNotEmpty).join(' · '),
            style: TextStyle(color: AppColors.body),
          ),
          const SizedBox(height: 12),
          title(l.profile),
          Wrap(
            children: [
              fact(l.ageLabel, c.age?.toString()),
              fact(
                l.gender,
                c.gender == 'male'
                    ? l.genderMale
                    : c.gender == 'female'
                    ? l.genderFemale
                    : null,
              ),
              fact(
                l.wilaya,
                c.wilaya == null ? null : wilayaLabel(c.wilaya!, lang),
              ),
              fact(l.commune, c.commune),
              fact(l.heardFrom, referral(c.referral)),
              fact(
                l.memberSince,
                c.createdAt == null ? null : date.format(c.createdAt!),
              ),
            ],
          ),
          title(l.deviceAndActivity),
          Wrap(
            children: [
              fact(
                l.lastSeen,
                c.lastSeenAt == null ? null : dateTime.format(c.lastSeenAt!),
              ),
              fact(l.activeDays30, '${c.activeDays30}'),
              fact(
                l.platformLabel,
                [
                  switch (c.lastPlatform ?? c.signupPlatform) {
                    'android' => 'Android',
                    'ios' => 'iPhone',
                    'web' => 'Web',
                    _ => '',
                  },
                  c.lastAppVersion ?? '',
                ].where((x) => x.isNotEmpty).join(' · '),
              ),
              fact(
                l.deviceLabel,
                [
                  c.lastDevice ?? '',
                  c.lastOs ?? '',
                ].where((x) => x.isNotEmpty).join(' · '),
              ),
              fact(l.language, c.lastLang?.toUpperCase()),
            ],
          ),
          title(l.orders),
          Wrap(
            children: [
              fact(l.ordersTotal, '${c.ordersCount}'),
              fact(l.statusDelivered, '${c.deliveredCount}'),
              fact(l.statusCancelled, '${c.cancelledCount}'),
              fact(l.cancels30dLabel, '${c.cancels30d}'),
              fact(l.spentLabel, formatDzd(c.spent, lang)),
              fact(
                l.lastOrder,
                c.lastOrderAt == null ? null : date.format(c.lastOrderAt!),
              ),
            ],
          ),
        ],
        title(l.sanctionsTitle),
        UserSanctionsSection(userId: userId, onChanged: onChanged),
      ],
    );
  }
}

/// All customers as a CSV for analysis (Excel / Google Sheets / Python).
/// Column names stay in English whatever the app language.
String customersCsv(List<AdminCustomer> list) {
  String d(DateTime? t) => t == null ? '' : DateFormat('yyyy-MM-dd').format(t);
  String dt(DateTime? t) =>
      t == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(t);
  String cell(Object? v) {
    final s = '${v ?? ''}';
    final safe = RegExp(r'^[=+\-@]').hasMatch(s) && v is String ? "'$s" : s;
    return safe.contains(RegExp('[;"\n\r]'))
        ? '"${safe.replaceAll('"', '""')}"'
        : safe;
  }

  final rows = <List<Object?>>[
    [
      'id',
      'name',
      'email',
      'phone',
      'signed_up',
      'birth_date',
      'age',
      'gender',
      'wilaya',
      'commune',
      'heard_from',
      'signup_platform',
      'last_platform',
      'app_version',
      'device',
      'os',
      'language',
      'last_seen',
      'active_days_30',
      'orders',
      'delivered',
      'cancelled',
      'cancels_30d',
      'spent_da',
      'last_order',
      'warnings',
      'restriction',
    ],
    for (final c in list)
      [
        c.id,
        c.fullName,
        c.email,
        c.phone,
        d(c.createdAt),
        d(c.birthDate),
        c.age,
        c.gender,
        c.wilaya,
        c.commune,
        c.referral,
        c.signupPlatform,
        c.lastPlatform,
        c.lastAppVersion,
        c.lastDevice,
        c.lastOs,
        c.lastLang,
        dt(c.lastSeenAt),
        c.activeDays30,
        c.ordersCount,
        c.deliveredCount,
        c.cancelledCount,
        c.cancels30d,
        c.spent,
        d(c.lastOrderAt),
        c.warnings,
        c.restriction,
      ],
  ];
  return rows.map((r) => r.map(cell).join(';')).join('\r\n');
}
