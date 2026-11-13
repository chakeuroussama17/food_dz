import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'cart_controller.dart';
import 'checkout_widgets.dart';

/// "My Cart" from the design: dark list of dishes, then the subtotal and
/// "Go to checkout" (address, promo code, payment and total are there).
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    // "Added to cart" from the previous page would float over the button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cart = ref.watch(cartProvider);

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
                            key: ValueKey(line.key),
                            line: line,
                            editing: _editing,
                            lang: lang,
                            onQuantity: (q) => ref
                                .read(cartProvider.notifier)
                                .setQuantity(line.key, q),
                          ),
                      ],
                    ),
                  ),
                  SheetPanel(
                    showHandle: false,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${l.subtotal.toUpperCase()}:',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.muted,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                formatDzd(cart.subtotal, lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              l.itemCount(
                                cart.lines.fold(0, (n, x) => n + x.quantity),
                              ),
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          label: l.goToCheckout,
                          onPressed: () => context.push('/checkout'),
                        ),
                      ],
                    ),
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
