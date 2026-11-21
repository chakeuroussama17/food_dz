import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_tracker.dart' show appPlatform;
import '../../account/widgets/details_fields.dart';
import '../../legal/legal_texts.dart' show kLegalVersion;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../widgets/social_buttons.dart';
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
  final _commune = TextEditingController();
  int? _wilaya;
  bool _accepted = false;
  bool _acceptError = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _retype, _commune]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _acceptError = !_accepted);
    if (!ok || !_accepted) return;
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
            details: {
              'wilaya': '$_wilaya',
              'commune': _commune.text.trim(),
              'lang': Localizations.localeOf(context).languageCode,
              'platform': appPlatform(),
              'accepted_terms': kLegalVersion,
            },
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
              // Where the customer lives (admin analysis, future zones).
              WilayaField(
                value: _wilaya,
                onChanged: (v) => setState(() => _wilaya = v),
              ),
              const SizedBox(height: 24),
              LabeledField(
                key: const Key('commune'),
                label: l.commune,
                controller: _commune,
                hint: l.communeHint,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? l.errCommune : null,
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
              const SizedBox(height: 20),
              // Required: terms of use and privacy policy (with links).
              _TermsBox(
                value: _accepted,
                error: _acceptError,
                onChanged: (v) => setState(() {
                  _accepted = v;
                  if (v) _acceptError = false;
                }),
              ),
              const SizedBox(height: 27),
              AppButton(label: l.signUp, loading: _loading, onPressed: _submit),
              const SizedBox(height: 24),
              const SocialButtons(),
              const SizedBox(height: 8),
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

class _TermsBox extends StatelessWidget {
  const _TermsBox({
    required this.value,
    required this.error,
    required this.onChanged,
  });
  final bool value;
  final bool error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final link = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: const Key('accept-terms-box'),
              value: value,
              activeColor: AppColors.primary,
              side: BorderSide(
                color: error ? AppColors.danger : AppColors.muted,
                width: 1.5,
              ),
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  children: [
                    Text(
                      l.signupAcceptPrefix,
                      style: TextStyle(color: AppColors.body, height: 1.4),
                    ),
                    InkWell(
                      onTap: () => context.push('/legal/terms'),
                      child: Text(l.termsOfUseLink, style: link),
                    ),
                    Text(
                      l.signupAcceptAnd,
                      style: TextStyle(color: AppColors.body, height: 1.4),
                    ),
                    InkWell(
                      onTap: () => context.push('/legal/privacy'),
                      child: Text(l.privacyLink, style: link),
                    ),
                    Text('.', style: TextStyle(color: AppColors.body)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (error)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Text(
              l.errAcceptTerms,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
