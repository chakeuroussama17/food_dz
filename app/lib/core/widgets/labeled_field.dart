import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Uppercase label + grey filled input ("EMAIL", "ADDRESS", "STREET").
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.textInputAction,
    this.optionalLabel,
    this.textDirection,
    this.autofillHints,
    this.onSubmitted,
    this.enabled = true,
  });

  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction? textInputAction;

  /// e.g. "optional", shown muted next to the label.
  final String? optionalLabel;

  /// Force LTR for phone numbers / emails inside an RTL layout.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label.toUpperCase()),
              if (optionalLabel != null)
                TextSpan(
                  text: '  ($optionalLabel)',
                  style: const TextStyle(color: AppColors.muted),
                ),
            ],
          ),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpace.sm),
        _withDirection(
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            textInputAction: textInputAction,
            textDirection: textDirection,
            autofillHints: autofillHints,
            onFieldSubmitted: onSubmitted,
            enabled: enabled,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      color: AppColors.inkSoft.withValues(alpha: .7),
                    ),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  /// Phone numbers and emails read left-to-right even in Arabic; wrapping
  /// the whole field (not just the input) keeps the placeholder in order.
  Widget _withDirection(Widget field) => textDirection == null
      ? field
      : Directionality(textDirection: textDirection!, child: field);
}
