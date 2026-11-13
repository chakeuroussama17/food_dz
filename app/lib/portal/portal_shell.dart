import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/pdf/business_info.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/snack.dart';
import '../core/widgets/theme_switch.dart';
import '../core/widgets/widgets.dart';
import '../features/auth/data/auth_providers.dart';
import '../l10n/app_localizations.dart';
import 'portal_state.dart';

/// One entry of the sidebar. [soon] = later step (shown, not clickable).
class PortalNavItem {
  const PortalNavItem(this.path, this.icon, this.label, {this.soon = false});
  final String path;
  final IconData icon;
  final String label;
  final bool soon;
}

List<PortalNavItem> portalNav(AppLocalizations l) => [
  PortalNavItem('/', Icons.space_dashboard_outlined, l.dashboard),
  PortalNavItem('/orders', Icons.receipt_long_outlined, l.orders),
  PortalNavItem('/reports', Icons.insights_outlined, l.navReports),
  PortalNavItem('/invoices', Icons.request_quote_outlined, l.navInvoices),
  PortalNavItem('/outlets', Icons.storefront_outlined, l.outlets),
  PortalNavItem('/team', Icons.group_outlined, l.navTeam),
  PortalNavItem('/menu', Icons.restaurant_menu_outlined, l.navMenu),
  PortalNavItem('/hours', Icons.schedule_outlined, l.navHours),
  PortalNavItem('/reviews', Icons.star_outline_rounded, l.navReviews),
  PortalNavItem(
    '/marketing',
    Icons.campaign_outlined,
    l.navMarketing,
    soon: true,
  ),
  PortalNavItem(
    '/notifications',
    Icons.notifications_none_rounded,
    l.navNotifications,
    soon: true,
  ),
];

/// Sidebar on wide screens, drawer on narrow ones; keeps the live updates
/// running while any portal page is open.
class PortalShell extends ConsumerWidget {
  const PortalShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(portalLiveProvider);
    final outlets = ref.watch(portalOutletsProvider);
    final body = outlets.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => refreshPortal(ref),
          child: Text(AppLocalizations.of(context).retry),
        ),
      ),
      // Staff accounts: the portal needs a manager or owner role.
      data: (list) => list.isEmpty ? const _StaffOnly() : child,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        if (wide) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            body: Row(
              children: [
                SizedBox(width: 248, child: _Sidebar(path: path)),
                VerticalDivider(width: 1, color: AppColors.border),
                Expanded(child: body),
              ],
            ),
          );
        }
        final current = portalNav(
          AppLocalizations.of(context),
        ).where((i) => i.path == path).firstOrNull;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(current?.label ?? ''),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            child: _Sidebar(path: path, inDrawer: true),
          ),
          body: body,
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.path, this.inDrawer = false});
  final String path;
  final bool inDrawer;

  Future<void> _support(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    try {
      final phone = (await ref.read(businessInfoRepositoryProvider).get())
          .businessPhone
          .trim();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final waiting =
        ref
            .watch(portalActiveOrdersProvider)
            .value
            ?.where((o) => o.status == 'placed')
            .length ??
        0;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: const BrandLogo(width: 168, stacked: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Text(
                l.portalTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in portalNav(l))
                    _NavTile(
                      item: item,
                      selected: item.path == path,
                      badge: item.path == '/orders' ? waiting : 0,
                      onTap: item.soon
                          ? null
                          : () {
                              if (inDrawer) Navigator.pop(context);
                              context.go(item.path);
                            },
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            _NavTile(
              item: PortalNavItem(
                '',
                Icons.support_agent_outlined,
                l.helpCenter,
              ),
              onTap: () => _support(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 20,
                    color: AppColors.body,
                  ),
                  const Spacer(),
                  const LanguageSwitch(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    size: 20,
                    color: AppColors.body,
                  ),
                  const Spacer(),
                  const ThemeSwitch(),
                ],
              ),
            ),
            _NavTile(
              item: PortalNavItem('', Icons.logout_rounded, l.logOut),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    this.selected = false,
    this.badge = 0,
    this.onTap,
  });

  final PortalNavItem item;
  final bool selected;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = selected
        ? AppColors.primary
        : item.soon
        ? AppColors.muted
        : AppColors.inkSoft;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : null,
            border: BorderDirectional(
              start: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsetsDirectional.only(start: 17, end: 16),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (badge > 0)
                Badge(label: Text('$badge'), backgroundColor: AppColors.danger),
              if (item.soon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.soon,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staff-only accounts: the portal is for managers and owners.
class _StaffOnly extends ConsumerWidget {
  const _StaffOnly();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.muted,
              ),
              const SizedBox(height: 16),
              Text(
                l.portalStaffOnly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sections of later steps.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 52, color: AppColors.muted),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(l.comingSoonBody, style: TextStyle(color: AppColors.body)),
        ],
      ),
    );
  }
}
