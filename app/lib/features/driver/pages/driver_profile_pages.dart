import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/push/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/pick_image.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/theme_switch.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/data/account_repository.dart';
import '../../account/widgets/account_widgets.dart';
import '../../auth/data/auth_providers.dart';
import '../../ratings/ratings_repository.dart';
import '../../ratings/ratings_widgets.dart';
import '../data/driver_repository.dart';
import '../data/rider_levels.dart';
import '../widgets/driver_widgets.dart';
import '../widgets/rider_ui.dart';

/// The app's version ("0.3.0"), empty when unknown.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return '';
  }
});

/// Colour of each level (ring, medal, bar).
Color levelColor(RiderLevel v) => switch (v) {
  RiderLevel.rookie => const Color(0xFF8E9AAF),
  RiderLevel.pro => AppColors.primary,
  RiderLevel.expert => const Color(0xFF7C6FD6),
  RiderLevel.legend => const Color(0xFFF5B301),
};

/// The rider's profile: who I am, my level, my numbers, my rating, then
/// settings and the account.
class DriverAccountPage extends ConsumerWidget {
  const DriverAccountPage({super.key});

  Future<void> _logOut(WidgetRef ref) async {
    // Going offline first so no order waits for us.
    try {
      await ref.read(driverRepositoryProvider).setOnline(false);
    } catch (_) {}
    await signOutAndStopPush(ref);
  }

  /// Confirm, then delete. The server refuses while a delivery runs or
  /// food money is still owed to a restaurant (clear message).
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.riderDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.back, style: TextStyle(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.deleteAccount,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(driverRepositoryProvider).deleteAccount();
      try {
        await ref.read(pushServiceProvider).stop();
      } catch (_) {
        // The login is gone anyway.
      }
      if (context.mounted) showAppSnack(context, l.accountDeleted);
      await ref.read(authRepositoryProvider).signOut();
    } on DriverError catch (e) {
      if (context.mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(myDriverProvider).value;
    final stats = ref.watch(driverStatsProvider).value ?? const DriverStats();
    final version = ref.watch(appVersionProvider).value ?? '';
    return DriverScaffold(
      tab: DriverTab.account,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myDriverProvider);
          ref.invalidate(driverStatsProvider);
          ref.invalidate(driverRatingProvider);
          ref.invalidate(profileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            if (d != null) _HeroCard(driver: d, stats: stats),
            const SizedBox(height: 16),
            _NumbersRow(stats: stats),
            const SizedBox(height: 16),
            _RatingSummaryCard(stats: stats),
            const SizedBox(height: 24),
            _Section(l.yourAccount),
            _Tile(
              icon: Icons.manage_accounts_rounded,
              color: AppColors.primary,
              title: l.riderEditProfile,
              subtitle: l.riderEditHint,
              onTap: () => context.push('/driver/account/edit'),
            ),
            const SizedBox(height: 24),
            _Section(l.sectionPreferences),
            RiderCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF2AA9E1),
                    label: l.language,
                    trailing: const LanguageSwitch(),
                  ),
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF7C6FD6),
                    label: l.appearance,
                    trailing: const ThemeSwitch(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Same as the customer account: log out, delete, version.
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => _logOut(ref),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.field,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: Text(
                  l.logOut,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _delete(context, ref),
                child: Text(
                  l.deleteAccount,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
            if (version.isNotEmpty)
              Center(
                child: Text(
                  '${l.appVersion} $version',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dark card: photo with the level ring, name, vehicle, level progress.
class _HeroCard extends ConsumerStatefulWidget {
  const _HeroCard({required this.driver, required this.stats});
  final DriverProfile driver;
  final DriverStats stats;

  @override
  ConsumerState<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<_HeroCard> {
  bool _uploading = false;

  Future<void> _photo() async {
    final l = AppLocalizations.of(context);
    try {
      final p = await ref.read(pickRiderPhotoProvider)();
      if (p == null) return;
      setState(() => _uploading = true);
      await ref
          .read(accountRepositoryProvider)
          .uploadAvatar(p.bytes, p.extension);
      ref.invalidate(profileProvider);
    } on ImageTooLarge {
      if (mounted) showAppSnack(context, l.errPhotoTooLarge, error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final d = widget.driver;
    final s = widget.stats;
    final avatar = ref.watch(profileProvider).value?.avatarUrl;
    final level = RiderLevel.of(s);
    final next = level.next;
    final color = levelColor(level);
    final name = d.fullName.isEmpty ? l.driverSection : d.fullName;

    final String hint;
    if (next == null) {
      hint = l.levelTop;
    } else if (s.deliveries < next.deliveries) {
      hint = l.levelNext(next.deliveries - s.deliveries, next.label(l));
    } else {
      hint = l.levelNeedsRating(
        next.minRating!.toStringAsFixed(1),
        next.label(l),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2238), AppColors.night],
        ),
        boxShadow: riderShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo inside the level ring, with a camera badge.
              GestureDetector(
                onTap: _uploading ? null : _photo,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                      child: ClipOval(
                        child: SizedBox.square(
                          dimension: 76,
                          child: avatar == null
                              ? Container(
                                  color: const Color(0xFF2E3350),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : AppImage(
                                  url: avatar,
                                  width: 76,
                                  height: 76,
                                  radius: 38,
                                ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: -2,
                      bottom: -2,
                      child: Semantics(
                        button: true,
                        label: l.changePhoto,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.night,
                              width: 2,
                            ),
                          ),
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (d.isApproved) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: l.driverApproved,
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF4FC3F7),
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          icon: vehicleIcon(d.vehicle),
                          text: vehicleLabel(l, d.vehicle),
                        ),
                        _Chip(
                          icon: Icons.call_rounded,
                          text: d.phone,
                          ltr: true,
                        ),
                        if (!d.isApproved)
                          _Chip(
                            icon: Icons.hourglass_top_rounded,
                            text: l.driverPendingTitle,
                          ),
                      ],
                    ),
                    if (s.memberSince != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.riderSince(
                          DateFormat.yMMMM(lang).format(s.memberSince!),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFB4B9CC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: color, size: 22),
              const SizedBox(width: 6),
              Text(
                l.levelLabel(level.label(l)),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (next != null)
                Text(
                  next.label(l),
                  style: TextStyle(
                    color: levelColor(next),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level.progress(s),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: .12),
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFFD5D8E4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.ltr = false});
  final IconData icon;
  final String text;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          textDirection: ltr ? TextDirection.ltr : null,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    ),
  );
}

/// Deliveries · earned · rating.
class _NumbersRow extends StatelessWidget {
  const _NumbersRow({required this.stats});
  final DriverStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Widget tile(
      IconData icon,
      Color c,
      String value,
      String label, {
      VoidCallback? onTap,
    }) => Expanded(
      child: RiderCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.body),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(
          Icons.check_circle_rounded,
          AppColors.success,
          '${stats.deliveries}',
          l.statTotalDeliveries,
        ),
        const SizedBox(width: 10),
        tile(
          Icons.payments_rounded,
          AppColors.primary,
          formatDzd(stats.earned, lang),
          l.statTotalEarned,
        ),
        const SizedBox(width: 10),
        tile(
          Icons.star_rounded,
          starColor,
          stats.average?.toStringAsFixed(1) ?? l.newRestaurant,
          l.statRating,
          onTap: () => context.push('/driver/account/rating'),
        ),
      ],
    );
  }
}

/// Average, the 5 bars, the 5-star run, "See details".
class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.stats});
  final DriverStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = stats;
    return RiderCard(
      onTap: () => context.push('/driver/account/rating'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.myRating,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                l.ratingDetails,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 112,
                child: Column(
                  children: [
                    Text(
                      s.average?.toStringAsFixed(1) ?? '–',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Stars(s.average ?? 0, size: 14),
                    const SizedBox(height: 4),
                    Text(
                      s.average == null
                          ? l.driverRatingHint
                          : l.ratingsCount(s.count),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StarBars(stars: s.stars, count: s.count),
              ),
            ],
          ),
          if (s.fiveStarStreak >= 2) ...[
            const SizedBox(height: 14),
            _StreakChip(n: s.fiveStarStreak),
          ],
        ],
      ),
    );
  }
}

/// "5 ★ ████████ 34" … "1 ★ ▏ 1".
class StarBars extends StatelessWidget {
  const StarBars({super.key, required this.stars, required this.count});
  final Map<int, int> stars;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var k = 5; k >= 1; k--)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text(
                  '$k',
                  style: TextStyle(fontSize: 12, color: AppColors.body),
                ),
              ),
              const Icon(Icons.star_rounded, size: 12, color: starColor),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count == 0 ? 0 : (stars[k] ?? 0) / count,
                    minHeight: 7,
                    backgroundColor: AppColors.field,
                    color: k >= 4
                        ? AppColors.success
                        : k == 3
                        ? starColor
                        : AppColors.danger,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${stars[k] ?? 0}',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: AppColors.body),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: .16),
          AppColors.accent.withValues(alpha: .08),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).fiveStarStreak(n),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: .8,
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RiderCard(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color == AppColors.danger
                      ? AppColors.danger
                      : AppColors.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    ),
  );
}

/// My rating in detail: average, 30 days vs all time, stars, the 5-star
/// run, what customers mentioned, and tips.
class DriverRatingPage extends ConsumerWidget {
  const DriverRatingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(driverStatsProvider).value ?? const DriverStats();
    final reasons =
        (ref.watch(driverRatingProvider).value?.reasons ?? const {}).entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxReason = reasons.isEmpty ? 1 : reasons.first.value;

    String coach(String key) => switch (key) {
      'late' => l.coachLate,
      'rude' => l.coachRude,
      'careless' => l.coachCareless,
      'no_contact' => l.coachNoContact,
      'wrong_place' => l.coachWrongPlace,
      _ => l.coachAllGood,
    };

    final trendUp =
        s.average != null && s.average30d != null && s.average30d! > s.average!;
    final trendDown =
        s.average != null && s.average30d != null && s.average30d! < s.average!;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                PageHeader(title: l.myRating),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      RiderCard(
                        child: Column(
                          children: [
                            Text(
                              s.average?.toStringAsFixed(1) ?? '–',
                              style: TextStyle(
                                fontSize: 56,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Stars(s.average ?? 0, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              s.average == null
                                  ? l.driverRatingHint
                                  : l.ratingsCount(s.count),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 16),
                            StarBars(stars: s.stars, count: s.count),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Compare(
                              label: l.avg30d,
                              value: s.average30d,
                              count: s.count30d,
                              icon: trendUp
                                  ? Icons.trending_up_rounded
                                  : trendDown
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_flat_rounded,
                              iconColor: trendUp
                                  ? AppColors.success
                                  : trendDown
                                  ? AppColors.danger
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Compare(
                              label: l.allTime,
                              value: s.average,
                              count: s.count,
                              icon: Icons.history_rounded,
                              iconColor: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      if (s.fiveStarStreak >= 2) ...[
                        const SizedBox(height: 14),
                        _StreakChip(n: s.fiveStarStreak),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        l.driverReasonsTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RiderCard(
                        child: reasons.isEmpty
                            ? Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l.coachAllGood,
                                      style: TextStyle(color: AppColors.ink),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  for (final e in reasons)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 130,
                                            child: Text(
                                              reasonText(l, e.key),
                                              style: TextStyle(
                                                color: AppColors.ink,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: e.value / maxReason,
                                                minHeight: 8,
                                                backgroundColor:
                                                    AppColors.field,
                                                color: AppColors.danger
                                                    .withValues(alpha: .75),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${e.value}',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                color: AppColors.body,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text(
                          l.coachTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final e in reasons.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: RiderCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_rounded,
                                    color: starColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reasonText(l, e.key),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          coach(e.key),
                                          style: TextStyle(
                                            color: AppColors.body,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.ratingPrivateNote,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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

class _Compare extends StatelessWidget {
  const _Compare({
    required this.label,
    required this.value,
    required this.count,
    required this.icon,
    required this.iconColor,
  });
  final String label;
  final double? value;
  final int count;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return RiderCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: AppColors.body, fontSize: 13),
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value?.toStringAsFixed(1) ?? '–',
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, color: starColor, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.ratingsCount(count),
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Edit name, phone, vehicle and photo.
class DriverEditProfilePage extends ConsumerStatefulWidget {
  const DriverEditProfilePage({super.key});

  @override
  ConsumerState<DriverEditProfilePage> createState() =>
      _DriverEditProfilePageState();
}

class _DriverEditProfilePageState extends ConsumerState<DriverEditProfilePage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  Vehicle? _vehicle;
  bool _saving = false;
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(driverRepositoryProvider)
          .updateProfile(
            fullName: _name.text,
            phone: _phone.text,
            vehicle: _vehicle!,
          );
      ref.invalidate(myDriverProvider);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      showAppSnack(context, l.saved);
      if (context.canPop()) context.pop();
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(myDriverProvider).value;
    if (d != null && !_filled) {
      _filled = true;
      _name.text = d.fullName;
      _phone.text = d.phone;
      _vehicle = d.vehicle;
    }
    InputDecoration deco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                PageHeader(title: l.riderEditProfile),
                Expanded(
                  child: d == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            _HeroCard(
                              driver: d,
                              stats:
                                  ref.watch(driverStatsProvider).value ??
                                  const DriverStats(),
                            ),
                            const SizedBox(height: 20),
                            RiderCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: deco(
                                      l.fullName,
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    textDirection: TextDirection.ltr,
                                    decoration: deco(
                                      l.driverPhone,
                                      Icons.call_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    l.vehicle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      for (final v in Vehicle.values) ...[
                                        if (v != Vehicle.values.first)
                                          const SizedBox(width: 10),
                                        Expanded(
                                          child: _VehicleCard(
                                            vehicle: v,
                                            selected: _vehicle == v,
                                            onTap: () =>
                                                setState(() => _vehicle = v),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            RiderButton(
                              label: l.saveChanges,
                              icon: Icons.check_rounded,
                              loading: _saving,
                              onPressed: _save,
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.field,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                vehicleIcon(vehicle),
                size: 30,
                color: selected ? AppColors.primary : AppColors.body,
              ),
              const SizedBox(height: 6),
              Text(
                vehicleLabel(l, vehicle),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.primary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
