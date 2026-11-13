import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/utils/pick_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/map_pin_picker.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_widgets.dart';

/// Restaurant profile: cover + logo, name, description, phone, address,
/// area, preparation time, map pin. Opened from the Account tab.
class OwnerProfilePage extends ConsumerWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myRestaurantProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AsyncBody(
              value: mine,
              onRetry: () => ref.invalidate(myRestaurantsProvider),
              builder: (r) =>
                  r == null ? const SizedBox.shrink() : _Form(restaurant: r),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.restaurant});
  final OwnedRestaurant restaurant;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late final r = widget.restaurant;
  late final _name = TextEditingController(text: r.name);
  late final _description = TextEditingController(text: r.description);
  late final _phone = TextEditingController(text: r.phone);
  late final _address = TextEditingController(text: r.address);
  late final _area = TextEditingController(text: r.area);
  late final _prep = TextEditingController(text: '${r.prepMinutes}');
  late String? _cover = r.coverUrl;
  late String? _logo = r.logoUrl;
  late LatLng _pin = r.lat != null && r.lng != null
      ? LatLng(r.lat!, r.lng!)
      : algiersCenter;
  late bool _pinSet = r.lat != null;
  String? _uploading; // 'cover' | 'logo'
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _description, _phone, _address, _area, _prep]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(String kind) async {
    final l = AppLocalizations.of(context);
    try {
      final img = await pickImage(maxSide: kind == 'logo' ? 400 : 1280);
      if (img == null) return;
      setState(() => _uploading = kind);
      final url = await ref
          .read(ownerRepositoryProvider)
          .uploadImage(r.id, img.bytes, img.extension);
      if (!mounted) return;
      setState(() => kind == 'logo' ? _logo = url : _cover = url);
      // Saved at once (with the details as last saved), so the new photo
      // shows everywhere even without pressing Save.
      await ref
          .read(ownerRepositoryProvider)
          .updateDetails(
            r.id,
            RestaurantDetailsInput(
              name: r.name,
              description: r.description,
              phone: r.phone,
              address: r.address,
              area: r.area,
              prepMinutes: r.prepMinutes,
              lat: r.lat,
              lng: r.lng,
              coverUrl: _cover,
              logoUrl: _logo,
            ),
          );
      ref.invalidate(myRestaurantsProvider);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerRepositoryProvider)
          .updateDetails(
            r.id,
            RestaurantDetailsInput(
              name: _name.text,
              description: _description.text,
              phone: normalizeRestaurantPhone(_phone.text)!,
              address: _address.text,
              area: _area.text,
              prepMinutes: int.parse(_prep.text.trim()),
              lat: _pinSet ? _pin.latitude : null,
              lng: _pinSet ? _pin.longitude : null,
              coverUrl: _cover,
              logoUrl: _logo,
            ),
          );
      ref.invalidate(myRestaurantsProvider);
      if (mounted) showAppSnack(context, l.saved);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: ListView(
        children: [
          PageHeader(title: l.restaurantProfile),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.coverPhoto.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) => PhotoTile(
                    url: _cover,
                    busy: _uploading == 'cover',
                    width: c.maxWidth,
                    height: 150,
                    onTap: () => _pick('cover'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    PhotoTile(
                      url: _logo,
                      busy: _uploading == 'logo',
                      width: 80,
                      height: 80,
                      circle: true,
                      onTap: () => _pick('logo'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l.logo.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: l.restaurantName,
                  controller: _name,
                  maxLength: 80,
                  validator: (v) =>
                      isValidName(v ?? '') ? null : l.errNameRequired,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.description,
                  controller: _description,
                  hint: l.descriptionHint,
                  optionalLabel: l.optional,
                  maxLines: 3,
                  maxLength: 300,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.restaurantPhone,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (v) => normalizeRestaurantPhone(v ?? '') == null
                      ? l.errRestaurantPhone
                      : null,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.address,
                  controller: _address,
                  prefixIcon: Icons.location_on_rounded,
                  maxLength: 200,
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? l.errAddressRequired : null,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.area,
                  controller: _area,
                  hint: l.areaHint,
                  maxLength: 80,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.prepTime,
                  controller: _prep,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 5 || n > 120 ? l.errPrepTime : null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l.restaurantLocation.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: MapPinPicker(
                      initial: _pin,
                      onChanged: (p) {
                        _pin = p;
                        _pinSet = true;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: l.saveChanges,
                  loading: _saving,
                  onPressed: _uploading != null ? null : _save,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
