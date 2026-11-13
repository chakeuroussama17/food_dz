import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'restriction_gate.dart' show sanctionReasonLabel;
import 'sanctions_repository.dart';

String sanctionKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'warning' => l.sanctionWarning,
  'suspension' => l.sanctionSuspension,
  _ => l.sanctionBan,
};

Color sanctionColor(String kind) => switch (kind) {
  'warning' => const Color(0xFFE8A317),
  'suspension' => AppColors.primary,
  _ => AppColors.danger,
};

/// "Suspended" / "Banned" pill.
class RestrictionPill extends StatelessWidget {
  const RestrictionPill({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Pill(
      kind == 'ban' ? l.bannedPill : l.suspendedPill,
      color: sanctionColor(kind),
    );
  }
}

/// A person's sanctions (newest first) with "lift" on those in force, and
/// the buttons to warn, suspend or ban. For customers and riders.
class UserSanctionsSection extends ConsumerWidget {
  const UserSanctionsSection({super.key, required this.userId, this.onChanged});

  final String userId;
  final VoidCallback? onChanged;

  void _changed(WidgetRef ref) {
    ref.invalidate(sanctionHistoryProvider(userId));
    ref.invalidate(restrictionsProvider);
    ref.invalidate(watchlistProvider);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final date = DateFormat('d MMM yyyy · HH:mm', lang);
    final history = ref.watch(sanctionHistoryProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in const ['warning', 'suspension', 'ban'])
              OutlinedButton.icon(
                key: Key('sanction:$kind'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: sanctionColor(kind),
                  side: BorderSide(color: sanctionColor(kind)),
                ),
                onPressed: () async {
                  final done = await showSanctionDialog(
                    context,
                    userId: userId,
                    kind: kind,
                  );
                  if (done) _changed(ref);
                },
                icon: Icon(switch (kind) {
                  'warning' => Icons.warning_amber_rounded,
                  'suspension' => Icons.lock_clock_rounded,
                  _ => Icons.block_rounded,
                }, size: 18),
                label: Text(switch (kind) {
                  'warning' => l.warnAction,
                  'suspension' => l.suspendAction,
                  _ => l.banAction,
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l.sanctionHistory.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        switch (history) {
          AsyncData(:final value) when value.isEmpty => Text(
            l.noSanctions,
            style: TextStyle(color: AppColors.muted),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final s in value)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: s.active
                          ? sanctionColor(s.kind)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Pill(
                                  sanctionKindLabel(l, s.kind),
                                  color: sanctionColor(s.kind),
                                ),
                                Text(
                                  sanctionReasonLabel(l, s.reason),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (s.createdAt != null)
                                  date.format(s.createdAt!),
                                if (s.createdByName.isNotEmpty) s.createdByName,
                                if (s.endsAt != null)
                                  l.untilDate(date.format(s.endsAt!)),
                                if (s.liftedAt != null)
                                  l.liftedOn(date.format(s.liftedAt!)),
                                if (s.isWarning && s.seenAt != null) l.seen,
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            if (s.message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '“${s.message}”',
                                  style: TextStyle(color: AppColors.body),
                                ),
                              ),
                            if (s.adminNote.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${l.adminNoteLabel}: ${s.adminNote}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (s.active || (s.isWarning && s.liftedAt == null))
                        TextButton(
                          key: Key('lift:${s.id}'),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(sanctionsRepositoryProvider)
                                  .lift(s.id);
                              _changed(ref);
                              if (context.mounted) {
                                showAppSnack(context, l.sanctionLifted);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                showAppSnack(
                                  context,
                                  l.errGeneric,
                                  error: true,
                                );
                              }
                            }
                          },
                          child: Text(
                            s.isWarning ? l.removeAction : l.liftAction,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          AsyncError() => Text(
            l.loadError,
            style: const TextStyle(color: AppColors.danger),
          ),
          _ => const LinearProgressIndicator(color: AppColors.primary),
        },
      ],
    );
  }
}

/// Reason, message to the person, days (suspension), private note.
/// Returns true when saved.
Future<bool> showSanctionDialog(
  BuildContext context, {
  required String userId,
  required String kind,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => _SanctionDialog(userId: userId, kind: kind),
  );
  return r == true;
}

class _SanctionDialog extends ConsumerStatefulWidget {
  const _SanctionDialog({required this.userId, required this.kind});
  final String userId;
  final String kind;

  @override
  ConsumerState<_SanctionDialog> createState() => _SanctionDialogState();
}

class _SanctionDialogState extends ConsumerState<_SanctionDialog> {
  String? _reason;
  int _days = 7;
  final _message = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _message.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(sanctionsRepositoryProvider)
          .sanction(
            userId: widget.userId,
            kind: widget.kind,
            reason: _reason!,
            message: _message.text.trim(),
            days: widget.kind == 'suspension' ? _days : null,
            adminNote: _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
      if (mounted) showAppSnack(context, l.saved);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = sanctionColor(widget.kind);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(switch (widget.kind) {
        'warning' => l.warnTitle,
        'suspension' => l.suspendTitle,
        _ => l.banTitle,
      }),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('sanction-reason'),
                initialValue: _reason,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.sanctionReasonTitle),
                items: [
                  for (final r in sanctionReasons)
                    DropdownMenuItem(
                      value: r,
                      child: Text(sanctionReasonLabel(l, r)),
                    ),
                ],
                onChanged: (v) => setState(() => _reason = v),
              ),
              if (widget.kind == 'suspension') ...[
                const SizedBox(height: 16),
                Text(
                  l.suspendFor.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in const [1, 3, 7, 30])
                      ChoiceChip(
                        key: Key('days:$d'),
                        label: Text(l.daysCount(d)),
                        selected: _days == d,
                        selectedColor: color,
                        labelStyle: TextStyle(
                          color: _days == d ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _days = d),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const Key('sanction-message'),
                controller: _message,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.messageToUser,
                  hintText: l.messageToUserHint,
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 300,
                decoration: InputDecoration(labelText: l.adminNoteLabel),
              ),
              Text(
                widget.kind == 'warning'
                    ? l.warnExplain
                    : widget.kind == 'suspension'
                    ? l.suspendExplain
                    : l.banExplain,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('sanction-save'),
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: _reason == null || _saving ? null : _save,
          child: Text(switch (widget.kind) {
            'warning' => l.warnAction,
            'suspension' => l.suspendAction,
            _ => l.banAction,
          }),
        ),
      ],
    );
  }
}
