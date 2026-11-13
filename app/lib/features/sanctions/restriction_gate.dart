import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../core/pdf/business_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../l10n/app_localizations.dart';
import '../auth/data/auth_providers.dart';
import 'sanctions_repository.dart';

String sanctionReasonLabel(AppLocalizations l, String reason) =>
    switch (reason) {
      'fake_orders' => l.sanctionFakeOrders,
      'no_show' => l.sanctionNoShow,
      'refused_to_pay' => l.sanctionRefusedToPay,
      'abuse' => l.sanctionAbuse,
      'fraud' => l.sanctionFraud,
      'too_many_cancellations' => l.sanctionTooManyCancellations,
      'unsafe_driving' => l.sanctionUnsafeDriving,
      'cash_not_returned' => l.sanctionCashNotReturned,
      _ => l.sanctionOther,
    };

/// Wraps the whole app. A suspended or banned person only sees why and
/// until when (with "contact us" and "log out"); a new warning is shown
/// once over the app. Checked at start, when the app comes back to the
/// front, and every few minutes.
class RestrictionGate extends ConsumerStatefulWidget {
  const RestrictionGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RestrictionGate> createState() => _RestrictionGateState();
}

class _RestrictionGateState extends ConsumerState<RestrictionGate> {
  late final AppLifecycleListener _life;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onResume: () => ref.invalidate(myRestrictionProvider),
    );
    _timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => ref.invalidate(myRestrictionProvider),
    );
  }

  @override
  void dispose() {
    _life.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(myRestrictionProvider).value;
    if (s == null) return widget.child;
    if (!s.isWarning) {
      // The app stays mounted underneath (nothing lost when it ends).
      return Stack(
        children: [
          Offstage(child: widget.child),
          RestrictedScreen(sanction: s),
        ],
      );
    }
    return Stack(
      children: [
        widget.child,
        _WarningOverlay(sanction: s),
      ],
    );
  }
}

class RestrictedScreen extends ConsumerWidget {
  const RestrictedScreen({super.key, required this.sanction});
  final Sanction sanction;

  Future<void> _contact(BuildContext context, WidgetRef ref) async {
    try {
      final b = await ref.read(businessInfoRepositoryProvider).get();
      final phone = b.businessPhone.trim();
      if (phone.isNotEmpty) {
        await launchUrl(Uri(scheme: 'tel', path: phone));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = sanction;
    final lang = Localizations.localeOf(context).languageCode;
    final until = s.endsAt == null
        ? null
        : DateFormat('d MMMM yyyy · HH:mm', lang).format(s.endsAt!);
    return Scaffold(
      key: const Key('restricted'),
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(28),
              children: [
                const Center(child: BrandLogo(width: 160, stacked: false)),
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.isBan ? Icons.block_rounded : Icons.lock_clock_rounded,
                      size: 44,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  s.isBan ? l.accountBannedTitle : l.accountSuspendedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.isBan
                      ? l.accountBannedBody
                      : l.accountSuspendedUntil(until ?? ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.body,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.sanctionReasonTitle.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sanctionReasonLabel(l, s.reason),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (s.message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          s.message,
                          style: TextStyle(height: 1.45, color: AppColors.body),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _contact(context, ref),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(l.contactSupport),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => signOutAndStopPush(ref),
                  child: Text(l.logOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningOverlay extends ConsumerWidget {
  const _WarningOverlay({required this.sanction});
  final Sanction sanction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = sanction;
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            key: const Key('warning'),
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 52,
                  color: Color(0xFFE8A317),
                ),
                const SizedBox(height: 12),
                Text(
                  l.warningTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sanctionReasonLabel(l, s.reason),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                if (s.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.45, color: AppColors.body),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  l.warningBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    await ref
                        .read(sanctionsRepositoryProvider)
                        .acknowledge(s.id);
                    ref.invalidate(myRestrictionProvider);
                  },
                  child: Text(l.understood),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
