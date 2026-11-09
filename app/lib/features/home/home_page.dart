import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../account/data/account_repository.dart';
import '../catalog/data/catalog_models.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/widgets/browse_widgets.dart';

/// Home V.1: header (menu, deliver-to, cart), greeting, search,
/// category pills, open restaurants.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // First visit after login: offer "Access location" once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(locationProvider).asked) context.push('/location');
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(restaurantsProvider(null));
    ref.invalidate(deliveryFeeProvider);
    ref.invalidate(addressesProvider);
    await ref.read(restaurantsProvider(null).future).catchError((_) {
      return <RestaurantSummary>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(categoriesProvider);
    final restaurants = ref.watch(restaurantsProvider(null));
    final names = {
      for (final c in categories.value ?? const <FoodCategory>[])
        c.slug: c.name(lang),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _HomeHeader()),
                  const SliverToBoxAdapter(child: _Greeting()),
                  SliverToBoxAdapter(
                    child: SearchFieldButton(
                      onTap: () => context.push('/search'),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(
                    child: SectionHeader(title: l.allCategories),
                  ),
                  SliverToBoxAdapter(
                    child: AsyncBody(
                      value: categories,
                      loadingHeight: 76,
                      onRetry: () => ref.invalidate(categoriesProvider),
                      builder: (cats) => SizedBox(
                        height: 76,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            CategoryPill(
                              label: l.all,
                              selected: true,
                              thumb: const CategoryThumb(slug: 'all'),
                              onTap: () {},
                            ),
                            for (final c in cats)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 10,
                                ),
                                child: CategoryPill(
                                  label: c.name(lang),
                                  thumb: CategoryThumb(
                                    slug: c.slug,
                                    url: c.imageUrl,
                                  ),
                                  onTap: () =>
                                      context.push('/category/${c.slug}'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: SectionHeader(title: l.openRestaurants),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  restaurants.when(
                    data: (list) => SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) => RestaurantCard(
                        restaurant: list[i],
                        categoryNames: names,
                        onTap: () => context.push('/r/${list[i].slug}'),
                      ),
                    ),
                    loading: () => const SliverToBoxAdapter(
                      child: AsyncBody<void>(
                        value: AsyncLoading(),
                        builder: _empty,
                        onRetry: _noop,
                      ),
                    ),
                    error: (e, st) => SliverToBoxAdapter(
                      child: AsyncBody<void>(
                        value: AsyncError(e, st),
                        builder: _empty,
                        onRetry: () =>
                            ref.invalidate(restaurantsProvider(null)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _empty(void _) => const SizedBox.shrink();
void _noop() {}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final addresses = ref.watch(addressesProvider).value;
    final current = (addresses == null || addresses.isEmpty)
        ? null
        : addresses.first; // default first (ordered by the query)
    final addressText = current == null
        ? l.chooseAddress
        : (current.area.isNotEmpty ? current.area : current.addressText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFECF0F4),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/account'),
              child: SizedBox.square(
                dimension: 45,
                child: Icon(
                  Icons.notes_rounded,
                  color: AppColors.ink,
                  size: 24,
                  semanticLabel: l.profile,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/account/addresses'),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.deliverTo.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFC6E2A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF676767),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CartButton(onTap: () => context.push('/cart')),
        ],
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final full = ref.watch(profileProvider).value?.fullName ?? '';
    final first = full.trim().split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final text = hour < 12
        ? l.greetingMorning(first)
        : hour < 18
        ? l.greetingAfternoon(first)
        : l.greetingEvening(first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Text(
        // No name yet: drop the gap before the comma ("Hey , ..." → "Hey, ...").
        text.replaceAllMapped(RegExp(r'\s+([,!،])'), (m) => m[1]!),
        style: const TextStyle(fontSize: 16, color: AppColors.inkSoft),
      ),
    );
  }
}
