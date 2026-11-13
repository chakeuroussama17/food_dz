import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/pdf/business_info.dart';
import '../../../core/push/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/theme_switch.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_widgets.dart';

final _versionProvider = FutureProvider<String>((ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return '';
  }
});

/// Restaurant account: cover + logo card with the approval status, business
/// links (details, orders table, insights, statements), settings, help,
/// log out and account deletion.
class OwnerAccountPage extends ConsumerWidget {
  const OwnerAccountPage({super.key});

  Future<void> _callSupport(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    try {
      final b = await ref.read(businessInfoRepositoryProvider).get();
      final phone = b.businessPhone.trim();
      if (phone.isEmpty) {
        if (context.mounted) showAppSnack(context, l.supportSoon);
        return;
      }
      final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
      if (!ok && context.mounted) showAppSnack(context, phone);
    } catch (_) {
      if (context.mounted) showAppSnack(context, l.errNetwork, error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteRestaurantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back, style: TextStyle(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.deleteAccount,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(ownerRepositoryProvider).deleteMyAccount();
      try {
        await ref.read(pushServiceProvider).stop();
      } catch (_) {
        // The login is gone anyway.
      }
      if (context.mounted) showAppSnack(context, l.accountDeleted);
      await ref.read(authRepositoryProvider).signOut();
    } on DeleteRestaurantError catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, switch (e.failure) {
        DeleteRestaurantFailure.activeOrders => l.errDeleteActiveOrders,
        DeleteRestaurantFailure.cashPending => l.errDeleteCashPending,
        DeleteRestaurantFailure.unpaidCommission => l.errDeleteUnpaidCommission,
        DeleteRestaurantFailure.network => l.errNetwork,
      }, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mine = ref.watch(myRestaurantProvider);
    final version = ref.watch(_versionProvider).value ?? '';
    final section = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.account),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    l.navAccount,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                AsyncBody(
                  value: mine,
                  onRetry: () => ref.invalidate(myRestaurantsProvider),
                  builder: (r) => r == null
                      ? const SizedBox.shrink()
                      : _RestaurantCard(restaurant: r),
                ),
                const SizedBox(height: 24),
                if (mine.value?.canManage ?? true) ...[
                  _Title(l.myBusiness, style: section),
                  _Row(
                    icon: Icons.storefront_outlined,
                    label: l.restaurantProfile,
                    hint: l.restaurantDetailsHint,
                    onTap: () => context.push('/restaurant/profile'),
                  ),
                  _Row(
                    icon: Icons.qr_code_2_rounded,
                    label: l.qrTitle,
                    hint: l.qrHint,
                    onTap: () => context.push('/restaurant/qr'),
                  ),
                  _Row(
                    icon: Icons.table_chart_outlined,
                    label: l.ordersTable,
                    hint: l.exportCsv,
                    onTap: () => context.push('/restaurant/orders/table'),
                  ),
                  _Row(
                    icon: Icons.insights_rounded,
                    label: l.insights,
                    onTap: () => context.go('/restaurant/insights'),
                  ),
                  _Row(
                    icon: Icons.request_quote_outlined,
                    label: l.myStatements,
                    onTap: () => context.push('/restaurant/statements'),
                  ),
                ],
                const SizedBox(height: 16),
                _Title(l.settings, style: section),
                _Row(
                  icon: Icons.translate_rounded,
                  label: l.language,
                  trailing: const LanguageSwitch(),
                ),
                _Row(
                  icon: Icons.dark_mode_outlined,
                  label: l.appearance,
                  trailing: const ThemeSwitch(),
                ),
                const SizedBox(height: 16),
                _Title(l.general, style: section),
                _Row(
                  icon: Icons.help_outline_rounded,
                  label: l.helpCenter,
                  onTap: () => _callSupport(context, ref),
                ),
                _Row(
                  icon: Icons.description_outlined,
                  label: l.termsTitle,
                  onTap: () => context.push('/terms'),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => signOutAndStopPush(ref),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.field,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        l.logOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => _delete(context, ref),
                    child: Text(
                      l.deleteAccount,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
                if (version.isNotEmpty)
                  Center(
                    child: Text(
                      '${l.appVersion} $version',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
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

/// Cover photo with the logo, name, area and approval status.
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});
  final OwnedRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = restaurant;
    final hasCover = (r.coverUrl ?? '').isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/restaurant/profile'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 110,
                child: hasCover
                    ? AppImage(url: r.coverUrl, height: 110)
                    : const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: AppImage(
                        url: r.logoUrl,
                        width: 56,
                        height: 56,
                        radius: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          if (r.area.isNotEmpty)
                            Text(
                              r.area,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.body,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Pill(
                      r.isActive ? l.accountApproved : l.accountPending,
                      color: r.isActive ? AppColors.success : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
    child: Text(text, style: style),
  );
}

/// Same row style as the customer Account page.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.hint,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, color: AppColors.ink),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}
