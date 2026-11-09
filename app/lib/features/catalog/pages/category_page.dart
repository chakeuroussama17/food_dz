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

/// Food - Burgers: category switcher pill, search, "Popular {category}"
/// dishes grid, then restaurants serving that category.
/// Route /category/:slug
class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AsyncBody(
              value: cats,
              onRetry: () => ref.invalidate(categoriesProvider),
              builder: (list) {
                final cat = list.where((c) => c.slug == slug).firstOrNull;
                if (cat == null) {
                  return Column(
                    children: [
                      const PageHeader(title: ''),
                      Expanded(
                        child: Center(
                          child: Text(
                            l.noResults(slug),
                            style: const TextStyle(color: AppColors.body),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                final names = {for (final c in list) c.slug: c.name(lang)};
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(current: cat, all: list),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Text(
                          l.popularIn(cat.name(lang)),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _PopularItems(category: cat)),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    SliverToBoxAdapter(
                      child: SectionHeader(title: l.openRestaurants),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: _Restaurants(slug: slug, names: names),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button, "BURGER ▾" switcher, search button.
class _Header extends StatelessWidget {
  const _Header({required this.current, required this.all});
  final FoodCategory current;
  final List<FoodCategory> all;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          CircleIconButton.back(context),
          const SizedBox(width: 17),
          PopupMenuButton<String>(
            onSelected: (s) => context.pushReplacement('/category/$s'),
            itemBuilder: (_) => [
              for (final c in all)
                PopupMenuItem(value: c.slug, child: Text(c.name(lang))),
            ],
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(33),
                border: Border.all(color: const Color(0xFFECF0F4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current.name(lang).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          CircleIconButton(
            icon: Icons.search_rounded,
            background: AppColors.ink,
            foreground: Colors.white,
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

class _PopularItems extends ConsumerWidget {
  const _PopularItems({required this.category});
  final FoodCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final items = ref.watch(categoryItemsProvider(category.id));
    final restaurants = ref.watch(restaurantsProvider(null)).value ?? const [];
    final openById = {for (final r in restaurants) r.id: r.isOpen};
    return AsyncBody(
      value: items,
      onRetry: () => ref.invalidate(categoryItemsProvider(category.id)),
      builder: (list) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: list.isEmpty
            ? Text(
                l.noResults(category.name(lang)),
                style: const TextStyle(color: AppColors.body),
              )
            : ProductGrid(
                children: [
                  for (final item in list)
                    ProductCard(
                      name: item.name,
                      subtitle: item.restaurantName,
                      price: formatDzd(item.price, lang),
                      imageUrl: item.photoUrl,
                      onTap: () => context.push(
                        '/r/${item.restaurantSlug}/item/${item.id}',
                      ),
                      onAdd: () => addToCartWithPrompt(
                        context,
                        ref,
                        item: item,
                        restaurantName: item.restaurantName ?? '',
                        restaurantOpen: openById[item.restaurantId] ?? false,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Restaurants extends ConsumerWidget {
  const _Restaurants({required this.slug, required this.names});
  final String slug;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(restaurantsProvider(slug));
    return AsyncBody(
      value: list,
      onRetry: () => ref.invalidate(restaurantsProvider(slug)),
      builder: (rs) => Column(
        children: [
          for (final r in rs)
            RestaurantCard(
              restaurant: r,
              categoryNames: names,
              onTap: () => context.push('/r/${r.slug}'),
            ),
        ],
      ),
    );
  }
}
