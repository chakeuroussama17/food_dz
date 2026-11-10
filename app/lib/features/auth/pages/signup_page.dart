import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _retype = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _retype]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            phone: normalizeDzPhone(_phone.text),
          );
      // Signed in straight away: the router redirect takes over (/home).
      if (signedIn || !mounted) return;
      context.push(
        Uri(
          path: '/verify',
          queryParameters: {'email': _email.text.trim(), 'purpose': 'signup'},
        ).toString(),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.signUpTitle,
      subtitle: l.signUpSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: l.name,
                controller: _name,
                hint: l.namePlaceholder,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) =>
                    isValidName(v ?? '') ? null : l.errNameRequired,
              ),
              const SizedBox(height: 24),
              LabeledField(
                label: l.email,
                controller: _email,
                hint: l.emailPlaceholder,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.email],
                validator: (v) =>
                    isValidEmail(v ?? '') ? null : l.errEmailInvalid,
              ),
              const SizedBox(height: 24),
              // Mandatory: the restaurant and the driver call this number.
              LabeledField(
                label: l.phone,
                controller: _phone,
                hint: '0550 12 34 56',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.telephoneNumber],
                maxLength: 20,
                validator: (v) => normalizeDzPhone(v ?? '') == null
                    ? l.errPhoneInvalid
                    : null,
              ),
              const SizedBox(height: 24),
              PasswordField(
                label: l.password,
                controller: _password,
                newPassword: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    isValidPassword(v ?? '') ? null : l.errPasswordShort,
              ),
              const SizedBox(height: 24),
              PasswordField(
                label: l.retypePassword,
                controller: _retype,
                newPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v == _password.text ? null : l.errPasswordMismatch,
              ),
              const SizedBox(height: 47),
              AppButton(label: l.signUp, loading: _loading, onPressed: _submit),
              const SizedBox(height: 16),
              AuthLinkRow(
                text: l.haveAccount,
                action: l.logIn,
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
