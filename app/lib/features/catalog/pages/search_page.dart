import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/page_header.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../widgets/browse_widgets.dart';

const _recentKey = 'recent_searches';
const _maxRecent = 6;

/// Search: field with clear button, recent keywords, suggested
/// restaurants, then live results (restaurants + dishes).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<SearchHit>>? _results;

  List<String> get _recent =>
      ref.read(sharedPrefsProvider).getStringList(_recentKey) ?? const [];

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(v));
    setState(() {}); // clear button visibility
  }

  void _run(String v) {
    final q = v.trim();
    setState(() {
      _query = q;
      _results = q.length < 2
          ? null
          : ref.read(catalogRepositoryProvider).search(q);
    });
  }

  Future<void> _remember(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    final list = [
      t,
      ..._recent.where((x) => x.toLowerCase() != t.toLowerCase()),
    ].take(_maxRecent).toList();
    await ref.read(sharedPrefsProvider).setStringList(_recentKey, list);
  }

  void _useKeyword(String k) {
    _controller.text = k;
    _controller.selection = TextSelection.collapsed(offset: k.length);
    _run(k);
  }

  void _open(SearchHit hit) {
    _remember(_query);
    context.push(
      hit.isRestaurant
          ? '/r/${hit.restaurantSlug}'
          : '/r/${hit.restaurantSlug}/item/${hit.id}',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(
                  title: l.search,
                  trailing: CartButton(onTap: () => context.push('/cart')),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    onSubmitted: (v) {
                      _remember(v);
                      _run(v);
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      fillColor: const Color(0xFFF6F6F6),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.muted,
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              onPressed: () {
                                _controller.clear();
                                _run('');
                              },
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Color(0xFFCDCDCF),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _query.length < 2 ? _idle(l) : _resultsView(l)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _idle(AppLocalizations l) {
    final recent = _recent;
    final restaurants = ref.watch(restaurantsProvider(null));
    return ListView(
      children: [
        if (recent.isNotEmpty) ...[
          _Title(l.recentKeywords),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => ActionChip(
                label: Text(recent[i]),
                onPressed: () => _useKeyword(recent[i]),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFEDEDED), width: 2),
                shape: const StadiumBorder(),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
        _Title(l.suggestedRestaurants),
        const SizedBox(height: 8),
        AsyncBody(
          value: restaurants,
          onRetry: () => ref.invalidate(restaurantsProvider(null)),
          builder: (list) => Column(
            children: [
              for (final r in list.take(5))
                _ResultRow(
                  imageUrl: r.coverUrl,
                  title: r.name,
                  subtitle: r.area,
                  onTap: () => context.push('/r/${r.slug}'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultsView(AppLocalizations l) {
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<List<SearchHit>>(
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snap.hasError) {
          return AsyncBody<void>(
            value: AsyncError(snap.error!, StackTrace.empty),
            builder: (_) => const SizedBox.shrink(),
            onRetry: () => _run(_query),
          );
        }
        final hits = snap.data ?? const <SearchHit>[];
        if (hits.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l.noResults(_query),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.body),
            ),
          );
        }
        final restaurants = hits.where((h) => h.isRestaurant).toList();
        final items = hits.where((h) => !h.isRestaurant).toList();
        return ListView(
          children: [
            if (restaurants.isNotEmpty) ...[
              _Title(l.restaurantsTitle),
              for (final h in restaurants)
                _ResultRow(
                  imageUrl: h.imageUrl,
                  title: h.title,
                  subtitle: h.subtitle,
                  onTap: () => _open(h),
                ),
              const SizedBox(height: 16),
            ],
            if (items.isNotEmpty) ...[
              _Title(l.dishes),
              for (final h in items)
                _ResultRow(
                  imageUrl: h.imageUrl,
                  title: h.title,
                  subtitle: h.subtitle,
                  trailing: h.price == null ? null : formatDzd(h.price!, lang),
                  onTap: () => _open(h),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, color: AppColors.inkSoft),
    ),
  );
}

/// "Suggested Restaurants" row: thumbnail, name, small grey line.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.imageUrl,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            AppImage(url: imageUrl, width: 60, height: 50, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
