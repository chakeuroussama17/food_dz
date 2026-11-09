import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/add_to_cart.dart';
import '../../cart/cart_controller.dart';
import '../data/catalog_repository.dart';
import '../widgets/browse_widgets.dart';

/// Food Details_01: photo, restaurant chip, name, description, info row,
/// grey footer with price, quantity stepper and ADD TO CART.
/// Route /r/:slug/item/:itemId
class ItemPage extends ConsumerStatefulWidget {
  const ItemPage({super.key, required this.slug, required this.itemId});
  final String slug;
  final String itemId;

  @override
  ConsumerState<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends ConsumerState<ItemPage> {
  int _qty = 1;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final detail = ref.watch(restaurantDetailProvider(widget.slug));
    final fee = ref.watch(deliveryFeeProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(title: l.details),
                Expanded(
                  child: AsyncBody(
                    value: detail,
                    onRetry: () =>
                        ref.invalidate(restaurantDetailProvider(widget.slug)),
                    builder: (d) {
                      final item = d?.items
                          .where((i) => i.id == widget.itemId)
                          .firstOrNull;
                      if (d == null || item == null) {
                        return Center(
                          child: Text(
                            l.restaurantNotFound,
                            style: const TextStyle(color: AppColors.body),
                          ),
                        );
                      }
                      final r = d.restaurant;
                      final canOrder = r.isOpen && item.isAvailable;
                      return Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              children: [
                                AppImage(
                                  url: item.photoUrl,
                                  height: 184,
                                  radius: 32,
                                ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _RestaurantChip(
                                    name: r.name,
                                    logoUrl: r.logoUrl,
                                    onTap: () => context.push('/r/${r.slug}'),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  item.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                InfoRow(
                                  items: [
                                    if (fee != null)
                                      InfoItem(
                                        Icons.delivery_dining_outlined,
                                        formatDzd(fee, lang),
                                      ),
                                    InfoItem(
                                      Icons.schedule_rounded,
                                      l.minutes(r.prepMinutes),
                                    ),
                                  ],
                                ),
                                if (!canOrder) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    !r.isOpen
                                        ? l.restaurantClosedNote
                                        : l.unavailable,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SheetPanel(
                            tinted: true,
                            showHandle: false,
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDzd(item.price * _qty, lang),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    QuantityStepper(
                                      value: _qty,
                                      max: maxQuantityPerItem,
                                      onChanged: (v) =>
                                          setState(() => _qty = v),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  label: l.addToCart,
                                  loading: _adding,
                                  onPressed: !canOrder
                                      ? null
                                      : () async {
                                          setState(() => _adding = true);
                                          final ok = await addToCartWithPrompt(
                                            context,
                                            ref,
                                            item: item,
                                            restaurantName: r.name,
                                            restaurantOpen: r.isOpen,
                                            quantity: _qty,
                                          );
                                          if (!context.mounted) return;
                                          setState(() => _adding = false);
                                          if (ok && context.canPop()) {
                                            context.pop();
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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

/// Outlined pill with the restaurant's logo and name ("Uttora Coffe House").
class _RestaurantChip extends StatelessWidget {
  const _RestaurantChip({
    required this.name,
    required this.onTap,
    this.logoUrl,
  });

  final String name;
  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE9E9E9))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 20, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              logoUrl == null
                  ? const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: 22,
                    )
                  : AppImage(url: logoUrl, width: 22, height: 22, radius: 11),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
