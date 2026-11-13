import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/account_repository.dart';
import 'details_fields.dart';

/// Home card shown once after sign-up: "Complete your profile" with
/// "Complete" (opens the questions) and "Later". Hidden once answered or
/// skipped.
class CompleteProfileCard extends ConsumerWidget {
  const CompleteProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(profileProvider).value;
    if (p == null || p.promptAnswered) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        key: const Key('complete-profile'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.completeProfileTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.completeProfileBody,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(accountRepositoryProvider)
                        .skipProfilePrompt();
                    ref.invalidate(profileProvider);
                  },
                  child: Text(
                    l.later,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => showCompleteProfileSheet(context, p),
                  child: Text(l.completeProfileAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCompleteProfileSheet(BuildContext context, Profile p) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _Sheet(profile: p),
    );

class _Sheet extends ConsumerStatefulWidget {
  const _Sheet({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_Sheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<_Sheet> {
  final _form = GlobalKey<FormState>();
  late DateTime? _birth = widget.profile.birthDate;
  late String? _gender = widget.profile.gender;
  late String? _referral = widget.profile.referral;
  late int? _wilaya = widget.profile.wilaya;
  late final _commune = TextEditingController(
    text: widget.profile.commune ?? '',
  );
  late final _askPlace =
      widget.profile.wilaya == null ||
      (widget.profile.commune ?? '').trim().isEmpty;
  bool _saving = false;

  @override
  void dispose() {
    _commune.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final commune = _commune.text.trim();
      await ref
          .read(accountRepositoryProvider)
          .updateDetails(
            ProfileDetails(
              birthDate: _birth,
              gender: _gender,
              referral: _referral,
              wilaya: _wilaya,
              commune: commune.isEmpty ? null : commune,
            ),
            complete: true,
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, l.thanksProfile);
    } on DetailsError catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          e.failure == DetailsFailure.invalidBirthDate
              ? l.errBirthDate
              : l.errGeneric,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              l.completeProfileTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.completeProfilePrivacy,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            BirthDateField(
              value: _birth,
              onChanged: (d) => setState(() => _birth = d),
            ),
            const SizedBox(height: 20),
            FieldLabel(l.gender),
            ChoiceChips(
              options: genderOptions(l),
              value: _gender,
              onChanged: (v) => setState(() => _gender = v),
            ),
            if (_askPlace) ...[
              const SizedBox(height: 20),
              WilayaField(
                value: _wilaya,
                required: false,
                onChanged: (v) => setState(() => _wilaya = v),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: l.commune,
                controller: _commune,
                hint: l.communeHint,
                maxLength: 80,
              ),
            ],
            const SizedBox(height: 20),
            FieldLabel(l.howDidYouHear),
            ChoiceChips(
              options: referralOptions(l),
              value: _referral,
              onChanged: (v) => setState(() => _referral = v),
            ),
            const SizedBox(height: 28),
            AppButton(label: l.save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
