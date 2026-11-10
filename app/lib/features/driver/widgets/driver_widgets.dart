import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/driver_live.dart';
import '../data/driver_repository.dart';

enum DriverTab { home, deliveries, account }

/// Frame for driver pages: bottom bar (Home / My deliveries / Profile). It
/// is on every driver page, so it also keeps the live updates running.
class DriverScaffold extends ConsumerWidget {
  const DriverScaffold({super.key, required this.tab, required this.body});
  final DriverTab tab;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(driverLiveProvider);
    const paths = ['/driver', '/driver/deliveries', '/driver/account'];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => context.go(paths[i]),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.delivery_dining_outlined),
            selectedIcon: const Icon(
              Icons.delivery_dining,
              color: AppColors.primary,
            ),
            label: l.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(
              Icons.receipt_long,
              color: AppColors.primary,
            ),
            label: l.myDeliveries,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
            ),
            label: l.profile,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: body,
          ),
        ),
      ),
    );
  }
}

IconData vehicleIcon(Vehicle v) => switch (v) {
  Vehicle.moto => Icons.two_wheeler_rounded,
  Vehicle.car => Icons.directions_car_rounded,
  Vehicle.bike => Icons.pedal_bike_rounded,
};

String vehicleLabel(AppLocalizations l, Vehicle v) => switch (v) {
  Vehicle.moto => l.vehicleMoto,
  Vehicle.car => l.vehicleCar,
  Vehicle.bike => l.vehicleBike,
};

String driverErrorText(AppLocalizations l, DriverFailure f) => switch (f) {
  DriverFailure.alreadyTaken => l.errAlreadyTaken,
  DriverFailure.cashOverdue => l.errCashOverdue,
  DriverFailure.photoRequired => l.errPhotoRequired,
  DriverFailure.busy => l.errDriverBusy,
  DriverFailure.notOnline => l.errNotOnline,
  DriverFailure.notApproved => l.errNotApproved,
  DriverFailure.notAllowed => l.errOrderChanged,
  DriverFailure.invalidPhone => l.errPhoneInvalid,
  DriverFailure.network => l.errNetwork,
  _ => l.errGeneric,
};

/// Opens the phone dialer.
Future<void> callNumber(BuildContext context, String phone) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
  if (!ok && context.mounted) showAppSnack(context, phone);
}

/// Google Maps directions to a point, or to an address when there is none.
Future<void> openDirections(
  BuildContext context, {
  double? lat,
  double? lng,
  required String address,
}) async {
  final dest = lat != null && lng != null ? '$lat,$lng' : address;
  final url = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': dest,
  });
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showAppSnack(context, address);
}

/// White rounded card.
class DriverCard extends StatelessWidget {
  const DriverCard({super.key, required this.child, this.onTap, this.color});
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  );
}

/// "Label    value" with the value in bold.
class AmountLine extends StatelessWidget {
  const AmountLine({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.big = false,
  });
  final String label;
  final String value;

  /// Default: the main text colour.
  final Color? color;
  final bool big;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.body)),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: big ? 18 : 15,
          ),
        ),
      ],
    ),
  );
}

/// Orange banner: "Tap here to turn on the sound alert…" (browsers).
class SoundBanner extends StatelessWidget {
  const SoundBanner({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primarySoft,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: AppColors.ink, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
