import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/sunburst.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/orders_repository.dart';

/// Shown right after PLACE ORDER (the kit's "Payment Successful" screen,
/// adapted to cash on delivery).
class OrderPlacedPage extends ConsumerWidget {
  const OrderPlacedPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final order = ref.watch(myOrderProvider(orderId)).value;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  SizedBox.square(
                    dimension: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Sunburst(
                          radius: 70,
                          strokeWidth: 70,
                          dash: 4,
                          color: AppColors.primaryPale,
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l.orderPlacedTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.orderNumber(order.code),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.orderPlacedBody(formatDzd(order.total, lang)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                  const Spacer(),
                  AppButton(
                    label: l.trackOrder,
                    onPressed: () => context.go('/orders/$orderId'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      l.backToHome,
                      style: TextStyle(color: AppColors.body),
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
