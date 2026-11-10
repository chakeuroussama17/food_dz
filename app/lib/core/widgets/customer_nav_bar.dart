import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/cart_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

enum CustomerTab { home, search, cart, orders, account }

const _paths = {
  CustomerTab.home: '/home',
  CustomerTab.search: '/search',
  CustomerTab.cart: '/cart',
  CustomerTab.orders: '/orders',
  CustomerTab.account: '/account',
};

/// Floating bottom bar on the customer's main pages: Home, Search, Cart
/// (with the number of items), Orders, Account. The selected tab sits in a
/// soft orange pill that slides between tabs.
class CustomerNavBar extends ConsumerWidget {
  const CustomerNavBar({super.key, required this.current});
  final CustomerTab current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final count = ref.watch(cartProvider.select((c) => c.count));
    final items = [
      (
        CustomerTab.home,
        Icons.restaurant_rounded,
        Icons.restaurant_rounded,
        l.navHome,
      ),
      (
        CustomerTab.search,
        Icons.search_rounded,
        Icons.search_rounded,
        l.search,
      ),
      (
        CustomerTab.cart,
        Icons.shopping_bag_outlined,
        Icons.shopping_bag_rounded,
        l.cart,
      ),
      (
        CustomerTab.orders,
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        l.orders,
      ),
      (
        CustomerTab.account,
        Icons.person_outline_rounded,
        Icons.person_rounded,
        l.navAccount,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(33),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (final (tab, icon, selectedIcon, label) in items)
                Expanded(
                  child: _NavItem(
                    icon: tab == current ? selectedIcon : icon,
                    label: label,
                    selected: tab == current,
                    badge: tab == CustomerTab.cart ? count : 0,
                    onTap: () {
                      if (tab == current) return;
                      // The cart is a checkout page: open it on top.
                      if (tab == CustomerTab.cart) {
                        context.push(_paths[tab]!);
                      } else {
                        context.go(_paths[tab]!);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF8A8FA3);
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
                backgroundColor: AppColors.primary,
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
