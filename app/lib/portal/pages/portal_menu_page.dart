import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/pick_image.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/catalog/data/catalog_models.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/restaurant_owner/data/outlet_admin_repository.dart';
import '../../features/restaurant_owner/data/owner_repository.dart';
import '../../features/restaurant_owner/widgets/period_chips.dart'
    show SmallChips;
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

/// Gallery picker for dish photos (overridden in tests).
final pickDishPhotoProvider = Provider<Future<PickedImage?> Function()>(
  (ref) =>
      () => pickImage(),
);

enum _Tab { dishes, groups }

/// Menu management: dishes (table, bulk actions, edit panel) and option
/// groups (sizes, extras) of one outlet.
class PortalMenuPage extends ConsumerStatefulWidget {
  const PortalMenuPage({super.key});

  @override
  ConsumerState<PortalMenuPage> createState() => _PortalMenuPageState();
}

class _PortalMenuPageState extends ConsumerState<PortalMenuPage> {
  _Tab _tab = _Tab.dishes;
  String _query = '';
  String? _category; // null = all
  final _selected = <String>{};

  /// The dish in the side panel: '' = new dish, null = closed.
  String? _editing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final outlet = ref.watch(portalOutletProvider).value;
    if (outlet == null) return const SizedBox.shrink();
    final items = ref.watch(myItemsProvider(outlet.id));
    final groups = ref.watch(optionGroupsProvider(outlet.id)).value ?? const [];
    final cats = ref.watch(categoriesProvider).value ?? const <FoodCategory>[];

    final page = PortalPage(
      title: l.navMenu,
      subtitle: l.menuSubtitle,
      actions: [
        const SingleOutletPicker(),
        FilledButton.icon(
          onPressed: () => _tab == _Tab.dishes
              ? setState(() => _editing = '')
              : _editGroup(context, outlet.id, null),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(_tab == _Tab.dishes ? l.addItem : l.addOptionGroup),
        ),
      ],
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Segmented<_Tab>(
            items: _Tab.values,
            selected: _tab,
            labelOf: (t) => t == _Tab.dishes
                ? '${l.dishesTab} (${items.value?.length ?? 0})'
                : '${l.optionGroupsTab} (${groups.length})',
            onSelected: (t) => setState(() => _tab = t),
          ),
        ),
        const SizedBox(height: 18),
        if (_tab == _Tab.dishes)
          AsyncBodyLite(
            value: items,
            onRetry: () => ref.invalidate(myItemsProvider(outlet.id)),
            builder: (list) => _dishes(context, outlet.id, list, groups, cats),
          )
        else
          _Groups(
            restaurantId: outlet.id,
            groups: groups,
            items: items.value ?? const [],
            onEdit: (g) => _editGroup(context, outlet.id, g),
          ),
      ],
    );

    final editing = _editing;
    final dish = editing == null || editing.isEmpty
        ? null
        : items.value?.where((i) => i.id == editing).firstOrNull;
    return Stack(
      children: [
        page,
        if (editing != null) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _editing = null),
              child: ColoredBox(color: Colors.black.withValues(alpha: .25)),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: MediaQuery.sizeOf(context).width < 560
                ? MediaQuery.sizeOf(context).width
                : 480,
            child: _DishPanel(
              key: ValueKey(editing),
              restaurantId: outlet.id,
              dish: dish,
              groups: groups,
              categories: cats,
              onClose: () => setState(() => _editing = null),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dishes(
    BuildContext context,
    String rid,
    List<MenuItem> all,
    List<OwnerOptionGroup> groups,
    List<FoodCategory> cats,
  ) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final q = _query.trim().toLowerCase();
    final list = all.where((i) {
      if (_category != null && i.categoryId != _category) return false;
      return q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
    }).toList();
    _selected.removeWhere((id) => !all.any((i) => i.id == id));
    final groupsOf = <String, List<String>>{};
    for (final g in groups) {
      for (final id in g.itemIds) {
        groupsOf.putIfAbsent(id, () => []).add(g.group.name);
      }
    }
    final catName = {for (final c in cats) c.id: c.name(lang)};
    final usedCats = cats.where((c) => all.any((i) => i.categoryId == c.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: _searchDecoration(l.searchDishesHint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: SmallChips<String?>(
            items: [null, for (final c in usedCats) c.id],
            selected: _category,
            labelOf: (id) => id == null ? l.filterAll : catName[id] ?? '',
            onSelected: (id) => setState(() => _category = id),
          ),
        ),
        const SizedBox(height: 12),
        if (_selected.isNotEmpty)
          _BulkBar(
            restaurantId: rid,
            ids: _selected.toList(),
            categories: cats,
            onDone: () => setState(_selected.clear),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l.emptyMenu,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: c.maxWidth),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 72,
                        horizontalMargin: 16,
                        columnSpacing: 24,
                        onSelectAll: (v) => setState(() {
                          v == true
                              ? _selected.addAll(list.map((i) => i.id))
                              : _selected.clear();
                        }),
                        columns: [
                          DataColumn(label: Text(l.csvItems)),
                          DataColumn(label: Text(l.category)),
                          DataColumn(label: Text(l.price), numeric: true),
                          DataColumn(label: Text(l.optionGroupsTab)),
                          DataColumn(label: Text(l.available)),
                          const DataColumn(label: SizedBox()),
                        ],
                        rows: [
                          for (final i in list)
                            DataRow(
                              selected: _selected.contains(i.id),
                              onSelectChanged: (v) => setState(() {
                                v == true
                                    ? _selected.add(i.id)
                                    : _selected.remove(i.id);
                              }),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      AppImage(
                                        url: i.photoUrl,
                                        width: 44,
                                        height: 44,
                                        radius: 10,
                                      ),
                                      const SizedBox(width: 12),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 260,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              i.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            if (i.description.isNotEmpty)
                                              Text(
                                                i.description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(catName[i.categoryId] ?? '—')),
                                DataCell(Text(formatDzd(i.price, lang))),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 200,
                                    ),
                                    child: Text(
                                      (groupsOf[i.id] ?? const ['—']).join(
                                        ', ',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.body,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Switch.adaptive(
                                    value: i.isAvailable,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (v) => _run(
                                      () => ref
                                          .read(ownerRepositoryProvider)
                                          .setItemAvailable(i.id, v),
                                      rid,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    tooltip: l.editItem,
                                    onPressed: () =>
                                        setState(() => _editing = i.id),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _run(Future<void> Function() action, String rid) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).errGeneric,
          error: true,
        );
      }
    } finally {
      ref.invalidate(myItemsProvider(rid));
    }
  }

  Future<void> _editGroup(
    BuildContext context,
    String rid,
    OwnerOptionGroup? g,
  ) async {
    final items = ref.read(myItemsProvider(rid)).value ?? const <MenuItem>[];
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _GroupDialog(restaurantId: rid, group: g, items: items),
    );
    if (saved == true) {
      ref.invalidate(optionGroupsProvider(rid));
    }
  }
}

InputDecoration _searchDecoration(String hint) => InputDecoration(
  hintText: hint,
  prefixIcon: const Icon(Icons.search_rounded),
  isDense: true,
  filled: true,
  fillColor: AppColors.surface,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.primary),
  ),
);

/// Loading / error / data without a page around it.
class AsyncBodyLite<T> extends StatelessWidget {
  const AsyncBodyLite({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    ),
    error: (_, _) => Center(
      child: TextButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retry),
      ),
    ),
    data: builder,
  );
}

/// "3 selected: Show · Hide · Category · Prices · Delete".
class _BulkBar extends ConsumerStatefulWidget {
  const _BulkBar({
    required this.restaurantId,
    required this.ids,
    required this.categories,
    required this.onDone,
  });

  final String restaurantId;
  final List<String> ids;
  final List<FoodCategory> categories;
  final VoidCallback onDone;

  @override
  ConsumerState<_BulkBar> createState() => _BulkBarState();
}

class _BulkBarState extends ConsumerState<_BulkBar> {
  bool _busy = false;

  Future<void> _do(BulkAction a, {num? number, String? category}) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final n = await ref
          .read(outletAdminRepositoryProvider)
          .bulkItems(
            widget.restaurantId,
            widget.ids,
            a,
            number: number,
            categoryId: category,
          );
      if (mounted) showAppSnack(context, l.bulkDone(n));
      widget.onDone();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      ref.invalidate(myItemsProvider(widget.restaurantId));
      ref.invalidate(optionGroupsProvider(widget.restaurantId));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prices() async {
    final r = await showDialog<(BulkAction, num)>(
      context: context,
      builder: (_) => const _PriceDialog(),
    );
    if (r != null) await _do(r.$1, number: r.$2);
  }

  Future<void> _category() async {
    final lang = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context);
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.category),
        children: [
          for (final c in widget.categories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, c.id),
              child: Text(c.name(lang)),
            ),
        ],
      ),
    );
    if (id != null) await _do(BulkAction.category, category: id);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.bulkDeleteConfirm(widget.ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _do(BulkAction.delete);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget btn(String label, IconData icon, VoidCallback onTap, {Color? c}) =>
        TextButton.icon(
          onPressed: _busy ? null : onTap,
          icon: Icon(icon, size: 18, color: c ?? AppColors.ink),
          label: Text(label, style: TextStyle(color: c ?? AppColors.ink)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l.selectedCount(widget.ids.length),
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          btn(
            l.bulkShow,
            Icons.visibility_outlined,
            () => _do(BulkAction.show),
          ),
          btn(
            l.bulkHide,
            Icons.visibility_off_outlined,
            () => _do(BulkAction.hide),
          ),
          btn(l.category, Icons.category_outlined, _category),
          btn(l.bulkPrices, Icons.price_change_outlined, _prices),
          btn(
            l.delete,
            Icons.delete_outline_rounded,
            _delete,
            c: AppColors.danger,
          ),
          IconButton(
            tooltip: l.back,
            onPressed: widget.onDone,
            icon: Icon(Icons.close_rounded, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// +/- percent or +/- DA. Returns (action, number).
class _PriceDialog extends StatefulWidget {
  const _PriceDialog();

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  bool _percent = true;
  bool _up = true;
  final _value = TextEditingController(text: '10');

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = int.tryParse(_value.text.trim());
    final ok =
        v != null && v > 0 && (_percent ? v <= (_up ? 300 : 90) : v <= 100000);
    return AlertDialog(
      title: Text(l.bulkPrices),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Segmented<bool>(
              items: const [true, false],
              selected: _up,
              labelOf: (u) => u ? l.priceIncrease : l.priceDecrease,
              onSelected: (u) => setState(() => _up = u),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Segmented<bool>(
                  items: const [true, false],
                  selected: _percent,
                  labelOf: (p) => p ? '%' : 'DA',
                  onSelected: (p) => setState(() => _percent = p),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.pricesRounded,
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back),
        ),
        AppButton(
          label: l.apply,
          variant: AppButtonVariant.small,
          onPressed: !ok
              ? null
              : () => Navigator.pop(context, (
                  _percent ? BulkAction.pricePercent : BulkAction.priceAdd,
                  _up ? v : -v,
                )),
        ),
      ],
    );
  }
}

/// Side panel to add or edit a dish, with its option groups.
class _DishPanel extends ConsumerStatefulWidget {
  const _DishPanel({
    super.key,
    required this.restaurantId,
    required this.dish,
    required this.groups,
    required this.categories,
    required this.onClose,
  });

  final String restaurantId;
  final MenuItem? dish;
  final List<OwnerOptionGroup> groups;
  final List<FoodCategory> categories;
  final VoidCallback onClose;

  @override
  ConsumerState<_DishPanel> createState() => _DishPanelState();
}

class _DishPanelState extends ConsumerState<_DishPanel> {
  final _form = GlobalKey<FormState>();
  late final d = widget.dish;
  late final _name = TextEditingController(text: d?.name ?? '');
  late final _desc = TextEditingController(text: d?.description ?? '');
  late final _price = TextEditingController(
    text: d == null ? '' : '${d!.price}',
  );
  late String? _category = d?.categoryId;
  late String? _photo = d?.photoUrl;
  late bool _available = d?.isAvailable ?? true;
  late final List<String> _groups = [
    for (final g in widget.groups)
      if (d != null && g.itemIds.contains(d!.id)) g.group.id,
  ];
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = AppLocalizations.of(context);
    setState(() => _uploading = true);
    try {
      final img = await ref.read(pickDishPhotoProvider)();
      if (img == null) return;
      final url = await ref
          .read(ownerRepositoryProvider)
          .uploadImage(widget.restaurantId, img.bytes, img.extension);
      if (mounted) setState(() => _photo = url);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final repo = ref.read(ownerRepositoryProvider);
    final input = MenuItemInput(
      name: _name.text.trim(),
      price: int.parse(_price.text.trim()),
      description: _desc.text.trim(),
      categoryId: _category,
      photoUrl: _photo,
      isAvailable: _available,
    );
    try {
      final id = d == null
          ? await repo.addItem(widget.restaurantId, input)
          : d!.id;
      if (d != null) await repo.updateItem(id, input);
      final before = [
        for (final g in widget.groups)
          if (d != null && g.itemIds.contains(d!.id)) g.group.id,
      ];
      if (before.join(',') != _groups.join(',')) {
        await ref
            .read(outletAdminRepositoryProvider)
            .setItemGroups(id, _groups);
      }
      if (mounted) showAppSnack(context, l.saved);
      widget.onClose();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      ref.invalidate(myItemsProvider(widget.restaurantId));
      ref.invalidate(optionGroupsProvider(widget.restaurantId));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteItemConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(ownerRepositoryProvider).deleteItem(d!.id);
      widget.onClose();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      ref.invalidate(myItemsProvider(widget.restaurantId));
      ref.invalidate(optionGroupsProvider(widget.restaurantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.pill,
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const BackButtonIcon(),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        d == null ? l.addItem : l.editItem,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  InkWell(
                    onTap: _uploading ? null : _pickPhoto,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: AppColors.field,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _uploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : (_photo ?? '').isNotEmpty
                          ? AppImage(url: _photo, height: 170)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.uploadDishPhoto,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.photosSellHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: l.itemName,
                    controller: _name,
                    maxLength: 80,
                    validator: (v) =>
                        (v ?? '').trim().length < 2 ? l.errNameRequired : null,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: l.description,
                    controller: _desc,
                    optionalLabel: l.optional,
                    maxLines: 3,
                    maxLength: 300,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: l.price,
                    controller: _price,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return n == null || n < 10 || n > 100000
                          ? l.errPrice
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in widget.categories)
                        ChoiceChip(
                          label: Text(c.name(lang)),
                          selected: _category == c.id,
                          selectedColor: AppColors.primarySoft,
                          onSelected: (v) =>
                              setState(() => _category = v ? c.id : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _available,
                    activeTrackColor: AppColors.primary,
                    title: Text(l.available),
                    onChanged: (v) => setState(() => _available = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.optionGroupsTab.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.groups.isEmpty
                        ? l.noOptionGroupsHint
                        : l.optionGroupsPickHint,
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in widget.groups)
                        FilterChip(
                          label: Text(g.group.name),
                          selected: _groups.contains(g.group.id),
                          selectedColor: AppColors.primarySoft,
                          onSelected: (v) => setState(
                            () => v
                                ? _groups.add(g.group.id)
                                : _groups.remove(g.group.id),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (d != null)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                      label: Text(
                        l.delete,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  const Spacer(),
                  AppButton(
                    label: l.saveChanges,
                    variant: AppButtonVariant.small,
                    loading: _saving,
                    onPressed: _uploading ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The option groups of the outlet as cards.
class _Groups extends ConsumerWidget {
  const _Groups({
    required this.restaurantId,
    required this.groups,
    required this.items,
    required this.onEdit,
  });

  final String restaurantId;
  final List<OwnerOptionGroup> groups;
  final List<MenuItem> items;
  final ValueChanged<OwnerOptionGroup> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    if (groups.isEmpty) {
      return PCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.tune_rounded, size: 44, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                l.noOptionGroups,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }
    final names = {for (final i in items) i.id: i.name};
    return LayoutBuilder(
      builder: (context, c) {
        final per = c.maxWidth > 900 ? 2 : 1;
        final w = (c.maxWidth - 16 * (per - 1)) / per;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final g in groups)
              SizedBox(
                width: w,
                child: PCard(
                  title: g.group.name,
                  subtitle: g.group.required
                      ? (g.group.single
                            ? l.ruleRequiredOne
                            : l.ruleRequiredRange(g.group.min, g.group.max))
                      : l.ruleOptionalUpTo(g.group.max),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.editItem,
                        onPressed: () => onEdit(g),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      IconButton(
                        tooltip: l.delete,
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              content: Text(l.deleteGroupConfirm(g.group.name)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l.back),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    l.delete,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          await ref
                              .read(outletAdminRepositoryProvider)
                              .deleteOptionGroup(g.group.id);
                          ref.invalidate(optionGroupsProvider(restaurantId));
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final ch in g.group.choices)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ch.name,
                                style: TextStyle(
                                  color: ch.isAvailable
                                      ? AppColors.ink
                                      : AppColors.muted,
                                  decoration: ch.isAvailable
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            Text(
                              ch.price == 0
                                  ? l.free
                                  : '+ ${formatDzd(ch.price, lang)}',
                              style: TextStyle(color: AppColors.body),
                            ),
                            Tooltip(
                              message: ch.isAvailable
                                  ? l.available
                                  : l.outOfStock,
                              child: Switch.adaptive(
                                value: ch.isAvailable,
                                activeTrackColor: AppColors.primary,
                                onChanged: (v) async {
                                  await ref
                                      .read(outletAdminRepositoryProvider)
                                      .setChoiceAvailable(ch.id, v);
                                  ref.invalidate(
                                    optionGroupsProvider(restaurantId),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      Divider(color: AppColors.border, height: 20),
                      Text(
                        g.itemIds.isEmpty
                            ? l.usedByNoDish
                            : l.usedBy(
                                g.itemIds
                                    .map((id) => names[id] ?? '')
                                    .where((n) => n.isNotEmpty)
                                    .join(', '),
                              ),
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Create / edit an option group: rule, choices, dishes using it.
class _GroupDialog extends ConsumerStatefulWidget {
  const _GroupDialog({
    required this.restaurantId,
    required this.group,
    required this.items,
  });

  final String restaurantId;
  final OwnerOptionGroup? group;
  final List<MenuItem> items;

  @override
  ConsumerState<_GroupDialog> createState() => _GroupDialogState();
}

class _ChoiceDraft {
  _ChoiceDraft({
    this.id = '',
    String name = '',
    int price = 0,
    this.available = true,
  }) : name = TextEditingController(text: name),
       price = TextEditingController(text: price == 0 ? '' : '$price');
  final String id;
  final TextEditingController name;
  final TextEditingController price;
  bool available;
}

class _GroupDialogState extends ConsumerState<_GroupDialog> {
  final _form = GlobalKey<FormState>();
  late final g = widget.group?.group;
  late final _name = TextEditingController(text: g?.name ?? '');
  late bool _required = g?.required ?? true;
  late int _max = g?.max ?? 1;
  late int _min = (g?.min ?? 1).clamp(1, 10);
  late final List<_ChoiceDraft> _choices = g == null
      ? [_ChoiceDraft(), _ChoiceDraft()]
      : [
          for (final c in g!.choices)
            _ChoiceDraft(
              id: c.id,
              name: c.name,
              price: c.price,
              available: c.isAvailable,
            ),
        ];
  late final Set<String> _items = {...?widget.group?.itemIds};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _choices) {
      c.name.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final min = _required ? _min.clamp(1, _max) : 0;
    if (min > _choices.length) {
      showAppSnack(context, l.errGroupRule, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(outletAdminRepositoryProvider)
          .saveOptionGroup(
            widget.restaurantId,
            id: g?.id,
            name: _name.text,
            min: min,
            max: _max,
            choices: [
              for (final c in _choices)
                OptionChoice(
                  id: c.id,
                  name: c.name.text.trim(),
                  price: int.tryParse(c.price.text.trim()) ?? 0,
                  isAvailable: c.available,
                ),
            ],
            itemIds: _items.toList(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget stepper(
      String label,
      int value,
      int lo,
      int hi,
      ValueChanged<int> on,
    ) => Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.ink)),
        ),
        IconButton(
          onPressed: value > lo ? () => on(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        Text(
          '$value',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        IconButton(
          onPressed: value < hi ? () => on(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
    return AlertDialog(
      title: Text(g == null ? l.addOptionGroup : l.editOptionGroup),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: l.groupName,
                  controller: _name,
                  hint: l.groupNameHint,
                  maxLength: 60,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.errNameRequired : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _required,
                  activeTrackColor: AppColors.primary,
                  title: Text(l.optionRequired),
                  subtitle: Text(l.requiredHint),
                  onChanged: (v) => setState(() => _required = v),
                ),
                if (_required)
                  stepper(
                    l.minChoices,
                    _min.clamp(1, _max),
                    1,
                    _max,
                    (v) => setState(() => _min = v),
                  ),
                stepper(
                  l.maxChoices,
                  _max,
                  1,
                  10,
                  (v) => setState(() {
                    _max = v;
                    if (_min > v) _min = v;
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  l.choices.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                for (var i = 0; i < _choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _choices[i].name,
                            maxLength: 60,
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              hintText: l.choiceNameHint,
                            ),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? l.errNameRequired
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _choices[i].price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: l.extraPriceHint,
                              suffixText: 'DA',
                            ),
                            validator: (v) =>
                                (int.tryParse((v ?? '').trim()) ?? 0) > 100000
                                ? l.errPrice
                                : null,
                          ),
                        ),
                        Checkbox(
                          value: _choices[i].available,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _choices[i].available = v ?? true),
                        ),
                        IconButton(
                          tooltip: l.delete,
                          onPressed: _choices.length <= 1
                              ? null
                              : () => setState(() => _choices.removeAt(i)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _choices.length >= 30
                        ? null
                        : () => setState(() => _choices.add(_ChoiceDraft())),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addChoice),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.dishesUsingGroup.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in widget.items)
                      FilterChip(
                        label: Text(i.name),
                        selected: _items.contains(i.id),
                        selectedColor: AppColors.primarySoft,
                        onSelected: (v) => setState(
                          () => v ? _items.add(i.id) : _items.remove(i.id),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        AppButton(
          label: l.saveChanges,
          variant: AppButtonVariant.small,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
