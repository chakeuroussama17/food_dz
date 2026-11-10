import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/customer_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../account/data/account_repository.dart';
import '../account/widgets/account_widgets.dart';
import '../catalog/data/catalog_models.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/widgets/browse_widgets.dart';
import '../banners/banners_repository.dart';

/// Customer home: orange header (address, photo, greeting, search), promo
/// carousel, category tiles, restaurant logos, open restaurants.
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
    ref.invalidate(homeBannersProvider);
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
      backgroundColor: AppColors.canvas,
      extendBody: true,
      bottomNavigationBar: const CustomerNavBar(current: CustomerTab.home),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(
              child: _Section(delay: 0, child: const _BannerCarousel()),
            ),
            SliverToBoxAdapter(
              child: _Section(
                delay: 1,
                child: AsyncBody(
                  value: categories,
                  loadingHeight: 110,
                  onRetry: () => ref.invalidate(categoriesProvider),
                  builder: (cats) => _CategoryStrip(categories: cats),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                delay: 2,
                child: _LogoStrip(restaurants: restaurants.value ?? const []),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SectionHeader(title: l.openNowTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            restaurants.when(
              data: (list) => SliverList.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _Section(
                  delay: 3 + i.clamp(0, 4),
                  child: RestaurantCard(
                    restaurant: list[i],
                    categoryNames: names,
                    onTap: () => context.push('/r/${list[i].slug}'),
                  ),
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
                  onRetry: () => ref.invalidate(restaurantsProvider(null)),
                ),
              ),
            ),
            // Room for the floating navigation bar.
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

Widget _empty(void _) => const SizedBox.shrink();
void _noop() {}

/// Fades and slides a section in, a little after the previous one.
class _Section extends StatelessWidget {
  const _Section({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final addresses = ref.watch(addressesProvider).value;
    final profile = ref.watch(profileProvider).value;
    final current = (addresses == null || addresses.isEmpty)
        ? null
        : addresses.first; // default first (ordered by the query)
    final addressText = current == null
        ? l.chooseAddress
        : [
            current.addressText,
            current.area,
          ].where((s) => s.isNotEmpty).join(', ');
    final first = (profile?.fullName ?? '').trim().split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting =
        (hour < 12
                ? l.greetingMorning(first)
                : hour < 18
                ? l.greetingAfternoon(first)
                : l.greetingEvening(first))
            .replaceAllMapped(RegExp(r'\s+([,!،])'), (m) => m[1]!);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFF9A4D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/account/addresses'),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.deliverTo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  addressText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: .9),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: l.profile,
                    child: GestureDetector(
                      onTap: () => context.go('/account'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Avatar(
                          url: profile?.avatarUrl,
                          name: profile?.fullName ?? '',
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => context.go('/search'),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search_rounded, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.searchHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The admin's banners (ads and news), sliding by themselves every 4 s,
/// with dots. Hidden when there are none.
class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _pages = PageController(viewportFraction: .92);
  Timer? _timer;
  int _index = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pages.hasClients || _count < 2) return;
      _pages.animateToPage(
        (_index + 1) % _count,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(homeBannersProvider).value ?? const [];
    _count = banners.length;
    if (banners.isEmpty) return const SizedBox(height: 4);
    if (_index >= banners.length) _index = 0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LayoutBuilder(
        builder: (context, box) {
          // Same shape as the recommended picture (1200 × 500).
          final height = (box.maxWidth * .92 - 12) / bannerAspectRatio;
          return Column(
            children: [
              SizedBox(
                height: height,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: banners.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _BannerSlide(banner: banners[i]),
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < banners.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});
  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final slug = banner.restaurantSlug;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: AppColors.placeholder,
        child: InkWell(
          onTap: slug == null ? null : () => context.push('/r/$slug'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(url: banner.imageUrl, radius: 0),
              if (banner.title.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x99000000)],
                      ),
                    ),
                    child: Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _categoryEmoji = {
  'burger': '🍔',
  'pizza': '🍕',
  'sandwich': '🥪',
  'tacos': '🌮',
  'chawarma': '🥙',
  'traditionnel': '🍲',
  'dessert': '🍰',
  'boisson': '🥤',
};

const _tileColors = [
  Color(0xFFFFEBE0),
  Color(0xFFFFF4D6),
  Color(0xFFE6F7EC),
  Color(0xFFE8F0FF),
  Color(0xFFF3E8FF),
  Color(0xFFFFE6EC),
];

/// Big round category tiles (emoji, or the category photo when set).
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});
  final List<FoodCategory> categories;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final c = categories[i];
            return _PressScale(
              onTap: () => context.push('/category/${c.slug}'),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: _tileColors[i % _tileColors.length],
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: (c.imageUrl ?? '').isNotEmpty
                          ? AppImage(
                              url: c.imageUrl,
                              width: 68,
                              height: 68,
                              radius: 34,
                            )
                          : Text(
                              _categoryEmoji[c.slug] ?? '🍽️',
                              style: const TextStyle(fontSize: 32),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.name(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Restaurant logos in a horizontal strip.
class _LogoStrip extends StatelessWidget {
  const _LogoStrip({required this.restaurants});
  final List<RestaurantSummary> restaurants;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (restaurants.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SectionHeader(title: l.restaurantsTitle),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final r = restaurants[i];
              return _PressScale(
                onTap: () => context.push('/r/${r.slug}'),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: r.isOpen
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: (r.logoUrl ?? '').isNotEmpty
                            ? AppImage(
                                url: r.logoUrl,
                                width: 60,
                                height: 60,
                                radius: 30,
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primarySoft,
                                child: Text(
                                  r.name.isEmpty ? '?' : r.name[0],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Shrinks a little while pressed.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .93 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
