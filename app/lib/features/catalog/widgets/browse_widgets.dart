import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/info_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/cart_controller.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

/// Loading / error-with-retry / data, used by every catalogue screen.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.loadingHeight = 160,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => SizedBox(
        height: loadingHeight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => _ErrorBox(onRetry: onRetry),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 36),
          const SizedBox(height: 8),
          Text(
            l.loadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.body),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }
}

/// Title + "See all >" row ("All Categories", "Open Restaurants").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 20, color: AppColors.inkSoft),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkSoft,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.seeAll, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Grey "Search dishes, restaurants" field. On Home it's a button that
/// opens the search page.
class SearchFieldButton extends StatelessWidget {
  const SearchFieldButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.search_rounded, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.searchHint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: AppColors.body),
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

/// Icon shown for a category until a photo is uploaded.
IconData categoryIcon(String slug) => switch (slug) {
  'burger' => Icons.lunch_dining_rounded,
  'pizza' => Icons.local_pizza_rounded,
  'sandwich' => Icons.bakery_dining_rounded,
  'tacos' => Icons.kebab_dining_rounded,
  'chawarma' => Icons.kebab_dining_rounded,
  'traditionnel' => Icons.rice_bowl_rounded,
  'dessert' => Icons.icecream_rounded,
  'boisson' => Icons.local_drink_rounded,
  _ => Icons.restaurant_rounded,
};

/// Round thumbnail for a category: photo if any, otherwise an icon.
class CategoryThumb extends StatelessWidget {
  const CategoryThumb({
    super.key,
    required this.slug,
    this.url,
    this.size = 44,
  });

  final String slug;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return AppImage(url: url, width: size, height: size, radius: size / 2);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
      ),
      child: Icon(
        categoryIcon(slug),
        color: AppColors.primary,
        size: size * .55,
      ),
    );
  }
}

/// Pill from Home V.1: thumbnail + label, selected = soft yellow.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.label,
    required this.thumb,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Widget thumb;
  final VoidCallback onTap;
  final bool selected;

  static const _selected = Color(0xFFFFD27C);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? _selected : AppColors.surface,
          borderRadius: BorderRadius.circular(39),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F96969A),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(39),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 20, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  thumb,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      // Dark text on the yellow selected pill, in both modes.
                      color: selected
                          ? const Color(0xFF32343E)
                          : AppColors.inkSoft,
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

/// "Open Restaurants" card: wide photo, name, categories, info row.
class RestaurantCard extends ConsumerWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.categoryNames,
    required this.onTap,
  });

  final RestaurantSummary restaurant;

  /// slug → localized name, for the "Burger · Pizza" line.
  final Map<String, String> categoryNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = restaurant;
    final pos = ref.watch(locationProvider).position;
    final fee = ref.watch(deliveryFeeProvider).value;
    final cats = r.categorySlugs
        .map((s) => categoryNames[s])
        .whereType<String>()
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  url: r.coverUrl,
                  height: 137,
                  width: double.infinity,
                  radius: 15,
                ),
                if (!r.isOpen)
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: _Badge(text: l.closed),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.name, style: TextStyle(fontSize: 20, color: AppColors.ink)),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                cats,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            InfoRow(
              items: [
                if (fee != null)
                  InfoItem(
                    Icons.delivery_dining_outlined,
                    formatDzd(fee, lang),
                  ),
                InfoItem(Icons.schedule_rounded, l.minutes(r.prepMinutes)),
                if (pos != null && r.lat != null && r.lng != null)
                  InfoItem(
                    Icons.near_me_outlined,
                    l.kmAway(
                      formatKm(distanceKm(pos.lat, pos.lng, r.lat!, r.lng!)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.pill.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// Dark round cart button with an orange count badge (top-right of Home).
class CartButton extends ConsumerWidget {
  const CartButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((c) => c.count));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.pill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox.square(
              dimension: 45,
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        if (count > 0)
          PositionedDirectional(
            top: -4,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
