import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/ratings/ratings_repository.dart';
import '../../features/ratings/ratings_widgets.dart';
import '../../features/restaurant_owner/data/owner_orders_repository.dart'
    show ReportRange;
import '../../features/restaurant_owner/insights/insights.dart'
    show percentChange;
import '../../features/restaurant_owner/widgets/period_chips.dart'
    show SmallChips;
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

enum _Span { d7, d30, d90, year }

int _days(_Span s) => switch (s) {
  _Span.d7 => 7,
  _Span.d30 => 30,
  _Span.d90 => 90,
  _Span.year => 365,
};

double? _average(Iterable<OwnerReview> r) =>
    r.isEmpty ? null : r.fold<int>(0, (s, x) => s + x.stars) / r.length;

/// Ratings and reviews: average and trend, distribution, the complaints
/// customers mention most, and every review with reply and report buttons.
class PortalReviewsPage extends ConsumerStatefulWidget {
  const PortalReviewsPage({super.key});

  @override
  ConsumerState<PortalReviewsPage> createState() => _PortalReviewsPageState();
}

class _PortalReviewsPageState extends ConsumerState<PortalReviewsPage> {
  _Span _span = _Span.d30;
  int? _stars; // null = all
  bool _unreplied = false;
  int _shown = 20;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ids = ref.watch(portalOutletIdsProvider).value;
    final outlets = ref.watch(portalOutletsProvider).value ?? const [];
    final days = _days(_span);
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day - (days - 1));
    final to = DateTime(today.year, today.month, today.day + 1);
    final range = ReportRange(
      DateTime(from.year, from.month, from.day - days),
      to,
      outlets: ids,
    );
    final data = ids == null
        ? const AsyncLoading<List<OwnerReview>>()
        : ref.watch(portalReviewsProvider(range));

    return PortalPage(
      title: l.navReviews,
      subtitle: l.reviewsSubtitle,
      actions: [
        Segmented<_Span>(
          items: _Span.values,
          selected: _span,
          labelOf: (s) => switch (s) {
            _Span.d7 => l.range7,
            _Span.d30 => l.range30,
            _Span.d90 => l.range90,
            _Span.year => '365 ${l.rangeDaysSuffix}',
          },
          onSelected: (s) => setState(() {
            _span = s;
            _shown = 20;
          }),
        ),
        const OutletSelector(),
      ],
      children: [
        data.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(64),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(portalReviewsProvider(range)),
              child: Text(l.retry),
            ),
          ),
          data: (all) {
            final now = all.where((r) => !r.ratedAt.isBefore(from)).toList();
            final before = all.where((r) => r.ratedAt.isBefore(from)).toList();
            final shown = now.where((r) {
              if (_stars != null && r.stars != _stars) return false;
              if (_unreplied && (r.reply ?? '').isNotEmpty) return false;
              return true;
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(now: now, before: before),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SmallChips<int?>(
                        items: const [null, 5, 4, 3, 2, 1],
                        selected: _stars,
                        labelOf: (s) =>
                            s == null ? l.filterAll : l.starsFilter(s),
                        onSelected: (s) => setState(() {
                          _stars = s;
                          _shown = 20;
                        }),
                      ),
                    ),
                    FilterChip(
                      label: Text(l.filterNeedsReply),
                      selected: _unreplied,
                      selectedColor: AppColors.primarySoft,
                      onSelected: (v) => setState(() {
                        _unreplied = v;
                        _shown = 20;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (shown.isEmpty)
                  PCard(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        l.noReviewsPeriod,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  for (final r in shown.take(_shown))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(
                        review: r,
                        showOutlet: outlets.length > 1,
                        onChanged: () =>
                            ref.invalidate(portalReviewsProvider(range)),
                      ),
                    ),
                if (shown.length > _shown)
                  Center(
                    child: AppButton(
                      label: '${l.seeAll} (${shown.length - _shown})',
                      variant: AppButtonVariant.outline,
                      onPressed: () => setState(() => _shown += 20),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.now, required this.before});
  final List<OwnerReview> now;
  final List<OwnerReview> before;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final avg = _average(now);
    final prev = _average(before);
    final change = avg == null || prev == null
        ? null
        : percentChange(avg, prev);
    final counts = [
      for (var s = 5; s >= 1; s--) now.where((r) => r.stars == s).length,
    ];
    final top = <String, int>{};
    for (final r in now) {
      for (final reason in r.reasons) {
        top[reason] = (top[reason] ?? 0) + 1;
      }
    }
    final complaints = top.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxComplaint = complaints.isEmpty ? 1 : complaints.first.value;

    return ResponsiveRow(
      children: [
        PCard(
          title: l.averageRating,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avg == null ? '—' : avg.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (change != null && change.round() != 0) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ChangeChip(change: change),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stars(avg ?? 0, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    l.ratingsCount(now.length),
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              child: Text(
                                '${5 - i}',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: starColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: now.isEmpty
                                      ? 0
                                      : counts[i] / now.length,
                                  minHeight: 8,
                                  color: starColor,
                                  backgroundColor: AppColors.field,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${counts[i]}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.body,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PCard(
          title: l.topComplaints,
          child: complaints.isEmpty
              ? Text('—', style: TextStyle(color: AppColors.muted))
              : Column(
                  children: [
                    for (final e in complaints.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reasonText(l, e.key),
                                    style: TextStyle(color: AppColors.ink),
                                  ),
                                ),
                                Text(
                                  '${e.value}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.value / maxComplaint,
                                minHeight: 8,
                                color: AppColors.danger,
                                backgroundColor: AppColors.field,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.review,
    required this.showOutlet,
    required this.onChanged,
  });

  final OwnerReview review;
  final bool showOutlet;
  final VoidCallback onChanged;

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _TextDialog(reply: true),
    );
    if (text == null) return;
    try {
      await ref.read(ratingsRepositoryProvider).reply(review.orderId, text);
      if (context.mounted) showAppSnack(context, l.replyPublished);
    } on RatingError catch (e) {
      if (context.mounted) {
        showAppSnack(context, ratingErrorText(l, e.failure), error: true);
      }
    }
    onChanged();
  }

  Future<void> _flag(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _TextDialog(reply: false),
    );
    if (text == null) return;
    try {
      await ref.read(ratingsRepositoryProvider).flag(review.orderId, text);
      if (context.mounted) showAppSnack(context, l.flagSent);
    } on RatingError catch (e) {
      if (context.mounted) {
        showAppSnack(context, ratingErrorText(l, e.failure), error: true);
      }
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = review;
    final date = DateFormat.yMMMd(lang);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Stars(r.stars.toDouble(), size: 20),
                Text(
                  r.customerLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  date.format(r.ratedAt),
                  style: TextStyle(color: AppColors.muted),
                ),
                if (showOutlet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.restaurantName,
                      style: TextStyle(fontSize: 12.5, color: AppColors.body),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l.reviewOrderRef(r.code)} · ${r.items} · ${formatDzd(r.total, lang)}',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (r.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final x in r.reasons)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.field,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        reasonText(l, x),
                        style: TextStyle(fontSize: 12.5, color: AppColors.body),
                      ),
                    ),
                ],
              ),
            ],
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                r.comment,
                style: TextStyle(height: 1.45, color: AppColors.inkSoft),
              ),
            ],
            const SizedBox(height: 10),
            if ((r.reply ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.restaurantReply,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(r.reply!, style: TextStyle(color: AppColors.body)),
                  ],
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: l.replyAction,
                  icon: Icons.reply_rounded,
                  variant: AppButtonVariant.small,
                  onPressed: () => _reply(context, ref),
                ),
              ),
            const SizedBox(height: 6),
            if (r.flagPending)
              Text(
                l.flagWaiting,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (r.flagged)
              Text(
                l.flagKept,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _flag(context, ref),
                  icon: Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  label: Text(
                    l.flagReview,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Text box for a reply (1 to 300) or the reason of a report (3 to 200).
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.reply});
  final bool reply;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = _c.text.trim();
    final ok = widget.reply ? text.isNotEmpty : text.length >= 3;
    return AlertDialog(
      title: Text(widget.reply ? l.replyAction : l.flagReview),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reply ? l.replyDialogHint : l.flagReviewHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              maxLines: 4,
              maxLength: widget.reply ? 300 : 200,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.reply ? l.replyHint : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        AppButton(
          label: widget.reply ? l.sendReply : l.flagSend,
          variant: AppButtonVariant.small,
          onPressed: ok ? () => Navigator.pop(context, text) : null,
        ),
      ],
    );
  }
}
