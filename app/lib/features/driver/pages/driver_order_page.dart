import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../../../core/utils/pick_image.dart';
import '../data/driver_live.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';

/// One delivery: pick up at the restaurant, deliver to the customer, cash.
class DriverOrderPage extends ConsumerStatefulWidget {
  const DriverOrderPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DriverOrderPage> createState() => _DriverOrderPageState();
}

class _DriverOrderPageState extends ConsumerState<DriverOrderPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // A message from the previous page would cover the action buttons.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  DriverOrder? _find() => [
    ...?ref.watch(driverActiveOrdersProvider).value,
    ...?ref.watch(driverHistoryProvider).value,
  ].where((o) => o.id == widget.orderId).firstOrNull;

  /// Runs [action]; errors are shown, success is visible on the page.
  /// Returns true when it worked.
  Future<bool> _run(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
      return false;
    } finally {
      ref.invalidate(driverActiveOrdersProvider);
      ref.invalidate(driverHistoryProvider);
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(driverCashPendingProvider);
      ref.invalidate(myDriverProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Photo sheet, then upload + delivered.
  Future<void> _deliver(DriverOrder o) async {
    final photo = await showModalBottomSheet<PickedImage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => ProofPhotoSheet(total: o.total),
    );
    if (photo == null || !mounted) return;
    final ok = await _run(
      () => ref.read(driverRepositoryProvider).completeDelivery(o.id, photo),
    );
    if (ok && mounted) context.go('/driver');
  }

  Future<bool> _confirm(String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                AppLocalizations.of(ctx).back,
                style: TextStyle(color: AppColors.body),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                action,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    ref.watch(driverLiveProvider); // live updates on this page too
    final o = _find();
    final repo = ref.read(driverRepositoryProvider);
    final loading =
        ref.watch(driverActiveOrdersProvider).isLoading &&
        !ref.watch(driverActiveOrdersProvider).hasValue;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                PageHeader(
                  title: o == null ? l.currentDelivery : l.orderNumber(o.code),
                  trailing: o == null
                      ? null
                      : Pill(
                          orderStatusLabel(l, o.status),
                          color: orderStatusColor(o.status),
                        ),
                ),
                Expanded(
                  child: o == null
                      ? Center(
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary,
                                )
                              : Text(l.noOrders),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            if (o.status == 'cancelled' ||
                                o.status == 'rejected')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DriverCard(
                                  color: AppColors.dangerSoft,
                                  child: Text(
                                    [
                                      l.cancelledByRestaurant,
                                      if ((o.rejectReason ?? '').isNotEmpty)
                                        l.rejectReasonLabel(
                                          rejectReasonText(l, o.rejectReason!),
                                        ),
                                    ].join('\n'),
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ),
                            _Stop(
                              title: l.pickupAt,
                              icon: Icons.storefront_rounded,
                              color: AppColors.primary,
                              name: o.restaurantName,
                              lines: [o.restaurantAddress, o.restaurantArea],
                              phone: o.restaurantPhone,
                              onDirections: () => openDirections(
                                context,
                                lat: o.restaurantLat,
                                lng: o.restaurantLng,
                                address:
                                    '${o.restaurantAddress} ${o.restaurantArea}',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Stop(
                              title: l.dropOffAt,
                              icon: Icons.location_on_rounded,
                              color: AppColors.danger,
                              name: o.customerName,
                              lines: [o.addressText, o.area, o.addressDetails],
                              phone: o.customerPhone,
                              notes: o.notes,
                              onDirections: () => openDirections(
                                context,
                                lat: o.lat,
                                lng: o.lng,
                                address: '${o.addressText} ${o.area}',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DriverCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final i in o.items)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        '${i.quantity}× ${i.name}',
                                        style: TextStyle(color: AppColors.ink),
                                      ),
                                    ),
                                  Divider(color: AppColors.border, height: 20),
                                  AmountLine(
                                    label: l.cashToCollect,
                                    value: formatDzd(o.total, lang),
                                    big: true,
                                  ),
                                  AmountLine(
                                    label: l.handToRestaurant,
                                    value: formatDzd(o.foodTotal, lang),
                                  ),
                                  AmountLine(
                                    label: l.yourFee,
                                    value: formatDzd(o.deliveryFee, lang),
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                if (o != null && o.isActive)
                  SheetPanel(
                    showHandle: false,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (o.status == 'accepted')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              l.waitRestaurant,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.body),
                            ),
                          ),
                        if (o.status == 'ready')
                          AppButton(
                            label: l.markPickedUp,
                            loading: _busy,
                            onPressed: () =>
                                _run(() => repo.setStatus(o.id, 'picked_up')),
                          ),
                        if (o.status == 'picked_up')
                          AppButton(
                            label: l.markDelivered,
                            loading: _busy,
                            onPressed: () => _deliver(o),
                          ),
                        if (o.canRelease)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    if (!await _confirm(
                                      l.releaseConfirm,
                                      l.releaseOrder,
                                    )) {
                                      return;
                                    }
                                    await _run(() => repo.release(o.id));
                                    if (context.mounted) context.go('/driver');
                                  },
                            child: Text(
                              l.releaseOrder,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.title,
    required this.icon,
    required this.color,
    required this.name,
    required this.lines,
    required this.phone,
    required this.onDirections,
    this.notes = '',
  });

  final String title;
  final IconData icon;
  final Color color;
  final String name;
  final List<String> lines;
  final String phone;
  final String notes;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          for (final x in lines.where((x) => x.trim().isNotEmpty))
            Text(x, style: TextStyle(color: AppColors.body)),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“$notes”',
              style: TextStyle(
                color: AppColors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (phone.isNotEmpty)
                AppButton(
                  label: l.callAction,
                  icon: Icons.call_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: () => callNumber(context, phone),
                ),
              AppButton(
                label: l.directions,
                icon: Icons.directions_rounded,
                variant: AppButtonVariant.small,
                onPressed: onDirections,
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              phone,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Delivered & paid": take the proof photo, see it, confirm with the cash
/// amount. Pops the photo, or null when cancelled.
class ProofPhotoSheet extends ConsumerStatefulWidget {
  const ProofPhotoSheet({super.key, required this.total});
  final int total;

  @override
  ConsumerState<ProofPhotoSheet> createState() => _ProofPhotoSheetState();
}

class _ProofPhotoSheetState extends ConsumerState<ProofPhotoSheet> {
  PickedImage? _photo;
  bool _opening = false;

  Future<void> _take({bool camera = true}) async {
    final l = AppLocalizations.of(context);
    setState(() => _opening = true);
    try {
      final p = await ref.read(takeProofPhotoProvider)(camera: camera);
      if (p != null && mounted) setState(() => _photo = p);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (e) {
      // Most often: camera permission refused, or no camera (computer).
      if (mounted) showAppSnack(context, l.errCamera, error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final photo = _photo;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.proofTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l.proofHint, style: TextStyle(color: AppColors.body)),
            const SizedBox(height: 16),
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.memory(
                  photo.bytes,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Material(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: _opening ? null : _take,
                  child: SizedBox(
                    height: 160,
                    child: Center(
                      child: _opening
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.takePhoto,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (photo != null)
                  TextButton.icon(
                    onPressed: _opening ? null : _take,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.retakePhoto),
                  ),
                // Fallback when the camera can't open (permission refused,
                // computer without camera): pick a photo instead.
                TextButton.icon(
                  onPressed: _opening ? null : () => _take(camera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l.chooseFromGallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.confirmDelivered(formatDzd(widget.total, lang)),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: l.markDelivered,
              onPressed: photo == null
                  ? null
                  : () => Navigator.of(context).pop(photo),
            ),
          ],
        ),
      ),
    );
  }
}
