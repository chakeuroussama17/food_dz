import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_widgets.dart';

/// My Food: "Total N items", category chips, dish rows with an
/// availability switch. Tap a dish to edit it.
class OwnerMenuPage extends ConsumerStatefulWidget {
  const OwnerMenuPage({super.key});

  @override
  ConsumerState<OwnerMenuPage> createState() => _OwnerMenuPageState();
}

class _OwnerMenuPageState extends ConsumerState<OwnerMenuPage> {
  String? _categoryId; // null = all

  Future<void> _setAvailable(String rid, MenuItem item, bool v) async {
    try {
      await ref.read(ownerRepositoryProvider).setItemAvailable(item.id, v);
      ref.invalidate(myItemsProvider(rid));
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).errGeneric,
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final mine = ref.watch(myRestaurantProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <FoodCategory>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.menu),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AsyncBody(
              value: mine,
              onRetry: () => ref.invalidate(myRestaurantProvider),
              builder: (r) {
                if (r == null) return const SizedBox.shrink();
                final items = ref.watch(myItemsProvider(r.id));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(title: l.myMenu, showBack: false),
                    Expanded(
                      child: AsyncBody(
                        value: items,
                        onRetry: () => ref.invalidate(myItemsProvider(r.id)),
                        builder: (list) {
                          if (list.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l.emptyMenu,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.body,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    AppButton(
                                      label: l.addItem,
                                      onPressed: () =>
                                          context.push('/restaurant/menu/new'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final used = list.map((i) => i.categoryId).toSet();
                          final chips = cats
                              .where((c) => used.contains(c.id))
                              .toList();
                          final shown = _categoryId == null
                              ? list
                              : list
                                    .where((i) => i.categoryId == _categoryId)
                                    .toList();
                          final names = {
                            for (final c in cats) c.id: c.name(lang),
                          };
                          return ListView(
                            children: [
                              PillChips<String?>(
                                items: [null, ...chips.map((c) => c.id)],
                                selected: _categoryId,
                                labelOf: (id) =>
                                    id == null ? l.all : names[id] ?? '',
                                onSelected: (id) =>
                                    setState(() => _categoryId = id),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  8,
                                ),
                                child: Text(
                                  l.totalItems(shown.length),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              for (final item in shown)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: OrderCard(
                                    imageUrl: item.photoUrl,
                                    tag: item.categoryId == null
                                        ? null
                                        : names[item.categoryId],
                                    title: item.name,
                                    subtitle: item.isAvailable
                                        ? l.available
                                        : l.unavailable,
                                    amount: formatDzd(item.price, lang),
                                    onTap: () => context.push(
                                      '/restaurant/menu/${item.id}',
                                      extra: item,
                                    ),
                                    actions: [
                                      Switch.adaptive(
                                        value: item.isAvailable,
                                        activeTrackColor: AppColors.primary,
                                        onChanged: (v) =>
                                            _setAvailable(r.id, item, v),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
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
