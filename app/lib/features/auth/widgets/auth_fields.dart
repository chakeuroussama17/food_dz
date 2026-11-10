import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../l10n/app_localizations.dart';

/// Password field with the eye / eye-off toggle from Log In and Sign Up.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.newPassword = false,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Hints the password manager to suggest a new password.
  final bool newPassword;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LabeledField(
      label: widget.label,
      controller: widget.controller,
      hint: '• • • • • • • • • •',
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      textDirection: TextDirection.ltr,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      suffix: IconButton(
        tooltip: _obscure ? l.showPassword : l.hidePassword,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.muted,
          size: 20,
        ),
      ),
    );
  }
}

/// 20px rounded-square checkbox + grey label ("Remember me").
class RememberCheckbox extends StatelessWidget {
  const RememberCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value ? AppColors.primary : AppColors.checkboxBorder,
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppColors.subtle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account?  SIGN UP" row.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: TextStyle(fontSize: 16, color: AppColors.body)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Text(
            action.toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// One-time code input drawn as separate grey boxes (Verification screen).
/// Backed by a single hidden text field so paste and SMS/email autofill work.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  void _onChanged() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    // Codes are always typed left-to-right, even in Arabic.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(
          children: [
            // Hidden real input.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 62,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    filled: false,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _box(i, value)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i, String value) {
    final active =
        _focus.hasFocus &&
        (i == value.length ||
            (i == widget.length - 1 && value.length == widget.length));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.hasError
              ? AppColors.danger
              : active
              ? AppColors.primary
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Text(
        i < value.length ? value[i] : '',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}
