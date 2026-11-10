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

/// "My Cart" from the design: dark list of dishes, then a white panel with
/// the delivery address, the total and PLACE ORDER. Checkout happens here:
/// cash on delivery is the only payment method, so there's no payment step.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _editing = false;
  bool _placing = false;

  /// Shown above PLACE ORDER (a snack bar would cover the button).
  String? _error;

  /// Chosen in the "Delivery details" sheet; null = default address.
  String? _addressId;
  String? _phone;
  String _notes = '';

  /// Same ref while the order doesn't change, so a retry after a lost
  /// response returns the order already placed instead of a second one.
  String? _clientRef;
  String? _refFor;

  @override
  void initState() {
    super.initState();
    // "Added to cart" from the previous page would float over PLACE ORDER.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
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

  Future<void> _showBreakdown(int subtotal, int fee) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => BreakdownSheet(subtotal: subtotal, fee: fee),
  );

  Future<void> _place(int fee) async {
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

    final total = cart.subtotal + fee;
    final signature = [
      cart.restaurantId,
      for (final x in cart.lines) '${x.item.id}x${x.quantity}',
      address.id,
      phone,
      _notes,
      total,
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
                for (final x in cart.lines) (id: x.item.id, qty: x.quantity),
              ],
              addressId: address.id,
              phone: phone,
              notes: _notes.trim(),
              expectedTotal: total,
              clientRef: _clientRef!,
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
      case CheckoutFailure.itemUnavailable || CheckoutFailure.pricesChanged:
        await _refreshCart();
        if (!mounted) return;
        setState(
          () => _error = f == CheckoutFailure.itemUnavailable
              ? l.errItemUnavailable
              : l.errPricesChanged,
        );
      case CheckoutFailure.addressNotFound:
        _addressId = null;
        ref.invalidate(addressesProvider);
        setState(() => _error = l.errAddressGone);
      default:
        setState(() => _error = checkoutErrorText(l, f));
    }
  }

  /// Reloads prices/availability of the cart's dishes and the fee.
  Future<void> _refreshCart() async {
    ref.invalidate(deliveryFeeProvider);
    final ids = [for (final x in ref.read(cartProvider).lines) x.item.id];
    try {
      final current = await ref.read(catalogRepositoryProvider).itemsByIds(ids);
      ref.read(cartProvider.notifier).syncWith(current);
    } catch (_) {
      // Keep the cart as it is; the next attempt checks again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cart = ref.watch(cartProvider);
    final fee = ref.watch(deliveryFeeProvider).value;
    final addresses = ref.watch(addressesProvider);
    ref.watch(profileProvider); // prefill the phone

    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _Header(
                  title: l.cart,
                  editing: _editing,
                  showEdit: !cart.isEmpty,
                  onToggle: () => setState(() => _editing = !_editing),
                ),
                if (cart.isEmpty)
                  Expanded(child: _Empty(text: l.cartEmpty))
                else ...[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        if (cart.restaurantName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              cart.restaurantName!,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        for (final line in cart.lines)
                          CartLineTile(
                            key: ValueKey(line.item.id),
                            line: line,
                            editing: _editing,
                            lang: lang,
                            onQuantity: (q) => ref
                                .read(cartProvider.notifier)
                                .setQuantity(line.item.id, q),
                          ),
                      ],
                    ),
                  ),
                  _CheckoutPanel(
                    address: addresses.when(
                      data: (all) => _address(all),
                      loading: () => null,
                      error: (_, _) => null,
                    ),
                    addressesLoading: addresses.isLoading,
                    phone: _effectivePhone,
                    total: fee == null ? null : cart.subtotal + fee,
                    lang: lang,
                    placing: _placing,
                    error: _error,
                    onEdit: () => addresses.value?.isEmpty ?? true
                        ? _addAddress()
                        : _editDetails(),
                    onBreakdown: fee == null
                        ? null
                        : () => _showBreakdown(cart.subtotal, fee),
                    onPlace: fee == null || _placing ? null : () => _place(fee),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.editing,
    required this.showEdit,
    required this.onToggle,
  });

  final String title;
  final bool editing;
  final bool showEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            background: Colors.white.withValues(alpha: 0.12),
            foreground: Colors.white,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
          if (showEdit)
            TextButton(
              onPressed: onToggle,
              child: Text(
                (editing
                        ? MaterialLocalizations.of(context).okButtonLabel
                        : l.edit)
                    .toUpperCase(),
                style: TextStyle(
                  color: editing ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: editing
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 56,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}

/// White bottom panel: DELIVERY ADDRESS / EDIT, the address box, TOTAL with
/// Breakdown, PLACE ORDER.
class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.address,
    required this.addressesLoading,
    required this.phone,
    required this.total,
    required this.lang,
    required this.placing,
    required this.error,
    required this.onEdit,
    required this.onBreakdown,
    required this.onPlace,
  });

  final Address? address;
  final bool addressesLoading;
  final String phone;
  final int? total;
  final String lang;
  final bool placing;
  final String? error;
  final VoidCallback onEdit;
  final VoidCallback? onBreakdown;
  final VoidCallback? onPlace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = TextStyle(
      fontSize: 14,
      color: AppColors.muted,
      letterSpacing: 0.4,
    );
    return SheetPanel(
      showHandle: false,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.deliveryAddress.toUpperCase(), style: label),
              ),
              InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    (address == null ? l.add : l.edit).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: addressesLoading
                    ? const SizedBox(
                        height: 20,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address == null
                                ? l.addDeliveryAddress
                                : [
                                    address!.addressText,
                                    address!.area,
                                  ].where((s) => s.isNotEmpty).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: address == null
                                  ? AppColors.primary
                                  : AppColors.inkSoft.withValues(alpha: 0.75),
                            ),
                          ),
                          if (address != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.call_outlined,
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  phone.isEmpty ? l.phone : phone,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: phone.isEmpty
                                        ? AppColors.danger
                                        : AppColors.body,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.payments_outlined,
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l.cashOnDelivery,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.body,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${l.total.toUpperCase()}:', style: label),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  total == null ? '…' : formatDzd(total!, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 30, color: AppColors.ink),
                ),
              ),
              InkWell(
                onTap: onBreakdown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.breakdown,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
            const SizedBox(height: 12),
          ],
          AppButton(label: l.placeOrder, loading: placing, onPressed: onPlace),
        ],
      ),
    );
  }
}
