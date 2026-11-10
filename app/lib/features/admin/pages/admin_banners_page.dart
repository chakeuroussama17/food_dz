import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pick_image.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../banners/banners_repository.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

/// Picks the banner picture. Overridden in tests.
final pickBannerImageProvider = Provider<Future<PickedImage?> Function()>(
  (ref) =>
      () => pickImage(maxSide: 1600, maxBytes: 3 * 1024 * 1024),
);

/// Home banners (ads and news): add, switch on/off, reorder, delete.
class AdminBannersPage extends ConsumerStatefulWidget {
  const AdminBannersPage({super.key});

  @override
  ConsumerState<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends ConsumerState<AdminBannersPage> {
  String? _busy;

  Future<void> _run(String id, Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = id);
    try {
      await action();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      ref.invalidate(adminBannersProvider);
      ref.invalidate(homeBannersProvider);
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _AddBannerSheet(),
    );
    if (added == true) {
      ref.invalidate(adminBannersProvider);
      ref.invalidate(homeBannersProvider);
    }
  }

  Future<void> _delete(AdminBanner b) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteBannerConfirm),
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
    if (ok == true) {
      await _run(b.id, () => ref.read(bannersRepositoryProvider).delete(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = ref.watch(adminBannersProvider);
    final repo = ref.read(bannersRepositoryProvider);
    return AdminScaffold(
      section: AdminSection.settings,
      title: l.homeBanners,
      floatingAction: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(l.addBanner),
      ),
      body: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(adminBannersProvider),
        builder: (banners) => banners.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l.noBanners,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.body),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: banners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final b = banners[i];
                  final busy = _busy == b.id;
                  return AdminCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: bannerAspectRatio,
                          child: Opacity(
                            opacity: b.isActive ? 1 : .4,
                            child: AppImage(url: b.imageUrl, radius: 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title.isEmpty ? '—' : b.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (b.restaurantName != null)
                                    Text(
                                      '→ ${b.restaurantName}',
                                      style: TextStyle(color: AppColors.body),
                                    ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: b.isActive,
                              activeTrackColor: AppColors.primary,
                              onChanged: busy
                                  ? null
                                  : (v) => _run(
                                      b.id,
                                      () => repo.update(
                                        b.id,
                                        title: b.title,
                                        restaurantId: b.restaurantId,
                                        isActive: v,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: l.moveUp,
                              onPressed: busy || i == 0
                                  ? null
                                  : () => _run(b.id, () => repo.move(b.id, -1)),
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                            IconButton(
                              tooltip: l.moveDown,
                              onPressed: busy || i == banners.length - 1
                                  ? null
                                  : () => _run(b.id, () => repo.move(b.id, 1)),
                              icon: const Icon(Icons.arrow_downward_rounded),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: busy ? null : () => _delete(b),
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
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AddBannerSheet extends ConsumerStatefulWidget {
  const _AddBannerSheet();

  @override
  ConsumerState<_AddBannerSheet> createState() => _AddBannerSheetState();
}

class _AddBannerSheetState extends ConsumerState<_AddBannerSheet> {
  final _title = TextEditingController();
  PickedImage? _image;
  String? _restaurantId;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final l = AppLocalizations.of(context);
    try {
      final img = await ref.read(pickBannerImageProvider)();
      if (img != null && mounted) setState(() => _image = img);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final img = _image;
    if (img == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bannersRepositoryProvider)
          .add(img, title: _title.text.trim(), restaurantId: _restaurantId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final restaurants = (ref.watch(adminRestaurantsProvider).value ?? const [])
        .where((r) => r.isActive)
        .toList();
    final img = _image;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.addBanner, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l.bannerSizeHint,
                style: TextStyle(color: AppColors.body, fontSize: 13),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: bannerAspectRatio,
                child: Material(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pick,
                    child: img == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.choosePicture,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Image.memory(img.bytes, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: '${l.bannerTitle} (${l.optional})',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _restaurantId,
                decoration: InputDecoration(labelText: l.bannerOpens),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l.bannerNoLink),
                  ),
                  for (final r in restaurants)
                    DropdownMenuItem<String?>(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _restaurantId = v),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: l.save,
                loading: _saving,
                onPressed: img == null ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
