import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../account/data/account_repository.dart';
import '../catalog/data/catalog_repository.dart';
import '../orders/data/orders_repository.dart';
import 'cart_controller.dart';
import 'checkout_widgets.dart';

enum PayMethod { cash, card, ccp }

/// Checkout: where it goes, what's in it, a promo code, how to pay, the
/// exact price (discount, delivery, tax), then one button with the total.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _placing = false;

  /// Shown above the button (a snack bar would cover it).
  String? _error;

  /// Chosen in the "Delivery details" sheet; null = default address.
  String? _addressId;
  String? _phone;
  String _notes = '';

  final _promoCtrl = TextEditingController();
  PromoQuote? _promo;
  String? _promoError;
  bool _checkingPromo = false;

  PayMethod _pay = PayMethod.cash;

  /// Same ref while the order doesn't change, so a retry after a lost
  /// response returns the order already placed instead of a second one.
  String? _clientRef;
  String? _refFor;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Address? _address(List<Address> all) {
    if (all.isEmpty) return null;
    return all.where((a) => a.id == _addressId).firstOrNull ??
        all.where((a) => a.isDefault).firstOrNull ??
        all.first;
  }

  String get _profilePhone =>
      ref.read(profileProvider).value?.phone?.trim() ?? '';

  String get _effectivePhone => _phone ?? _profilePhone;

  Future<void> _addAddress() async {
    await context.push('/account/addresses/new');
    ref.invalidate(addressesProvider);
  }

  Future<bool> _editDetails() async {
    final all = ref.read(addressesProvider).value ?? const <Address>[];
    final result = await showModalBottomSheet<DeliveryDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DeliveryDetailsSheet(
        addresses: all,
        initial: DeliveryDetails(
          addressId: _address(all)?.id,
          phone: _effectivePhone,
          notes: _notes,
        ),
        onAddAddress: () async {
          Navigator.of(context).pop();
          await _addAddress();
        },
      ),
    );
    if (result == null || !mounted) return false;
    setState(() {
      _addressId = result.addressId;
      _phone = result.phone;
      _notes = result.notes;
    });
    return true;
  }

  Future<void> _applyPromo() async {
    final l = AppLocalizations.of(context);
    final code = _promoCtrl.text.trim();
    final cart = ref.read(cartProvider);
    if (code.isEmpty || cart.restaurantId == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _checkingPromo = true;
      _promoError = null;
    });
    try {
      final q = await ref
          .read(ordersRepositoryProvider)
          .checkPromo(cart.restaurantId!, code, cart.subtotal);
      if (mounted) setState(() => _promo = q);
    } on CheckoutError catch (e) {
      if (mounted) {
        setState(() => _promoError = checkoutErrorText(l, e.failure));
      }
    } finally {
      if (mounted) setState(() => _checkingPromo = false);
    }
  }

  void _removePromo() => setState(() {
    _promo = null;
    _promoError = null;
    _promoCtrl.clear();
  });

  Future<void> _place(OrderPrice price) async {
    final l = AppLocalizations.of(context);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || cart.restaurantId == null) return;

    final addresses = ref.read(addressesProvider).value ?? const <Address>[];
    final address = _address(addresses);
    if (address == null) {
      setState(() => _error = l.errAddressRequired);
      await _addAddress();
      return;
    }
    var phone = normalizeDzPhone(_effectivePhone);
    if (phone == null) {
      setState(() => _error = l.errPhoneInvalid);
      if (!await _editDetails()) return;
      phone = normalizeDzPhone(_effectivePhone);
      if (phone == null) return;
    }

    final signature = [
      cart.restaurantId,
      for (final x in cart.lines) '${x.item.id}x${x.quantity}',
      address.id,
      phone,
      _notes,
      _promo?.code,
      price.total,
    ].join('|');
    if (signature != _refFor) {
      _refFor = signature;
      _clientRef = newClientRef();
    }

    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final placed = await ref
          .read(ordersRepositoryProvider)
          .placeOrder(
            PlaceOrderRequest(
              restaurantId: cart.restaurantId!,
              items: [
                for (final x in cart.lines)
                  (
                    id: x.item.id,
                    qty: x.quantity,
                    options: [for (final o in x.options) o.id],
                  ),
              ],
              addressId: address.id,
              phone: phone,
              notes: _notes.trim(),
              expectedTotal: price.total,
              clientRef: _clientRef!,
              promoCode: _promo?.code,
              paymentMethod: _pay.name,
            ),
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      ref.invalidate(profileProvider); // the phone may have been saved
      if (mounted) context.go('/orders/${placed.id}/placed');
    } on CheckoutError catch (e) {
      if (!mounted) return;
      await _handleFailure(e.failure);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _handleFailure(CheckoutFailure f) async {
    final l = AppLocalizations.of(context);
    switch (f) {
      case CheckoutFailure.itemUnavailable ||
          CheckoutFailure.pricesChanged ||
          CheckoutFailure.optionsInvalid:
        // Reload the menu: removed dishes / options leave the cart.
        await _refreshCart();
        if (!mounted) return;
        setState(() => _error = checkoutErrorText(l, f));
      case CheckoutFailure.addressNotFound:
        _addressId = null;
        ref.invalidate(addressesProvider);
        setState(() => _error = l.errAddressGone);
      case CheckoutFailure.promoInvalid ||
          CheckoutFailure.promoNotHere ||
          CheckoutFailure.promoNotStarted ||
          CheckoutFailure.promoExpired ||
          CheckoutFailure.promoMinOrder ||
          CheckoutFailure.promoUsedUp ||
          CheckoutFailure.promoAlreadyUsed:
        // The code stopped working meanwhile: drop it, show why.
        setState(() {
          _promo = null;
          _promoError = checkoutErrorText(l, f);
          _error = checkoutErrorText(l, f);
        });
      default:
        setState(() => _error = checkoutErrorText(l, f));
    }
  }

  /// Reloads prices/availability of the cart's dishes, the fee and the tax.
  Future<void> _refreshCart() async {
    ref.invalidate(deliveryFeeProvider);
    ref.invalidate(taxRateProvider);
    final ids = [for (final x in ref.read(cartProvider).lines) x.item.id];
    try {
      final current = await ref.read(catalogRepositoryProvider).itemsByIds(ids);
      ref.read(cartProvider.notifier).syncWith(current);
    } catch (_) {
      // Keep the cart as it is; the next attempt checks again.
    }
    // A percent code depends on the subtotal: check it again.
    if (_promo != null) await _applyPromo();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cart = ref.watch(cartProvider);
    final fee = ref.watch(deliveryFeeProvider).value;
    final taxRate = ref.watch(taxRateProvider).value;
    final addresses = ref.watch(addressesProvider);
    ref.watch(profileProvider); // prefill the phone

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l.checkout),
              Expanded(child: Center(child: Text(l.cartEmpty))),
            ],
          ),
        ),
      );
    }

    final price = fee == null || taxRate == null
        ? null
        : OrderPrice(
            food: cart.subtotal,
            fee: fee,
            taxRate: taxRate,
            discount: _promo?.discount ?? 0,
          );
    final address = addresses.value == null ? null : _address(addresses.value!);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                PageHeader(title: l.checkout),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _Section(
                        icon: Icons.location_on_rounded,
                        title: l.deliveryAddress,
                        action: address == null ? l.add : l.edit,
                        onAction: addresses.value?.isEmpty ?? true
                            ? _addAddress
                            : _editDetails,
                        child: addresses.isLoading && !addresses.hasValue
                            ? const LinearProgressIndicator(
                                color: AppColors.primary,
                              )
                            : _AddressBlock(
                                address: address,
                                phone: _effectivePhone,
                                notes: _notes,
                                onAdd: _addAddress,
                              ),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        icon: Icons.receipt_long_rounded,
                        title: l.orderSummary,
                        action: l.edit,
                        onAction: () => context.canPop()
                            ? context.pop()
                            : context.go('/cart'),
                        child: _Summary(cart: cart, lang: lang),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        icon: Icons.local_offer_rounded,
                        title: l.promoCode,
                        child: _promo == null
                            ? _PromoInput(
                                controller: _promoCtrl,
                                checking: _checkingPromo,
                                error: _promoError,
                                onApply: _applyPromo,
                              )
                            : _PromoTicket(
                                quote: _promo!,
                                lang: lang,
                                onRemove: _removePromo,
                              ),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        icon: Icons.account_balance_wallet_rounded,
                        title: l.paymentMethod,
                        child: Column(
                          children: [
                            _PayTile(
                              icon: Icons.payments_rounded,
                              title: l.cashOnDelivery,
                              subtitle: l.payCashHint,
                              selected: _pay == PayMethod.cash,
                              onTap: () =>
                                  setState(() => _pay = PayMethod.cash),
                            ),
                            const SizedBox(height: 10),
                            _PayTile(
                              icon: Icons.credit_card_rounded,
                              title: l.payCard,
                              soon: true,
                              selected: false,
                            ),
                            const SizedBox(height: 10),
                            _PayTile(
                              icon: Icons.account_balance_rounded,
                              title: l.payCcp,
                              soon: true,
                              selected: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (price != null)
                        _PriceCard(price: price, taxRate: taxRate!, lang: lang),
                    ],
                  ),
                ),
                _BottomBar(
                  price: price,
                  lang: lang,
                  placing: _placing,
                  error: _error,
                  onPlace: price == null || _placing
                      ? null
                      : () => _place(price),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White card with an icon, a title and an optional action ("Edit").
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? .3 : .05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  action!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({
    required this.address,
    required this.phone,
    required this.notes,
    required this.onAdd,
  });
  final Address? address;
  final String phone;
  final String notes;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = address;
    if (a == null) {
      return OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(l.addDeliveryAddress),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }
    Widget line(IconData icon, String text, {Color? color, bool ltr = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  textDirection: ltr ? TextDirection.ltr : null,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: color ?? AppColors.body),
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [a.addressText, a.area].where((s) => s.isNotEmpty).join(', '),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if (a.details.isNotEmpty) line(Icons.apartment_rounded, a.details),
        line(
          Icons.call_outlined,
          phone.isEmpty ? l.phone : phone,
          color: phone.isEmpty ? AppColors.danger : null,
          ltr: phone.isNotEmpty,
        ),
        if (notes.isNotEmpty) line(Icons.sticky_note_2_outlined, notes),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart, required this.lang});
  final Cart cart;
  final String lang;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (cart.restaurantName != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            cart.restaurantName!,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      for (final x in cart.lines)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${x.quantity}×',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.item.name, style: TextStyle(color: AppColors.ink)),
                    if (x.optionsText.isNotEmpty)
                      Text(
                        x.optionsText,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                formatDzd(x.unitPrice * x.quantity, lang),
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _PromoInput extends StatelessWidget {
  const _PromoInput({
    required this.controller,
    required this.checking,
    required this.error,
    required this.onApply,
  });
  final TextEditingController controller;
  final bool checking;
  final String? error;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onApply(),
                style: TextStyle(
                  color: AppColors.ink,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: l.promoHint,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.field,
                  prefixIcon: Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.muted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: error == null
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.danger),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: error == null
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: checking ? null : onApply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.night,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.applyPromo),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The applied code, drawn as a green ticket.
class _PromoTicket extends StatelessWidget {
  const _PromoTicket({
    required this.quote,
    required this.lang,
    required this.onRemove,
  });
  final PromoQuote quote;
  final String lang;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final what = quote.kind == 'percent'
        ? '−${quote.value} %'
        : '−${formatDzd(quote.value, lang)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: .5),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.promoApplied(quote.code),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$what · −${formatDzd(quote.discount, lang)}',
                  style: TextStyle(color: AppColors.body, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.removePromo),
          ),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.icon,
    required this.title,
    required this.selected,
    this.subtitle,
    this.soon = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool soon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = soon ? AppColors.muted : AppColors.ink;
    return Semantics(
      selected: selected,
      enabled: !soon,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.field,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: soon ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: soon
                      ? AppColors.muted
                      : selected
                      ? AppColors.primary
                      : AppColors.body,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (soon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.comingSoon,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtotal, discount, delivery, tax, total.
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.taxRate,
    required this.lang,
  });
  final OrderPrice price;
  final double taxRate;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rate =
        '${(taxRate * 100).toStringAsFixed(taxRate * 100 % 1 == 0 ? 0 : 1)} %';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyRow(label: l.subtotal, value: formatDzd(price.food, lang)),
          if (price.discount > 0)
            MoneyRow(
              label: l.discount,
              value: '−${formatDzd(price.discount, lang)}',
              color: AppColors.success,
            ),
          MoneyRow(
            label: l.deliveryFee,
            value: price.fee == 0 ? l.freeDelivery : formatDzd(price.fee, lang),
          ),
          if (taxRate > 0)
            MoneyRow(label: l.taxLine(rate), value: formatDzd(price.tax, lang)),
          Divider(color: AppColors.border, height: 24),
          MoneyRow(
            label: l.total,
            value: formatDzd(price.total, lang),
            strong: true,
          ),
          if (price.discount > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.youSave(formatDzd(price.discount, lang)),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.price,
    required this.lang,
    required this.placing,
    required this.error,
    required this.onPlace,
  });
  final OrderPrice? price;
  final String lang;
  final bool placing;
  final String? error;
  final VoidCallback? onPlace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SheetPanel(
      showHandle: false,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: price == null
                ? l.placeOrder
                : l.placeOrderTotal(formatDzd(price!.total, lang)),
            loading: placing,
            onPressed: onPlace,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                l.payOnDeliveryNote,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
