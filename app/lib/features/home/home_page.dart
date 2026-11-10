import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/customer_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../account/data/account_repository.dart';
import '../account/widgets/account_widgets.dart';
import '../catalog/data/catalog_models.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/widgets/browse_widgets.dart';

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
              child: _Section(
                delay: 0,
                child: _PromoCarousel(
                  restaurants: restaurants.value ?? const [],
                ),
              ),
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

/// Promo banners that slide by themselves (every 4 s), with dots.
class _PromoCarousel extends ConsumerStatefulWidget {
  const _PromoCarousel({required this.restaurants});
  final List<RestaurantSummary> restaurants;

  @override
  ConsumerState<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<_PromoCarousel> {
  final _pages = PageController(viewportFraction: .92);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pages.hasClients) return;
      final count = _slideCount;
      if (count < 2) return;
      _pages.animateToPage(
        (_index + 1) % count,
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

  RestaurantSummary? get _featured => widget.restaurants
      .where((r) => r.isOpen && (r.coverUrl ?? '').isNotEmpty)
      .firstOrNull;

  int get _slideCount => _featured == null ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final fee = ref.watch(deliveryFeeProvider).value;
    final featured = _featured;
    final slides = <Widget>[
      _PromoSlide(
        colors: const [Color(0xFF181C2E), Color(0xFF3B4161)],
        emoji: '💵',
        title: l.promoCashTitle,
        body: l.promoCashBody,
      ),
      _PromoSlide(
        colors: const [Color(0xFF1DB954), Color(0xFF6BD68F)],
        emoji: '🛵',
        title: fee == null
            ? l.deliveryFee
            : l.promoFeeTitle(formatDzd(fee, lang)),
        body: l.promoFeeBody,
      ),
      if (featured != null)
        _PromoSlide(
          colors: const [Color(0xFF7B2FF7), Color(0xFFB57BFF)],
          imageUrl: featured.coverUrl,
          title: featured.name,
          body: l.promoDiscover,
          onTap: () => context.push('/r/${featured.slug}'),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: slides,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({
    required this.colors,
    required this.title,
    required this.body,
    this.emoji,
    this.imageUrl,
    this.onTap,
  });

  final List<Color> colors;
  final String title;
  final String body;
  final String? emoji;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppImage(
                      url: imageUrl,
                      width: 120,
                      height: 120,
                      radius: 18,
                    ),
                  )
                else if (emoji != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 20),
                    child: Text(emoji!, style: const TextStyle(fontSize: 64)),
                  ),
              ],
            ),
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
