import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'ratings_repository.dart';

const starColor = Color(0xFFF59E0B);

/// "Cold food", "Late delivery"... in the current language.
String reasonText(AppLocalizations l, String key) => switch (key) {
  'cold' => l.rsnCold,
  'missing_item' => l.rsnMissingItem,
  'wrong_order' => l.rsnWrongOrder,
  'small_portion' => l.rsnSmallPortion,
  'bad_taste' => l.rsnBadTaste,
  'bad_packaging' => l.rsnBadPackaging,
  'late' => l.rsnLate,
  'rude' => l.rsnRude,
  'careless' => l.rsnCareless,
  'no_contact' => l.rsnNoContact,
  'wrong_place' => l.rsnWrongPlace,
  'fake_order' => l.rsnFakeOrder,
  'no_answer' => l.rsnNoAnswer,
  'wrong_address' => l.rsnWrongAddress,
  'refused_to_pay' => l.rsnRefusedToPay,
  _ => l.rsnOther,
};

String ratingWord(AppLocalizations l, int stars) => switch (stars) {
  1 => l.ratingWord1,
  2 => l.ratingWord2,
  3 => l.ratingWord3,
  4 => l.ratingWord4,
  _ => l.ratingWord5,
};

String ratingErrorText(AppLocalizations l, RatingFailure f) => switch (f) {
  RatingFailure.windowClosed => l.errRatingClosed,
  RatingFailure.locked => l.errRatingLocked,
  RatingFailure.alreadyReplied => l.errAlreadyReplied,
  RatingFailure.alreadyFlagged => l.errAlreadyFlagged,
  RatingFailure.alreadyReported => l.errAlreadyReported,
  RatingFailure.tooManyReports => l.errTooManyReports,
  RatingFailure.customerGone => l.errCustomerGone,
  RatingFailure.network => l.errNetwork,
  _ => l.errGeneric,
};

/// Read-only stars (whole numbers, or one decimal as filled amount).
class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 16});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.ltr,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          value >= i - .25
              ? Icons.star_rounded
              : value >= i - .75
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: value >= i - .75 ? starColor : AppColors.border,
        ),
    ],
  );
}

/// "★ 4.6 (123)" or a "New" tag while there are fewer than 5 ratings.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.average,
    required this.count,
    this.size = 14,
  });

  final double? average;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (average == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l.newRestaurant,
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: starColor),
        const SizedBox(width: 3),
        Text(
          average!.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        Text(
          ' ($count)',
          style: TextStyle(fontSize: size - 1, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Five big stars to tap.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    textDirection: TextDirection.ltr,
    children: [
      for (var i = 1; i <= 5; i++)
        Semantics(
          button: true,
          label: '$i',
          child: InkResponse(
            onTap: () => onChanged(i),
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: i <= value ? 1.1 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 46,
                  color: i <= value ? starColor : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// A customer's review: stars, reasons, comment, date and the reply.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                date.format(review.ratedAt),
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stars(review.stars.toDouble()),
          if (review.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in review.reasons)
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
                      reasonText(l, r),
                      style: TextStyle(fontSize: 12, color: AppColors.body),
                    ),
                  ),
              ],
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: TextStyle(height: 1.4, color: AppColors.inkSoft),
            ),
          ],
          if ((review.reply ?? '').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
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
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(review.reply!, style: TextStyle(color: AppColors.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet to rate the food or the delivery. Returns true when sent.
Future<bool> showRatingSheet(
  BuildContext context, {
  required String orderId,
  required bool driver,
  required String subject,
  int initialStars = 0,
  List<String> initialReasons = const [],
  String initialComment = '',
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _RatingSheet(
      orderId: orderId,
      driver: driver,
      subject: subject,
      initialStars: initialStars,
      initialReasons: initialReasons,
      initialComment: initialComment,
    ),
  );
  return sent == true;
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({
    required this.orderId,
    required this.driver,
    required this.subject,
    required this.initialStars,
    required this.initialReasons,
    required this.initialComment,
  });

  final String orderId;
  final bool driver;
  final String subject;
  final int initialStars;
  final List<String> initialReasons;
  final String initialComment;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  late int _stars = widget.initialStars;
  late final Set<String> _reasons = {...widget.initialReasons};
  late final _comment = TextEditingController(text: widget.initialComment);
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(ratingsRepositoryProvider)
          .rate(
            widget.orderId,
            widget.driver ? 'driver' : 'food',
            _stars,
            reasons: _stars <= 3 ? _reasons.toList() : const [],
            comment: _comment.text.trim(),
          );
      ref.invalidate(orderRatingProvider(widget.orderId));
      ref.invalidate(myRatingsProvider);
      if (mounted) {
        showAppSnack(context, l.ratingThanks);
        Navigator.pop(context, true);
      }
    } on RatingError catch (e) {
      if (mounted) {
        showAppSnack(context, ratingErrorText(l, e.failure), error: true);
        if (e.failure == RatingFailure.locked ||
            e.failure == RatingFailure.windowClosed) {
          ref.invalidate(orderRatingProvider(widget.orderId));
          Navigator.pop(context, false);
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reasons = widget.driver ? deliveryReasons : foodReasons;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  widget.driver
                      ? Icons.delivery_dining_rounded
                      : Icons.restaurant_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.driver ? l.rateDriverTitle : l.rateFoodTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subject,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.body),
                ),
                const SizedBox(height: 18),
                StarPicker(
                  value: _stars,
                  onChanged: (v) => setState(() => _stars = v),
                ),
                SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      _stars == 0 ? '' : ratingWord(l, _stars),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                if (_stars > 0 && _stars <= 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.ratingWhatWrong,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in reasons)
                        FilterChip(
                          label: Text(reasonText(l, r)),
                          selected: _reasons.contains(r),
                          selectedColor: AppColors.primarySoft,
                          checkmarkColor: AppColors.primary,
                          onSelected: (v) => setState(
                            () => v ? _reasons.add(r) : _reasons.remove(r),
                          ),
                        ),
                    ],
                  ),
                ],
                if (_stars > 0) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _comment,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(hintText: l.ratingCommentHint),
                  ),
                ],
                const SizedBox(height: 10),
                AppButton(
                  label: l.ratingSubmit,
                  loading: _sending,
                  onPressed: _stars == 0 ? null : _send,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _sending
                      ? null
                      : () => Navigator.pop(context, false),
                  child: Text(
                    l.ratingLater,
                    style: TextStyle(color: AppColors.body),
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

/// Reason + note, then a private report to the admin. True when sent.
Future<bool> showReportCustomerDialog(
  BuildContext context,
  WidgetRef ref, {
  required String orderId,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(orderId: orderId),
  );
  if (sent == true) ref.invalidate(reportedOrdersProvider);
  return sent == true;
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  String? _reason;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(ratingsRepositoryProvider)
          .reportCustomer(widget.orderId, _reason!, note: _note.text.trim());
      if (mounted) {
        showAppSnack(context, l.reportSent);
        Navigator.pop(context, true);
      }
    } on RatingError catch (e) {
      if (mounted) {
        showAppSnack(context, ratingErrorText(l, e.failure), error: true);
        if (e.failure == RatingFailure.alreadyReported) {
          Navigator.pop(context, true);
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.reportCustomer),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.reportCustomerHint,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in reportReasons)
                      RadioListTile<String>(
                        value: r,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(reasonText(l, r)),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLines: 2,
                maxLength: 300,
                decoration: InputDecoration(hintText: l.reportNoteHint),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        AppButton(
          label: l.reportSend,
          variant: AppButtonVariant.small,
          loading: _sending,
          onPressed: _reason == null ? null : _send,
        ),
      ],
    );
  }
}

/// Small "Report this customer" link (private, admin only); greyed out once
/// this order was reported by the signed-in user.
class ReportCustomerLink extends ConsumerWidget {
  const ReportCustomerLink({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final reported = ref.watch(reportedOrdersProvider).value ?? const {};
    final done = reported.contains(orderId);
    return TextButton.icon(
      onPressed: done
          ? null
          : () => showReportCustomerDialog(context, ref, orderId: orderId),
      icon: Icon(
        Icons.flag_outlined,
        size: 18,
        color: done ? AppColors.muted : AppColors.danger,
      ),
      label: Text(
        done ? l.reportedLabel : l.reportCustomer,
        style: TextStyle(color: done ? AppColors.muted : AppColors.danger),
      ),
    );
  }
}
