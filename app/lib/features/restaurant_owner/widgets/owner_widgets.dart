import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/owner_live.dart';

enum OwnerTab { dashboard, menu, orders, profile }

/// Bottom bar from Seller Dashboard Home: four icons and an orange "+"
/// in the middle (add a dish). It is on every restaurant page, so it also
/// keeps the live orders listener (and the new-order sound) running, and
/// shows how many orders wait on the orders icon.
class OwnerBottomBar extends ConsumerWidget {
  const OwnerBottomBar({super.key, required this.current});
  final OwnerTab current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final waiting = ref.watch(ownerLiveProvider.select((s) => s.newCount));
    Widget item(
      OwnerTab tab,
      IconData icon,
      String label,
      String path, {
      int badge = 0,
    }) {
      final selected = tab == current;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: InkResponse(
            onTap: selected ? null : () => context.go(path),
            child: SizedBox(
              height: 64,
              child: Center(
                child: Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: AppColors.danger,
                  child: Icon(
                    icon,
                    size: 26,
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFAFAFAF),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        // Fixed height: without it the centred "+" would make the bar fill
        // the whole screen (bottom bars get the full height as max).
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              item(
                OwnerTab.dashboard,
                Icons.grid_view_rounded,
                l.dashboard,
                '/restaurant',
              ),
              item(
                OwnerTab.menu,
                Icons.format_list_bulleted_rounded,
                l.myMenu,
                '/restaurant/menu',
              ),
              Expanded(
                child: Center(
                  child: Tooltip(
                    message: l.addItem,
                    child: Material(
                      color: const Color(0xFFFFF1EB),
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.push('/restaurant/menu/new'),
                        child: const SizedBox.square(
                          dimension: 56,
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              item(
                OwnerTab.orders,
                Icons.notifications_none_rounded,
                l.orders,
                '/restaurant/orders',
                badge: waiting,
              ),
              item(
                OwnerTab.profile,
                Icons.person_outline_rounded,
                l.restaurantProfile,
                '/restaurant/profile',
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
        color: Colors.white,
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
          color: has ? null : Colors.white,
          border: has
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
