import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pdf/pdf_output.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../admin/statement_pdf.dart' show PdfFonts;
import '../restaurant_owner/data/owner_repository.dart';
import '../catalog/widgets/browse_widgets.dart' show AsyncBody;
import 'qr_card.dart';
import 'qr_pdf.dart';
import 'qr_repository.dart';

/// The restaurant's QR code with its actions (poster PDF, print, copy the
/// link) and how many people scanned it. Used by the restaurant app, the
/// partner portal and the admin.
class RestaurantQrPanel extends ConsumerStatefulWidget {
  const RestaurantQrPanel({
    super.key,
    required this.restaurantId,
    required this.slug,
    required this.name,
    this.wide = false,
  });

  final String restaurantId;
  final String slug;
  final String name;

  /// Card and the rest side by side (portal dialog, wide screens).
  final bool wide;

  @override
  ConsumerState<RestaurantQrPanel> createState() => _RestaurantQrPanelState();
}

class _RestaurantQrPanelState extends ConsumerState<RestaurantQrPanel> {
  bool _busy = false;

  Future<void> _poster(String link, {required bool print}) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await buildQrPosterPdf(
        name: widget.name,
        link: link,
        fonts: await PdfFonts.fromAssets(),
      );
      final out = ref.read(pdfOutputProvider);
      final file = 'QR-${widget.slug}';
      if (print) {
        await out.print(bytes, file);
      } else {
        await out.download(bytes, '$file.pdf');
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final base =
        ref.watch(publicBaseUrlProvider).value ?? kDefaultPublicBaseUrl;
    final link = restaurantQrLink(base, widget.slug);
    final card = Center(
      child: RestaurantQrCard(
        link: link,
        name: widget.name,
        caption: l.qrScanToOrder,
        size: widget.wide ? 230 : 210,
      ),
    );
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l.qrDownloadPoster,
          icon: Icons.download_rounded,
          loading: _busy,
          onPressed: () => _poster(link, print: false),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _poster(link, print: true),
                icon: const Icon(Icons.print_outlined),
                label: Text(l.printAction),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: link.split('?').first),
                  );
                  if (context.mounted) showAppSnack(context, l.copied);
                },
                icon: const Icon(Icons.link_rounded),
                label: Text(l.qrCopyLink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Stats(restaurantId: widget.restaurantId),
        const SizedBox(height: 16),
        _Tip(text: l.qrTip),
      ],
    );
    if (widget.wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          card,
          const SizedBox(width: 28),
          Expanded(child: actions),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [card, const SizedBox(height: 24), actions],
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(qrStatsProvider(restaurantId)).value ?? const QrStats();
    Widget tile(String value, String label, IconData icon) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              label,
              maxLines: 3,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.qrStatsTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile('${s.last30}', l.qrScans30, Icons.qr_code_scanner_rounded),
              const SizedBox(width: 10),
              tile('${s.people}', l.qrPeople, Icons.people_outline_rounded),
              const SizedBox(width: 10),
              tile(
                '${s.ordersAfter}',
                l.qrOrdersAfter,
                Icons.shopping_bag_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.qrScansTotal(s.total, s.app, s.web),
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lightbulb_outline_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.body),
          ),
        ),
      ],
    ),
  );
}

/// Restaurant app: /restaurant/qr, for the selected restaurant.
class OwnerQrPage extends ConsumerWidget {
  const OwnerQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mine = ref.watch(myRestaurantProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                PageHeader(title: l.qrTitle),
                Expanded(
                  child: AsyncBody(
                    value: mine,
                    onRetry: () => ref.invalidate(myRestaurantProvider),
                    builder: (r) => r == null
                        ? const SizedBox.shrink()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            children: [
                              RestaurantQrPanel(
                                restaurantId: r.id,
                                slug: r.slug,
                                name: r.name,
                              ),
                            ],
                          ),
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

/// Portal and admin: the QR code in a dialog.
Future<void> showRestaurantQrDialog(
  BuildContext context, {
  required String restaurantId,
  required String slug,
  required String name,
}) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final wide = MediaQuery.sizeOf(ctx).width >= 760;
      return Dialog(
        backgroundColor: AppColors.canvas,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 760 : 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.qrTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RestaurantQrPanel(
                  restaurantId: restaurantId,
                  slug: slug,
                  name: name,
                  wide: wide,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
