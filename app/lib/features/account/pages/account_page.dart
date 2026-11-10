import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/pdf/business_info.dart';
import '../../../core/push/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/customer_nav_bar.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../cart/cart_controller.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/account_repository.dart';
import '../widgets/account_widgets.dart';

final _versionProvider = FutureProvider<String>((ref) async {
  try {
    final i = await PackageInfo.fromPlatform();
    return i.version;
  } catch (_) {
    return '';
  }
});

/// Account: name + "View profile", shortcut cards, settings, general links,
/// log out, delete account, app version.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  Future<void> _logOut(WidgetRef ref) async {
    ref.read(cartProvider.notifier).clear();
    await signOutAndStopPush(ref);
  }

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

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back, style: const TextStyle(color: AppColors.body)),
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
      await ref.read(pushServiceProvider).stop();
      await ref.read(accountRepositoryProvider).deleteMyAccount();
      ref.read(cartProvider.notifier).clear();
      if (context.mounted) showAppSnack(context, l.accountDeleted);
      await ref.read(authRepositoryProvider).signOut();
    } on DeleteAccountError catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, switch (e.failure) {
        DeleteAccountFailure.activeOrders => l.errDeleteActiveOrders,
        DeleteAccountFailure.notCustomer => l.errDeleteNotCustomer,
        DeleteAccountFailure.network => l.errNetwork,
      }, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final version = ref.watch(_versionProvider).value ?? '';
    const sectionTitle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomerNavBar(current: CustomerTab.account),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l.navAccount,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                AsyncBody(
                  value: profile,
                  onRetry: () => ref.invalidate(profileProvider),
                  builder: (p) => InkWell(
                    onTap: () => context.push('/account/personal'),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName.isEmpty ? p.email : p.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.viewProfile,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Avatar(url: p.avatarUrl, name: p.fullName, size: 64),
                        ],
                      ),
                    ),
                  ),
                ),
                // Shortcut cards.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final (icon, label, path) in [
                        (Icons.receipt_long_outlined, l.orders, '/orders'),
                        (
                          Icons.place_outlined,
                          l.addresses,
                          '/account/addresses',
                        ),
                        (
                          Icons.person_outline_rounded,
                          l.profile,
                          '/account/edit',
                        ),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _ShortcutCard(
                              icon: icon,
                              label: label,
                              onTap: () => path == '/orders'
                                  ? context.go(path)
                                  : context.push(path),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l.settings, style: sectionTitle),
                ),
                _Row(
                  icon: Icons.translate_rounded,
                  label: l.language,
                  trailing: const LanguageSwitch(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l.general, style: sectionTitle),
                ),
                _Row(
                  icon: Icons.help_outline_rounded,
                  label: l.helpCenter,
                  onTap: () => _callSupport(context, ref),
                ),
                _Row(
                  icon: Icons.storefront_outlined,
                  label: l.becomePartner,
                  onTap: () => context.push('/restaurant/register'),
                ),
                _Row(
                  icon: Icons.delivery_dining_outlined,
                  label: l.becomeDriver,
                  onTap: () => context.push('/driver/register'),
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
                      onPressed: () => _logOut(ref),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.field,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        l.logOut,
                        style: const TextStyle(
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
                    onPressed: () => _deleteAccount(context, ref),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
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

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.ink, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.ink),
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
        ],
      ),
    ),
  );
}
