import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/owner_live.dart';
import '../data/owner_repository.dart';

enum OwnerTab { dashboard, orders, menu, insights, account }

/// Floating bottom bar on the restaurant's main pages (same look as the
/// customer one): Home, Orders (with how many wait), Menu, Insights,
/// Account. It is on every main restaurant page, so it also keeps the live
/// orders listener (and the new-order sound) running.
class OwnerBottomBar extends ConsumerWidget {
  const OwnerBottomBar({super.key, required this.current});
  final OwnerTab current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final waiting = ref.watch(ownerLiveProvider.select((s) => s.newCount));
    // Staff only handle orders: no menu or insights tabs.
    final manage = ref.watch(myRestaurantProvider).value?.canManage ?? true;
    final items = [
      (
        OwnerTab.dashboard,
        Icons.space_dashboard_outlined,
        Icons.space_dashboard_rounded,
        l.navHome,
        '/restaurant',
      ),
      (
        OwnerTab.orders,
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        l.orders,
        '/restaurant/orders',
      ),
      (
        OwnerTab.menu,
        Icons.restaurant_menu_outlined,
        Icons.restaurant_menu_rounded,
        l.myMenu,
        '/restaurant/menu',
      ),
      (
        OwnerTab.insights,
        Icons.insights_outlined,
        Icons.insights_rounded,
        l.insights,
        '/restaurant/insights',
      ),
      (
        OwnerTab.account,
        Icons.storefront_outlined,
        Icons.storefront_rounded,
        l.navAccount,
        '/restaurant/account',
      ),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(33),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final (tab, icon, selectedIcon, label, path) in items)
                if (manage ||
                    (tab != OwnerTab.menu && tab != OwnerTab.insights))
                  Expanded(
                    child: _OwnerNavItem(
                      icon: tab == current ? selectedIcon : icon,
                      label: label,
                      selected: tab == current,
                      badge: tab == OwnerTab.orders ? waiting : 0,
                      onTap: tab == current ? null : () => context.go(path),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerNavItem extends StatelessWidget {
  const _OwnerNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(27),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: AppColors.danger,
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(icon, size: 23, color: color),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded card on the grey dashboard background.
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Square photo tile used by the dish form: shows the photo or a dashed
/// "Add" box (Add New Items design).
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.onTap,
    this.url,
    this.busy = false,
    this.width = 110,
    this.height = 100,
    this.circle = false,
  });

  final String? url;
  final VoidCallback? onTap;
  final bool busy;
  final double width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final radius = BorderRadius.circular(circle ? height / 2 : 20);
    final has = url != null && url!.isNotEmpty;
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: has ? null : AppColors.surface,
          border: has ? null : Border.all(color: AppColors.border, width: 1.5),
          image: has
              ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
              : null,
        ),
        child: busy
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : has
            ? Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF7C6FD6),
                      size: 22,
                    ),
                  ),
                  // The round logo tile is too small for the label.
                  if (!circle) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.add,
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// The outlet name; with several outlets, a tap opens the list to switch.
class OutletSwitcher extends ConsumerWidget {
  const OutletSwitcher({super.key, required this.name, required this.style});
  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(myRestaurantsProvider).value ?? const [];
    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (all.length < 2) return text;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showOutletPicker(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          Icon(Icons.expand_more_rounded, color: style.color),
        ],
      ),
    );
  }
}

/// Bottom sheet listing the account's outlets; picking one shows it.
Future<void> showOutletPicker(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final all = ref.read(myRestaurantsProvider).value ?? const [];
  final current = ref.read(myRestaurantProvider).value?.id;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l.outlets,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          for (final r in all)
            ListTile(
              leading: Icon(
                Icons.storefront_outlined,
                color: r.id == current ? AppColors.primary : AppColors.muted,
              ),
              title: Text(r.name),
              subtitle: Text(
                [
                  if (r.area.isNotEmpty) r.area,
                  roleLabel(l, r.role),
                ].join(' · '),
              ),
              trailing: r.id == current
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(selectedOutletProvider.notifier).select(r.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

/// "Owner" / "Manager" / "Staff".
String roleLabel(AppLocalizations l, String role) => switch (role) {
  'owner' => l.roleOwner,
  'manager' => l.roleManager,
  _ => l.roleStaff,
};
