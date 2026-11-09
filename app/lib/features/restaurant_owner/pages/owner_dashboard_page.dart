import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/owner_orders_repository.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_widgets.dart';

/// Seller Dashboard Home: restaurant name + area, approval banner, open /
/// closed switch, live order counters, menu summary.
class OwnerDashboardPage extends ConsumerWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myRestaurantProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const OwnerBottomBar(current: OwnerTab.dashboard),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AsyncBody(
              value: mine,
              onRetry: () => ref.invalidate(myRestaurantProvider),
              builder: (r) => r == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(myRestaurantProvider);
                        ref.invalidate(myItemsProvider(r.id));
                      },
                      child: _Body(restaurant: r),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.restaurant});
  final OwnedRestaurant restaurant;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _switching = false;

  Future<void> _toggle(bool open) async {
    final l = AppLocalizations.of(context);
    setState(() => _switching = true);
    try {
      await ref
          .read(ownerRepositoryProvider)
          .setOpen(widget.restaurant.id, open);
      ref.invalidate(myRestaurantProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.restaurant;
    final items = ref.watch(myItemsProvider(r.id)).value;
    final available = items?.where((i) => i.isAvailable).length ?? 0;
    final active = ref.watch(ownerActiveOrdersProvider).value;
    String two(int? n) => n == null ? '--' : n.toString().padLeft(2, '0');
    final running = active?.where((o) => o.isRunning).length;
    final requests = active?.where((o) => o.isNew).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        // Header: area label + name, logo on the end side.
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (r.area.isEmpty ? l.restaurant : r.area).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF676767),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/restaurant/profile'),
              child: AppImage(
                url: r.logoUrl,
                width: 45,
                height: 45,
                radius: 22.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!r.isActive) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD8A8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.pendingApprovalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.pendingApprovalBody,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        DashCard(
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r.isOpen ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.isOpen ? l.openForOrders : l.closedForOrders,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.isActive ? l.openSwitchHint : l.cantOpenPending,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: r.isOpen,
                activeTrackColor: AppColors.primary,
                onChanged: !r.isActive || _switching ? null : _toggle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: two(running),
                label: l.runningOrders,
                onTap: () => context.go('/restaurant/orders?tab=running'),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: StatCard(
                value: two(requests),
                label: l.orderRequests,
                onTap: () => context.go('/restaurant/orders?tab=new'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const CashToReceiveCard(),
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.myMenu,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/restaurant/menu'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      l.seeMenu,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l.totalItems(items?.length ?? 0),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l.dishesAvailable(available, items.length),
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ],
              if (items != null && items.isEmpty) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: l.addItem,
                  variant: AppButtonVariant.small,
                  icon: Icons.add_rounded,
                  onPressed: () => context.push('/restaurant/menu/new'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// "Money to receive from drivers": delivered orders whose food money the
/// restaurant hasn't confirmed. Hidden when there is none.
class CashToReceiveCard extends ConsumerStatefulWidget {
  const CashToReceiveCard({super.key});

  @override
  ConsumerState<CashToReceiveCard> createState() => _CashToReceiveCardState();
}

class _CashToReceiveCardState extends ConsumerState<CashToReceiveCard> {
  String? _busy;

  Future<void> _confirm(CashToReceive c) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          l.confirmReceivedQ(
            formatDzd(c.amount, lang),
            c.driverName.isEmpty ? l.driverSection : c.driverName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back, style: const TextStyle(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.confirmReceived,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = c.orderId);
    try {
      await ref.read(ownerOrdersRepositoryProvider).confirmCash(c.orderId);
      if (mounted) showAppSnack(context, l.cashConfirmedMsg);
    } on OwnerOrderError catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          e.failure == OwnerOrderFailure.network
              ? l.errNetwork
              : l.errOrderChanged,
          error: true,
        );
      }
    } finally {
      ref.invalidate(ownerCashPendingProvider);
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final items = ref.watch(ownerCashPendingProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold(0, (s, c) => s + c.amount);
    final when = DateFormat('dd/MM HH:mm');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.cashToReceive,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  formatDzd(total, lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            for (final c in items) ...[
              const Divider(color: AppColors.border, height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (c.driverName.isNotEmpty) c.driverName,
                            if (c.driverPhone.isNotEmpty) c.driverPhone,
                          ].join(' · '),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '#${c.code} · ${l.deliveredOnTime(when.format(c.deliveredAt))}',
                          style: const TextStyle(color: AppColors.body),
                        ),
                        if (c.handedAt != null)
                          Text(
                            l.driverSaysHanded,
                            style: const TextStyle(color: AppColors.success),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatDzd(c.amount, lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(
                  label: l.confirmReceived,
                  variant: AppButtonVariant.small,
                  loading: _busy == c.orderId,
                  onPressed: _busy == null ? () => _confirm(c) : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
