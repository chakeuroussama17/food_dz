import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/widgets/map_pin_picker.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/account_repository.dart';
import 'addresses_page.dart';

/// Add New Address: map on top with a fixed centre pin (move the map to
/// place it), ADDRESS / AREA / DETAILS fields, LABEL AS chips,
/// SAVE LOCATION. Also used to edit an existing address.
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({super.key, this.existing});

  /// Null = new address.
  final Address? existing;

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: widget.existing?.addressText ?? '',
  );
  late final _area = TextEditingController(text: widget.existing?.area ?? '');
  late final _details = TextEditingController(
    text: widget.existing?.details ?? '',
  );
  late AddressLabel _label = widget.existing?.label ?? AddressLabel.home;
  late LatLng _pin = _initialPin();
  bool _saving = false;

  LatLng _initialPin() {
    final e = widget.existing;
    if (e?.lat != null && e?.lng != null) return LatLng(e!.lat!, e.lng!);
    final p = ref.read(locationProvider).position;
    return p == null ? algiersCenter : LatLng(p.lat, p.lng);
  }

  @override
  void dispose() {
    _address.dispose();
    _area.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final input = AddressInput(
      label: _label,
      addressText: _address.text,
      area: _area.text,
      details: _details.text,
      lat: _pin.latitude,
      lng: _pin.longitude,
    );
    final repo = ref.read(accountRepositoryProvider);
    try {
      if (widget.existing == null) {
        final isFirst = (ref.read(addressesProvider).value ?? const []).isEmpty;
        await repo.addAddress(input, makeDefault: isFirst);
      } else {
        await repo.updateAddress(widget.existing!.id, input);
      }
      ref.invalidate(addressesProvider);
      if (!mounted) return;
      showAppSnack(context, l.saved);
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      final limit = e.toString().contains('address limit');
      showAppSnack(
        context,
        limit ? l.errAddressLimit : l.errGeneric,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mapHeight = (MediaQuery.sizeOf(context).height * .36).clamp(
      200.0,
      320.0,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: mapHeight + MediaQuery.paddingOf(context).top,
              child: MapPinPicker(
                initial: _pin,
                onChanged: (p) => _pin = p,
                topPadding: MediaQuery.paddingOf(context).top,
                topStart: CircleIconButton.back(context, dark: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: l.address,
                    controller: _address,
                    hint: l.addressHint,
                    prefixIcon: Icons.location_on_rounded,
                    maxLength: 200,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.fullStreetAddress],
                    validator: (v) => (v ?? '').trim().length < 3
                        ? l.errAddressRequired
                        : null,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: l.area,
                    controller: _area,
                    hint: l.areaHint,
                    maxLength: 80,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: l.addressDetails,
                    controller: _details,
                    optionalLabel: l.optional,
                    maxLength: 120,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.labelAs.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            PillChips<AddressLabel>(
              items: AddressLabel.values,
              selected: _label,
              labelOf: (a) => addressLabelText(l, a),
              filledUnselected: true,
              onSelected: (a) => setState(() => _label = a),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: AppButton(
                label: l.saveLocation,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
