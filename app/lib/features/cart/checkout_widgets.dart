import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../account/data/account_repository.dart';
import '../orders/data/orders_repository.dart';
import 'cart_controller.dart';

String checkoutErrorText(AppLocalizations l, CheckoutFailure f) => switch (f) {
  CheckoutFailure.restaurantClosed => l.errRestaurantClosed,
  CheckoutFailure.restaurantUnavailable => l.errRestaurantUnavailable,
  CheckoutFailure.itemUnavailable => l.errItemUnavailable,
  CheckoutFailure.pricesChanged => l.errPricesChanged,
  CheckoutFailure.tooManyActiveOrders => l.errTooManyActiveOrders,
  CheckoutFailure.tooManyOrders => l.errTooManyOrders,
  CheckoutFailure.invalidPhone => l.errPhoneInvalid,
  CheckoutFailure.addressNotFound => l.errAddressGone,
  CheckoutFailure.cannotCancel => l.errCannotCancel,
  CheckoutFailure.network => l.errNetwork,
  CheckoutFailure.unknown => l.errGeneric,
};

/// One dish on the dark cart: photo, name, price, small (−) n (+) and, in
/// edit mode, a red remove button.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.editing,
    required this.lang,
    required this.onQuantity,
  });

  final CartLine line;
  final bool editing;
  final String lang;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget round(IconData icon, VoidCallback? onTap, String label) => Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: onTap == null ? 0.08 : 0.2),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(
            url: line.item.photoUrl,
            width: 136,
            height: 117,
            radius: 25,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        line.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (editing)
                      Semantics(
                        button: true,
                        label: l.delete,
                        child: InkResponse(
                          onTap: () => onQuantity(0),
                          radius: 18,
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE04444),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatDzd(line.lineTotal, lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDzd(line.item.price, lang),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    round(
                      Icons.remove_rounded,
                      () => onQuantity(line.quantity - 1),
                      '-',
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${line.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    round(
                      Icons.add_rounded,
                      line.quantity < maxQuantityPerItem
                          ? () => onQuantity(line.quantity + 1)
                          : null,
                      '+',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryDetails {
  const DeliveryDetails({
    required this.addressId,
    required this.phone,
    required this.notes,
  });
  final String? addressId;
  final String phone;
  final String notes;
}

/// "EDIT" on the cart: choose a saved address, the phone the restaurant
/// and driver will call, and notes.
class DeliveryDetailsSheet extends StatefulWidget {
  const DeliveryDetailsSheet({
    super.key,
    required this.addresses,
    required this.initial,
    required this.onAddAddress,
  });

  final List<Address> addresses;
  final DeliveryDetails initial;
  final VoidCallback onAddAddress;

  @override
  State<DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

class _DeliveryDetailsSheetState extends State<DeliveryDetailsSheet> {
  final _form = GlobalKey<FormState>();
  late String? _addressId = widget.initial.addressId;
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _notes = TextEditingController(text: widget.initial.notes);

  @override
  void dispose() {
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  IconData _icon(AddressLabel label) => switch (label) {
    AddressLabel.home => Icons.home_outlined,
    AddressLabel.work => Icons.work_outline_rounded,
    AddressLabel.other => Icons.place_outlined,
  };

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      DeliveryDetails(
        addressId: _addressId,
        phone: normalizeDzPhone(_phone.text)!,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC1C7D0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  l.deliveryDetails,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  l.deliveryAddress.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _addressId,
                  onChanged: (v) => setState(() => _addressId = v),
                  child: Column(
                    children: [
                      for (final a in widget.addresses)
                        RadioListTile<String>(
                          value: a.id,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          secondary: Icon(
                            _icon(a.label),
                            color: AppColors.body,
                          ),
                          title: Text(
                            a.addressText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                          ),
                          subtitle: a.area.isEmpty
                              ? null
                              : Text(
                                  a.area,
                                  style: TextStyle(color: AppColors.body),
                                ),
                        ),
                    ],
                  ),
                ),
                if (widget.addresses.length < 10)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: widget.onAddAddress,
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        l.addNewAddress,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                LabeledField(
                  label: l.phone,
                  controller: _phone,
                  hint: '0550 12 34 56',
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  maxLength: 20,
                  validator: (v) => normalizeDzPhone(v ?? '') == null
                      ? l.errPhoneInvalid
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  l.phoneForDriver,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: l.notes,
                  optionalLabel: l.optional,
                  controller: _notes,
                  hint: l.notesHint,
                  maxLines: 2,
                  maxLength: 300,
                ),
                const SizedBox(height: 24),
                AppButton(label: l.save, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Breakdown >" on the cart.
class BreakdownSheet extends StatelessWidget {
  const BreakdownSheet({super.key, required this.subtotal, required this.fee});
  final int subtotal;
  final int fee;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.breakdown, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            MoneyRow(label: l.subtotal, value: formatDzd(subtotal, lang)),
            MoneyRow(
              label: l.deliveryFee,
              value: fee == 0 ? l.freeDelivery : formatDzd(fee, lang),
            ),
            const Divider(height: 24),
            MoneyRow(
              label: l.total,
              value: formatDzd(subtotal + fee, lang),
              strong: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(l.cashOnDelivery, style: TextStyle(color: AppColors.body)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Label ........ 1 250 DA".
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: strong ? 17 : 15,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
      color: strong ? AppColors.ink : AppColors.body,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
