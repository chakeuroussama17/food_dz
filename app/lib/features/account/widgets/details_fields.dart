import 'package:flutter/material.dart';

import '../../../core/data/wilayas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Label in the same style as LabeledField ("WILAYA").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional});
  final String text;
  final String? optional;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.toUpperCase()),
          if (optional != null)
            TextSpan(
              text: '  ($optional)',
              style: TextStyle(color: AppColors.muted),
            ),
        ],
      ),
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}

/// The 58 wilayas, "16 - Alger".
class WilayaField extends StatelessWidget {
  const WilayaField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = true,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l.wilaya),
        DropdownButtonFormField<int>(
          key: const Key('wilaya'),
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 360,
          hint: Text(
            l.chooseWilaya,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.inkSoft,
          ),
          dropdownColor: AppColors.surface,
          items: [
            for (final (code, _, _) in wilayas)
              DropdownMenuItem(
                value: code,
                child: Text(wilayaLabel(code, lang)),
              ),
          ],
          onChanged: onChanged,
          validator: (v) => required && v == null ? l.errWilaya : null,
        ),
      ],
    );
  }
}

/// A row of choice chips (gender, how they heard about us).
class ChoiceChips extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// (value, label, icon)
  final List<(String, String, IconData?)> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, label, icon) in options)
        ChoiceChip(
          key: Key('choice:$v'),
          avatar: icon == null
              ? null
              : Icon(
                  icon,
                  size: 18,
                  color: value == v ? Colors.white : AppColors.primary,
                ),
          label: Text(label),
          selected: value == v,
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.field,
          side: BorderSide.none,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: value == v ? Colors.white : AppColors.inkSoft,
          ),
          onSelected: (on) => onChanged(on ? v : null),
        ),
    ],
  );
}

List<(String, String, IconData?)> genderOptions(AppLocalizations l) => [
  ('male', l.genderMale, Icons.male_rounded),
  ('female', l.genderFemale, Icons.female_rounded),
];

List<(String, String, IconData?)> referralOptions(AppLocalizations l) => [
  ('friend', l.refFriend, Icons.people_outline_rounded),
  ('social', l.refSocial, Icons.thumb_up_alt_outlined),
  ('search', l.refSearch, Icons.search_rounded),
  ('restaurant', l.refRestaurant, Icons.storefront_outlined),
  ('ad', l.refAd, Icons.campaign_outlined),
  ('other', l.refOther, Icons.more_horiz_rounded),
];

/// Birth date: a field that opens a date picker (years first).
class BirthDateField extends StatelessWidget {
  const BirthDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final last = DateTime(now.year - 13, now.month, now.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l.birthDate),
        InkWell(
          key: const Key('birth-date'),
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(now.year - 25),
              firstDate: DateTime(now.year - 100),
              lastDate: last,
              initialDatePickerMode: DatePickerMode.year,
              helpText: l.birthDate,
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              value == null ? l.chooseDate : loc.formatMediumDate(value!),
              style: TextStyle(
                fontSize: 14,
                color: value == null ? AppColors.muted : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
