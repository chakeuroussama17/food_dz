import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pick_image.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_widgets.dart';

/// Add New Items: ITEM NAME, photo, PRICE, CATEGORY, AVAILABLE, DETAILS,
/// SAVE CHANGES. With [existing] it edits the dish (and can delete it).
class OwnerItemFormPage extends ConsumerStatefulWidget {
  const OwnerItemFormPage({super.key, this.existing});
  final MenuItem? existing;

  @override
  ConsumerState<OwnerItemFormPage> createState() => _OwnerItemFormPageState();
}

class _OwnerItemFormPageState extends ConsumerState<OwnerItemFormPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.price}',
  );
  late final _details = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late String? _photoUrl = widget.existing?.photoUrl;
  late String? _categoryId = widget.existing?.categoryId;
  late bool _available = widget.existing?.isAvailable ?? true;
  bool _uploading = false;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _details.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      final e = widget.existing;
      _name.text = e?.name ?? '';
      _price.text = e == null ? '' : '${e.price}';
      _details.text = e?.description ?? '';
      _photoUrl = e?.photoUrl;
      _categoryId = e?.categoryId;
      _available = e?.isAvailable ?? true;
    });
  }

  Future<void> _pickPhoto(String restaurantId) async {
    final l = AppLocalizations.of(context);
    try {
      final img = await pickImage();
      if (img == null) return;
      setState(() => _uploading = true);
      final url = await ref
          .read(ownerRepositoryProvider)
          .uploadImage(restaurantId, img.bytes, img.extension);
      if (mounted) setState(() => _photoUrl = url);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save(String restaurantId) async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final input = MenuItemInput(
      name: _name.text,
      price: int.parse(_price.text.trim()),
      description: _details.text,
      categoryId: _categoryId,
      photoUrl: _photoUrl,
      isAvailable: _available,
    );
    final repo = ref.read(ownerRepositoryProvider);
    try {
      if (_editing) {
        await repo.updateItem(widget.existing!.id, input);
      } else {
        await repo.addItem(restaurantId, input);
      }
      ref.invalidate(myItemsProvider(restaurantId));
      if (!mounted) return;
      showAppSnack(context, l.saved);
      context.canPop() ? context.pop() : context.go('/restaurant/menu');
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String restaurantId) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteItemConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppColors.body),
            ),
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
      await ref.read(ownerRepositoryProvider).deleteItem(widget.existing!.id);
      ref.invalidate(myItemsProvider(restaurantId));
      if (mounted) {
        context.canPop() ? context.pop() : context.go('/restaurant/menu');
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final restaurant = ref.watch(myRestaurantProvider).value;
    final cats = ref.watch(categoriesProvider).value ?? const <FoodCategory>[];
    if (restaurant == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: ListView(
                children: [
                  PageHeader(
                    title: _editing ? l.editItem : l.addItem,
                    trailing: TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        l.reset.toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: l.itemName,
                          controller: _name,
                          hint: l.itemNameHint,
                          maxLength: 80,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            return t.isEmpty || t.length > 80
                                ? l.errNameRequired
                                : null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.uploadPhoto.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: PhotoTile(
                            url: _photoUrl,
                            busy: _uploading,
                            onTap: () => _pickPhoto(restaurant.id),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: LabeledField(
                                label: l.price,
                                controller: _price,
                                hint: l.priceHint,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                validator: (v) {
                                  final n = int.tryParse((v ?? '').trim());
                                  return n == null || n < 10 || n > 100000
                                      ? l.errPrice
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Column(
                                children: [
                                  Switch.adaptive(
                                    value: _available,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (v) =>
                                        setState(() => _available = v),
                                  ),
                                  Text(
                                    l.available,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.subtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.category.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  PillChips<String?>(
                    items: [null, ...cats.map((c) => c.id)],
                    selected: _categoryId,
                    filledUnselected: true,
                    labelOf: (id) => id == null
                        ? l.noCategory
                        : cats.firstWhere((c) => c.id == id).name(lang),
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: l.itemDetails,
                          controller: _details,
                          hint: l.itemDetailsHint,
                          optionalLabel: l.optional,
                          maxLines: 4,
                          maxLength: 300,
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          label: l.saveChanges,
                          loading: _saving,
                          onPressed: _uploading
                              ? null
                              : () => _save(restaurant.id),
                        ),
                        if (_editing) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _delete(restaurant.id),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                            label: Text(
                              l.delete,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ],
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
