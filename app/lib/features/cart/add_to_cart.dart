import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/data/catalog_models.dart';
import 'cart_controller.dart';

/// Adds a dish to the cart. If the cart holds another restaurant's dishes,
/// asks before starting a new cart. Returns true when added.
Future<bool> addToCartWithPrompt(
  BuildContext context,
  WidgetRef ref, {
  required MenuItem item,
  required String restaurantName,
  required bool restaurantOpen,
  int quantity = 1,
}) async {
  final l = AppLocalizations.of(context);
  if (!restaurantOpen) {
    showAppSnack(context, l.restaurantClosedNote, error: true);
    return false;
  }
  final cart = ref.read(cartProvider.notifier);
  var result = cart.add(
    item,
    restaurantName: restaurantName,
    quantity: quantity,
  );
  if (result == AddResult.otherRestaurant) {
    final current = ref.read(cartProvider).restaurantName ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.cartOtherRestaurant(current)),
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
              l.newCart,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    result = cart.add(
      item,
      restaurantName: restaurantName,
      quantity: quantity,
      replace: true,
    );
  }
  if (context.mounted) showAppSnack(context, l.addedToCart);
  return true;
}
