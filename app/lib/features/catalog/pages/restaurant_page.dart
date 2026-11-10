import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/add_to_cart.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../widgets/browse_widgets.dart';

/// Restaurant View_01: cover, name, description, info row, category chips
/// and a 2-column grid of the dishes in the selected category.
/// Route /r/:slug (this is also the QR-code link).
class RestaurantPage extends ConsumerStatefulWidget {
  const RestaurantPage({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends ConsumerState<RestaurantPage> {
  String? _categoryId; // null = all

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(restaurantDetailProvider(widget.slug));
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(
                  title: l.restaurant,
                  trailing: CartButton(onTap: () => context.push('/cart')),
                ),
                Expanded(
                  child: AsyncBody(
                    value: detail,
                    onRetry: () =>
                        ref.invalidate(restaurantDetailProvider(widget.slug)),
                    builder: (d) => d == null
                        ? Center(
                            child: Text(
                              l.restaurantNotFound,
                              style: TextStyle(color: AppColors.body),
                            ),
                          )
                        : _content(d),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(RestaurantDetail d) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = d.restaurant;
    final fee = ref.watch(deliveryFeeProvider).value;
    final cats = ref.watch(categoriesProvider).value ?? const <FoodCategory>[];

    // Chips: only categories this restaurant actually has, in global order.
    final usedIds = d.items.map((i) => i.categoryId).toSet();
    final chips = cats.where((c) => usedIds.contains(c.id)).toList();
    final shown = _categoryId == null
        ? d.items
        : d.items.where((i) => i.categoryId == _categoryId).toList();
    final selectedName = _categoryId == null
        ? l.all
        : chips.firstWhere((c) => c.id == _categoryId).name(lang);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppImage(url: r.coverUrl, height: 150, radius: 30),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
              if (r.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  r.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 18),
              InfoRow(
                items: [
                  if (fee != null)
                    InfoItem(
                      Icons.delivery_dining_outlined,
                      formatDzd(fee, lang),
                    ),
                  InfoItem(Icons.schedule_rounded, l.minutes(r.prepMinutes)),
                  InfoItem(
                    Icons.circle,
                    r.isOpen ? l.open : l.closed,
                    bold: true,
                    color: r.isOpen ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PillChips<String?>(
          items: [null, ...chips.map((c) => c.id)],
          selected: _categoryId,
          labelOf: (id) => id == null
              ? l.all
              : chips.firstWhere((c) => c.id == id).name(lang),
          onSelected: (id) => setState(() => _categoryId = id),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '$selectedName (${shown.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ProductGrid(
            children: [
              for (final item in shown)
                ProductCard(
                  name: item.name,
                  subtitle: r.name,
                  price: formatDzd(item.price, lang),
                  imageUrl: item.photoUrl,
                  unavailableLabel: item.isAvailable ? null : l.unavailable,
                  onTap: () => context.push('/r/${r.slug}/item/${item.id}'),
                  onAdd: () => addToCartWithPrompt(
                    context,
                    ref,
                    item: item,
                    restaurantName: r.name,
                    restaurantOpen: r.isOpen,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
